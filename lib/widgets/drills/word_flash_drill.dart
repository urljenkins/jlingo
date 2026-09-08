import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/word_pair.dart';
import '../../services/word_pool.dart';
import '../../theme/app_colors.dart';

/// A rapid recognition drill: one word flashes, you tap its meaning, the next
/// one is already on screen.
///
/// The design goal is the least interaction that still constitutes practice —
/// one tap per word, no Check button, no confirmation, no page transition.
/// A learner who knows the vocabulary can clear dozens of words a minute, and
/// speed is itself the signal that retires a word (see `WordKnowledge`).
class WordFlashDrill extends StatefulWidget {
  const WordFlashDrill({
    super.key,
    required this.pool,
    required this.onAnswer,
    required this.onDeclareKnown,
    this.onFinished,
    this.rounds = 20,
  });

  /// Words to drill. Already filtered to exclude ones marked known.
  final WordPool pool;

  /// Reports one answer with how long it took, so a fast correct answer can
  /// promote the word.
  final void Function(WordPair pair, bool correct, Duration elapsed) onAnswer;

  /// The explicit "I know this" gesture.
  final void Function(WordPair pair) onDeclareKnown;

  final VoidCallback? onFinished;

  /// How many words before the drill hands back. Kept finite so the session
  /// has an end; the learner can start another immediately.
  final int rounds;

  @override
  State<WordFlashDrill> createState() => _WordFlashDrillState();
}

class _WordFlashDrillState extends State<WordFlashDrill> {
  /// How long a new word is shown alone before its options appear. Long
  /// enough to read, short enough that it feels like a flash rather than a
  /// prompt waiting for you.
  static const Duration _flashDuration = Duration(milliseconds: 800);

  /// How long feedback holds before the next word. Wrong answers hold longer
  /// so the correction is actually readable.
  static const Duration _correctHold = Duration(milliseconds: 320);
  static const Duration _incorrectHold = Duration(milliseconds: 1100);

  late List<WordPair> _queue;
  int _index = 0;
  int _correct = 0;

  List<WordPair> _options = const [];
  WordPair? _chosen;
  bool _optionsVisible = false;
  DateTime _shownAt = DateTime.now();
  Timer? _revealTimer;
  Timer? _advanceTimer;

  WordPair get _current => _queue[_index];

  @override
  void initState() {
    super.initState();
    _queue = List.of(widget.pool.pairs)..shuffle();
    if (_queue.length > widget.rounds) {
      _queue = _queue.sublist(0, widget.rounds);
    }
    if (_queue.isNotEmpty) _present();
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    _advanceTimer?.cancel();
    super.dispose();
  }

  void _present() {
    final answer = _current;
    final options = [answer, ...widget.pool.distractorsFor(answer)]..shuffle();

    setState(() {
      _options = options;
      _chosen = null;
      _optionsVisible = false;
    });

    // The word appears alone first — that beat is what makes it a flash and
    // not just another multiple-choice card.
    _revealTimer?.cancel();
    _revealTimer = Timer(_flashDuration, () {
      if (!mounted) return;
      setState(() {
        _optionsVisible = true;
        _shownAt = DateTime.now();
      });
    });
  }

  void _choose(WordPair option) {
    if (_chosen != null || !_optionsVisible) return;

    final elapsed = DateTime.now().difference(_shownAt);
    final isCorrect = option.target == _current.target;

    setState(() => _chosen = option);
    HapticFeedback.selectionClick();
    widget.onAnswer(_current, isCorrect, elapsed);
    if (isCorrect) _correct++;

    _advanceTimer?.cancel();
    _advanceTimer = Timer(isCorrect ? _correctHold : _incorrectHold, _advance);
  }

  void _advance() {
    if (!mounted) return;
    if (_index >= _queue.length - 1) {
      widget.onFinished?.call();
      return;
    }
    setState(() => _index++);
    _present();
  }

  void _declareKnown() {
    if (_chosen != null) return;
    HapticFeedback.mediumImpact();
    widget.onDeclareKnown(_current);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('"${_current.target}" marked as known'),
          duration: const Duration(milliseconds: 1200),
          behavior: SnackBarBehavior.floating,
        ),
      );
    _revealTimer?.cancel();
    _advance();
  }

  @override
  Widget build(BuildContext context) {
    if (_queue.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No words left to drill — everything here is marked known.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildHeader(),
        Expanded(child: _buildFlashCard()),
        _buildOptions(),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Text(
            '${_index + 1} / ${_queue.length}',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const Spacer(),
          Text(
            '$_correct correct',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildFlashCard() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              // A slight settle as the word lands, so consecutive words read
              // as separate events rather than text swapping in place.
              scale: _optionsVisible ? 1.0 : 1.06,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: Text(
                _current.target,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (_current.pronunciation != null) ...[
              const SizedBox(height: 8),
              Text(
                _current.pronunciation!,
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 15),
              ),
            ],
            const SizedBox(height: 20),
            // The explicit escape hatch, deliberately quiet: available on
            // every word but never competing with the options for attention.
            TextButton.icon(
              onPressed: _chosen == null ? _declareKnown : null,
              icon: const Icon(Icons.done_all, size: 16),
              label: const Text('I know this'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textMuted,
                textStyle: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptions() {
    return AnimatedOpacity(
      opacity: _optionsVisible ? 1 : 0,
      duration: const Duration(milliseconds: 160),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: _options.map(_buildOption).toList(),
        ),
      ),
    );
  }

  Widget _buildOption(WordPair option) {
    final isChosen = _chosen == option;
    final isAnswer = option.target == _current.target;

    Color background = AppColors.surfaceRaised;
    Color border = Colors.transparent;

    if (_chosen != null) {
      // Once answered, always show where the right answer was — a missed
      // word teaches nothing if the drill moves on without showing it.
      if (isAnswer) {
        background = AppColors.correct.withValues(alpha: 0.2);
        border = AppColors.correct;
      } else if (isChosen) {
        background = AppColors.incorrect.withValues(alpha: 0.2);
        border = AppColors.incorrect;
      }
    }

    return GestureDetector(
      onTap: () => _choose(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        constraints: const BoxConstraints(minWidth: 120),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Text(
          option.native,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
