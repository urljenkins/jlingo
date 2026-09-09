import 'package:flutter/material.dart';
import '../../models/exercise.dart';
import '../hover_card.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class MatchPairsWidget extends StatefulWidget {
  final Exercise exercise;
  final void Function(bool) onAnswer;

  const MatchPairsWidget({
    super.key,
    required this.exercise,
    required this.onAnswer,
  });

  @override
  State<MatchPairsWidget> createState() => _MatchPairsWidgetState();
}

class _MatchPairsWidgetState extends State<MatchPairsWidget> {
  final List<String> _selectedTiles = [];
  final Set<String> _wrongTiles = {};
  final Map<String, String> _matchedPairs = {};
  late List<MatchPair> _pairs;
  late List<String> _targetTiles;
  late List<String> _nativeTiles;

  @override
  void initState() {
    super.initState();
    _initializePairs();
  }

  void _initializePairs() {
    // Parse pairs from metadata
    final pairsData =
        widget.exercise.metadata?['pairs'] as List<dynamic>? ?? [];
    _pairs = pairsData
        .map((p) => MatchPair.fromJson(p as Map<String, dynamic>))
        .toList();

    // Create independently shuffled lists of target and native tiles
    _targetTiles = _pairs.map((p) => 'target:${p.target}').toList()..shuffle();
    _nativeTiles = _pairs.map((p) => 'native:${p.native}').toList()..shuffle();
  }

  void _onTileTap(String tile) {
    if (_matchedPairs.containsKey(tile) || _wrongTiles.isNotEmpty) return;
    if (_selectedTiles.contains(tile)) {
      setState(() => _selectedTiles.remove(tile));
      return;
    }

    setState(() {
      _selectedTiles.add(tile);

      if (_selectedTiles.length == 2) {
        _checkMatch();
      }
    });
  }

  void _checkMatch() {
    final tile1 = _selectedTiles[0];
    final tile2 = _selectedTiles[1];

    final parts1 = tile1.split(':');
    final parts2 = tile2.split(':');

    final type1 = parts1[0];
    final value1 = parts1[1];
    final type2 = parts2[0];
    final value2 = parts2[1];

    // Check if they're different types and form a valid pair
    if (type1 != type2) {
      final isMatch = _pairs.any((pair) =>
          (pair.target == value1 && pair.native == value2) ||
          (pair.target == value2 && pair.native == value1));

      if (isMatch) {
        setState(() {
          _matchedPairs[tile1] = tile2;
          _matchedPairs[tile2] = tile1;
          _selectedTiles.clear();

          // Check if all pairs are matched
          if (_matchedPairs.length == _pairs.length * 2) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) widget.onAnswer(true);
            });
          }
        });
      } else {
        setState(() {
          _wrongTiles.addAll([tile1, tile2]);
        });
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _wrongTiles.clear();
              _selectedTiles.clear();
            });
          }
        });
      }
    } else {
      setState(_selectedTiles.clear);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenInset,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Match the pairs',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Text(
            widget.exercise.question,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap a tile on the left, then its match on the right. Correct pairs lock in place; a wrong pair flashes red and clears.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        for (final tile in _targetTiles)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SizedBox(
                              height: 64,
                              child: _buildTile(tile),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: [
                        for (final tile in _nativeTiles)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SizedBox(
                              height: 64,
                              child: _buildTile(tile),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(String tile) {
    final isWrong = _wrongTiles.contains(tile);
    final isMatched = _matchedPairs.containsKey(tile);
    final isSelected = _selectedTiles.contains(tile);
    final value = tile.split(':')[1];

    Color backgroundColor = AppColors.surfaceRaised;
    Color borderColor = Colors.transparent;

    if (isMatched) {
      backgroundColor = AppColors.correct.withValues(alpha: 0.2);
      borderColor = AppColors.correct;
    } else if (isWrong) {
      backgroundColor = AppColors.incorrect.withValues(alpha: 0.2);
      borderColor = AppColors.incorrect;
    } else if (isSelected) {
      backgroundColor = AppColors.textPrimary.withValues(alpha: 0.2);
      borderColor = AppColors.textPrimary;
    }

    return HoverCard(
      baseColor: backgroundColor,
      hoverColor: isMatched || isWrong || isSelected
          ? backgroundColor
          : AppColors.surfaceRaised,
      onTap: () => _onTileTap(tile),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
