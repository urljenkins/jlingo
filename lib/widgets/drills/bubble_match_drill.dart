import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/word_pair.dart';
import '../../providers/settings_provider.dart';
import '../../services/word_pool.dart';
import '../../theme/app_colors.dart';

/// Match pairs as a loose field of drifting word bubbles rather than a grid or
/// a column.
///
/// The waterfall drill keeps two tidy columns; this one throws the same words
/// across the whole screen as small bubbles that bob and drift. The task is
/// the same — tap a target word, then its meaning — but the eye has to hunt,
/// which is the point: it turns a lookup into a scan-and-spot game. Matched
/// bubbles pop and, in the endless size, are replaced from the pool.
class BubbleMatchDrill extends StatefulWidget {
  const BubbleMatchDrill({
    super.key,
    required this.pool,
    required this.fieldSize,
    required this.onAnswer,
    required this.onDeclareKnown,
    this.onFinished,
  });

  final WordPool pool;

  /// Chosen in settings — how many bubbles, and whether the field refills.
  final BubbleFieldSize fieldSize;

  final void Function(WordPair pair, bool correct, Duration elapsed) onAnswer;
  final void Function(WordPair pair) onDeclareKnown;
  final VoidCallback? onFinished;

  @override
  State<BubbleMatchDrill> createState() => _BubbleMatchDrillState();
}

/// One bubble: one side of one pair, with its own position and drift within
/// the unit square. Pixel positions are derived at paint time from the field
/// size, so the layout survives rotation and resize.
class _Bubble {
  _Bubble({
    required this.pair,
    required this.isTarget,
    required this.pos,
    required this.drift,
    required this.phase,
  });

  final WordPair pair;
  final bool isTarget;

  /// Normalised centre, each component in [0, 1].
  Offset pos;

  /// Normalised velocity per second, small.
  Offset drift;

  /// Bob offset so bubbles are not all in sync.
  double phase;

  String get text => isTarget ? pair.target : pair.native;
}

