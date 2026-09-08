import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/word_pair.dart';
import '../../services/word_pool.dart';
import '../../theme/app_colors.dart';

/// Match pairs as a continuous scrolling column rather than a fixed grid of
/// four.
///
/// The standard match exercise ends after eight tiles, so a learner with real
/// vocabulary spends more time on screen transitions than on words. Here the
/// list refills as pairs are cleared: matched rows drop out, new ones slide
/// in beneath, and the drill only ends when the learner stops or the pool is
/// exhausted. Volume comes from never leaving the screen.
class WaterfallMatchDrill extends StatefulWidget {
  const WaterfallMatchDrill({
    super.key,
    required this.pool,
    required this.onAnswer,
    required this.onDeclareKnown,
    this.onFinished,
    this.windowSize = 6,
  });

  final WordPool pool;
  final void Function(WordPair pair, bool correct, Duration elapsed) onAnswer;
  final void Function(WordPair pair) onDeclareKnown;
  final VoidCallback? onFinished;

  /// How many pairs are live at once. Six is the most that stays scannable
  /// without the learner hunting; the list refills to this as pairs clear.
  final int windowSize;

  @override
  State<WaterfallMatchDrill> createState() => _WaterfallMatchDrillState();
}

/// One side of one row. Tiles are identified by object rather than by string
/// so two words sharing a translation cannot be confused for each other.
class _Tile {
  _Tile({required this.pair, required this.isTarget});

  final WordPair pair;
  final bool isTarget;

  String get text => isTarget ? pair.target : pair.native;
}

class _WaterfallMatchDrillState extends State<WaterfallMatchDrill> {
  /// Pairs not yet brought on screen.
  late List<WordPair> _remaining;

  /// The live columns. Target and native are shuffled independently, which is
  /// what stops a row's two halves from lining up and giving the answer away.
  final List<_Tile> _targets = [];
  final List<_Tile> _natives = [];

  _Tile? _selected;
  final Set<WordPair> _matched = {};
  WordPair? _wrongPair;
  DateTime _selectedAt = DateTime.now();
  int _cleared = 0;
  Timer? _wrongTimer;

  @override
  void initState() {
    super.initState();
    _remaining = List.of(widget.pool.pairs)..shuffle();
    _refill();
  }

  @override
  void dispose() {
    _wrongTimer?.cancel();
    super.dispose();
  }

  /// Tops the live window back up to [windowSize] from the remaining pool.
  void _refill() {
    while (_targets.length < widget.windowSize && _remaining.isNotEmpty) {
      final pair = _remaining.removeLast();
      _targets.add(_Tile(pair: pair, isTarget: true));
      _natives.add(_Tile(pair: pair, isTarget: false));
    }
    _targets.shuffle();
    _natives.shuffle();
  }

  void _onTap(_Tile tile) {
    if (_matched.contains(tile.pair)) return;

    final selected = _selected;
    if (selected == null) {
      setState(() {
        _selected = tile;
        _selectedAt = DateTime.now();
      });
      return;
    }

    // Tapping the same tile again deselects; tapping the same side switches
    // the selection rather than counting as a failed match.
    if (identical(selected, tile)) {
      setState(() => _selected = null);
      return;
    }
    if (selected.isTarget == tile.isTarget) {
      setState(() {
        _selected = tile;
        _selectedAt = DateTime.now();
      });
      return;
    }

    final elapsed = DateTime.now().difference(_selectedAt);
    final isMatch = selected.pair == tile.pair;
    widget.onAnswer(selected.pair, isMatch, elapsed);

    if (isMatch) {
      HapticFeedback.selectionClick();
      setState(() {
        _matched.add(tile.pair);
        _selected = null;
        _cleared++;
      });
      // Let the matched row show green briefly, then drop it and slide the
      // replacement in.
      Timer(const Duration(milliseconds: 260), _clearMatched);
    } else {
      HapticFeedback.lightImpact();
      setState(() {
        _wrongPair = selected.pair;
        _selected = null;
      });
      _wrongTimer?.cancel();
      _wrongTimer = Timer(const Duration(milliseconds: 420), () {
        if (mounted) setState(() => _wrongPair = null);
      });
    }
  }

  void _clearMatched() {
    if (!mounted) return;
    setState(() {
      _targets.removeWhere((t) => _matched.contains(t.pair));
      _natives.removeWhere((t) => _matched.contains(t.pair));
      _matched.clear();
      _refill();
    });

    if (_targets.isEmpty) widget.onFinished?.call();
  }

  /// Long-press retires a word without matching it — the bulk gesture for a
  /// learner clearing vocabulary they already have.
  void _declareKnown(_Tile tile) {
    HapticFeedback.mediumImpact();
    widget.onDeclareKnown(tile.pair);
    setState(() {
      _targets.removeWhere((t) => t.pair == tile.pair);
      _natives.removeWhere((t) => t.pair == tile.pair);
      if (_selected?.pair == tile.pair) _selected = null;
      _cleared++;
      _refill();
    });
    if (_targets.isEmpty) widget.onFinished?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_targets.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No words left to match — everything here is marked known.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              const Text(
                'Match as many as you can',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const Spacer(),
              Text(
                '$_cleared cleared',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildColumn(_targets)),
                const SizedBox(width: 10),
                Expanded(child: _buildColumn(_natives)),
              ],
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: Center(
            child: Text(
              'Long-press a word you already know',
              style: TextStyle(color: AppColors.textDisabled, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColumn(List<_Tile> tiles) {
    return Column(
      children: [
        for (final tile in tiles)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildTile(tile),
          ),
      ],
    );
  }

  Widget _buildTile(_Tile tile) {
    final isSelected = identical(_selected, tile);
    final isMatched = _matched.contains(tile.pair);
    final isWrong = _wrongPair == tile.pair;

    Color background = AppColors.surfaceRaised;
    Color border = Colors.transparent;

    if (isMatched) {
      background = AppColors.correct.withValues(alpha: 0.2);
      border = AppColors.correct;
    } else if (isWrong) {
      background = AppColors.incorrect.withValues(alpha: 0.18);
      border = AppColors.incorrect;
    } else if (isSelected) {
      background = AppColors.textPrimary.withValues(alpha: 0.16);
      border = AppColors.borderStrong;
    }

    return GestureDetector(
      onTap: () => _onTap(tile),
      onLongPress: () => _declareKnown(tile),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Center(
          child: Text(
            tile.text,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
              fontWeight: tile.isTarget ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