class _BubbleMatchDrillState extends State<BubbleMatchDrill>
    with SingleTickerProviderStateMixin {
  static const _tickInterval = Duration(milliseconds: 33);
  final _rng = Random();

  /// Pairs not yet on the field.
  late List<WordPair> _remaining;

  final List<_Bubble> _bubbles = [];
  _Bubble? _selected;
  final Set<WordPair> _matched = {};
  WordPair? _wrongPair;
  DateTime _selectedAt = DateTime.now();
  int _cleared = 0;

  Timer? _ticker;
  Timer? _wrongTimer;
  Duration _elapsed = Duration.zero;

  int get _targetPairs => widget.fieldSize.pairCount;

  @override
  void initState() {
    super.initState();
    _remaining = List.of(widget.pool.pairs)..shuffle();
    _fill();
    _ticker = Timer.periodic(_tickInterval, _onTick);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _wrongTimer?.cancel();
    super.dispose();
  }

  /// Tops the field up to the target pair count from the remaining pool.
  void _fill() {
    while (_livePairCount < _targetPairs && _remaining.isNotEmpty) {
      final pair = _remaining.removeLast();
      _bubbles.add(_spawn(pair, isTarget: true));
      _bubbles.add(_spawn(pair, isTarget: false));
    }
  }

  int get _livePairCount {
    final live = <WordPair>{};
    for (final b in _bubbles) {
      if (!_matched.contains(b.pair)) live.add(b.pair);
    }
    return live.length;
  }

  _Bubble _spawn(WordPair pair, {required bool isTarget}) {
    // Keep spawns off the extreme edges so bubbles do not clip the frame.
    double coord() => 0.1 + _rng.nextDouble() * 0.8;
    const speed = 0.012;
    return _Bubble(
      pair: pair,
      isTarget: isTarget,
      pos: Offset(coord(), coord()),
      drift: Offset(
        (_rng.nextDouble() - 0.5) * speed,
        (_rng.nextDouble() - 0.5) * speed,
      ),
      phase: _rng.nextDouble() * 2 * pi,
    );
  }

  void _onTick(Timer _) {
    if (!mounted) return;
    setState(() {
      _elapsed += _tickInterval;
      const dt = 33 / 1000;
      for (final b in _bubbles) {
        if (_matched.contains(b.pair)) continue;
        var p = b.pos + b.drift * dt;
        var d = b.drift;
        // Bounce off the soft walls so the field stays populated.
        if (p.dx < 0.08 || p.dx > 0.92) {
          d = Offset(-d.dx, d.dy);
          p = Offset(p.dx.clamp(0.08, 0.92), p.dy);
        }
        if (p.dy < 0.08 || p.dy > 0.92) {
          d = Offset(d.dx, -d.dy);
          p = Offset(p.dx, p.dy.clamp(0.08, 0.92));
        }
        b.pos = p;
        b.drift = d;
      }
    });
  }

  void _onTap(_Bubble bubble) {
    if (_matched.contains(bubble.pair)) return;

    final selected = _selected;
    if (selected == null) {
      setState(() {
        _selected = bubble;
        _selectedAt = DateTime.now();
      });
      return;
    }

    if (identical(selected, bubble)) {
      setState(() => _selected = null);
      return;
    }
    // Tapping the same side just moves the selection rather than counting as
    // a wrong match.
    if (selected.isTarget == bubble.isTarget) {
      setState(() {
        _selected = bubble;
        _selectedAt = DateTime.now();
      });
      return;
    }

    final elapsed = DateTime.now().difference(_selectedAt);
    final isMatch = selected.pair == bubble.pair;
    widget.onAnswer(selected.pair, isMatch, elapsed);

    if (isMatch) {
      HapticFeedback.selectionClick();
      setState(() {
        _matched.add(bubble.pair);
        _selected = null;
        _cleared++;
      });
      Timer(
          const Duration(milliseconds: 260), () => _clearMatched(bubble.pair));
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

  void _clearMatched(WordPair pair) {
    if (!mounted) return;
    setState(() {
      _bubbles.removeWhere((b) => b.pair == pair);
      _matched.remove(pair);
      if (widget.fieldSize.refills) _fill();
    });
    if (_bubbles.isEmpty) widget.onFinished?.call();
  }

  /// Long-press retires a word without matching it — the same bulk gesture the
  /// waterfall drill uses.
  void _declareKnown(_Bubble bubble) {
    HapticFeedback.mediumImpact();
    widget.onDeclareKnown(bubble.pair);
    setState(() {
      _bubbles.removeWhere((b) => b.pair == bubble.pair);
      if (_selected?.pair == bubble.pair) _selected = null;
      _cleared++;
      if (widget.fieldSize.refills) _fill();
    });
    if (_bubbles.isEmpty) widget.onFinished?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_bubbles.isEmpty) {
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              const Text(
                'Tap a word, then its match',
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  for (final bubble in _bubbles)
                    _buildBubble(bubble, constraints.biggest),
                ],
              );
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 14, top: 4),
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

  Widget _buildBubble(_Bubble bubble, Size field) {
    final isSelected = identical(_selected, bubble);
    final isMatched = _matched.contains(bubble.pair);
    final isWrong = _wrongPair == bubble.pair;

    Color background = AppColors.surfaceRaised;
    Color border = Colors.transparent;

    if (isMatched) {
      background = AppColors.correct.withValues(alpha: 0.22);
      border = AppColors.correct;
    } else if (isWrong) {
      background = AppColors.incorrect.withValues(alpha: 0.18);
      border = AppColors.incorrect;
    } else if (isSelected) {
      background = AppColors.textPrimary.withValues(alpha: 0.16);
      border = AppColors.borderStrong;
    }

    // A gentle bob layered on top of the drift, so nothing sits perfectly
    // still even between ticks.
    final t = _elapsed.inMilliseconds / 1000;
    final bob = sin(t * 1.4 + bubble.phase) * 3;

    final dx = bubble.pos.dx * field.width;
    final dy = bubble.pos.dy * field.height + bob;

    // Smaller bubbles when the field is busier.
    final fontSize = widget.fieldSize == BubbleFieldSize.packed ? 12.0 : 13.5;

    return AnimatedPositioned(
      duration: _tickInterval,
      left: dx,
      top: dy,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: GestureDetector(
          onTap: () => _onTap(bubble),
          onLongPress: () => _declareKnown(bubble),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 200),
            scale: isMatched ? 0.1 : 1,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isMatched ? 0 : 1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                constraints: const BoxConstraints(maxWidth: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: border, width: 1.5),
                ),
                child: Text(
                  bubble.text,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: fontSize,
                    color: AppColors.textPrimary,
                    fontWeight:
                        bubble.isTarget ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
