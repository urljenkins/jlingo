import 'package:flutter/material.dart';
import '../../models/exercise.dart';
import '../../theme/app_colors.dart';

/// Translation Exercise Widget
/// Handles sentence and paragraph translation exercises in both directions
/// (target language to native and native to target).
///
/// Metadata structure:
/// {
///   "direction": "toNative" or "toTarget",
///   "sourceText": "Original text to translate",
///   "hints": ["hint1", "hint2"],
///   "acceptableAnswers": ["answer1", "answer2"],  // Alternative correct answers
///   "difficulty": "sentence" or "paragraph"
/// }
class TranslationExerciseWidget extends StatefulWidget {
  final Exercise exercise;
  final void Function(bool) onAnswer;

  const TranslationExerciseWidget({
    super.key,
    required this.exercise,
    required this.onAnswer,
  });

  @override
  State<TranslationExerciseWidget> createState() =>
      _TranslationExerciseWidgetState();
}

class _TranslationExerciseWidgetState extends State<TranslationExerciseWidget> {
  final _controller = TextEditingController();
  bool _showFeedback = false;
  bool _isCorrect = false;
  bool _showHints = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {}); // Rebuild to update button state
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _direction =>
      (widget.exercise.metadata?['direction'] as String?) ?? 'toNative';

  String get _sourceText =>
      (widget.exercise.metadata?['sourceText'] as String?) ??
      widget.exercise.question;

  List<String> get _hints {
    final hints = widget.exercise.metadata?['hints'];
    if (hints != null) {
      return List<String>.from(hints as List);
    }
    return [];
  }

  List<String> get _acceptableAnswers {
    final answers = widget.exercise.metadata?['acceptableAnswers'];
    if (answers != null) {
      return [
        widget.exercise.correctAnswer,
        ...List<String>.from(answers as List),
      ];
    }
    return [widget.exercise.correctAnswer];
  }

  String get _difficulty =>
      (widget.exercise.metadata?['difficulty'] as String?) ?? 'sentence';

  String get _directionLabel {
    if (_direction == 'toNative') {
      return 'Translate to ${widget.exercise.nativeLanguage ?? "English"}';
    } else {
      return 'Translate to ${widget.exercise.targetLanguage ?? "target language"}';
    }
  }

  IconData get _directionIcon {
    return _direction == 'toNative' ? Icons.translate : Icons.language;
  }

  bool _checkUserAnswer(String userAnswer) {
    final normalizedUser = _normalizeText(userAnswer);

    for (final acceptable in _acceptableAnswers) {
      if (_normalizeText(acceptable) == normalizedUser) {
        return true;
      }
    }

    // Also check with fuzzy matching for minor typos (Levenshtein distance)
    for (final acceptable in _acceptableAnswers) {
      if (_fuzzyMatch(_normalizeText(acceptable), normalizedUser)) {
        return true;
      }
    }

    return false;
  }

  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove punctuation
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize whitespace
  }

  bool _fuzzyMatch(String expected, String actual) {
    if (expected.isEmpty || actual.isEmpty) return false;

    // Allow up to 10% character difference for longer texts
    final maxDistance = (expected.length * 0.1).ceil();
    final distance = _levenshteinDistance(expected, actual);

    return distance <= maxDistance;
  }

  int _levenshteinDistance(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> previousRow = List.generate(s2.length + 1, (i) => i);
    final List<int> currentRow = List.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      currentRow[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        final int insertCost = currentRow[j] + 1;
        final int deleteCost = previousRow[j + 1] + 1;
        final int replaceCost = previousRow[j] + (s1[i] == s2[j] ? 0 : 1);
        currentRow[j + 1] = [insertCost, deleteCost, replaceCost]
            .reduce((a, b) => a < b ? a : b);
      }
      previousRow = List.from(currentRow);
    }

    return currentRow[s2.length];
  }

  void _checkAnswer() {
    if (_showFeedback) return;

    final userAnswer = _controller.text;

    setState(() {
      _isCorrect = _checkUserAnswer(userAnswer);
      _showFeedback = true;
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        widget.onAnswer(_isCorrect);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isParagraph = _difficulty == 'paragraph';

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(_directionIcon, color: AppColors.textPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                _directionLabel,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary),
              ),
              const Spacer(),
              if (isParagraph)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Paragraph',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Source text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _direction == 'toNative'
                    ? AppColors.textPrimary.withValues(alpha: 0.3)
                    : AppColors.correct.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _direction == 'toNative'
                            ? AppColors.textPrimary.withValues(alpha: 0.2)
                            : AppColors.correct.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _direction == 'toNative' ? 'Source' : 'Native',
                        style: TextStyle(
                          fontSize: 10,
                          color: _direction == 'toNative'
                              ? AppColors.textPrimary
                              : AppColors.correct,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _sourceText,
                  style: TextStyle(
                    fontSize: isParagraph ? 16 : 22,
                    fontWeight: FontWeight.bold,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // Hints section
          if (_hints.isNotEmpty) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => setState(() => _showHints = !_showHints),
              icon: Icon(
                _showHints ? Icons.lightbulb : Icons.lightbulb_outline,
                size: 18,
                color: AppColors.textPrimary,
              ),
              label: Text(
                _showHints ? 'Hide Hints' : 'Show Hints',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (_showHints) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.textPrimary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _hints
                      .map((hint) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('• ',
                                    style: TextStyle(
                                        color: AppColors.textPrimary)),
                                Expanded(
                                  child: Text(
                                    hint,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ],

          const SizedBox(height: 16),

          // Translation input
          const Text(
            'Your translation:',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _showFeedback
                    ? (_isCorrect
                        ? AppColors.correct.withValues(alpha: 0.1)
                        : AppColors.incorrect.withValues(alpha: 0.1))
                    : AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _showFeedback
                      ? (_isCorrect ? AppColors.correct : AppColors.incorrect)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: TextField(
                controller: _controller,
                autofocus: true,
                maxLines: isParagraph ? null : 3,
                expands: isParagraph,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(fontSize: 16, height: 1.5),
                decoration: InputDecoration(
                  hintText: isParagraph
                      ? 'Type your translation here...'
                      : 'Type your translation',
                  filled: true,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
                onSubmitted: isParagraph ? null : (_) => _checkAnswer(),
              ),
            ),
          ),

          // Feedback section
          if (_showFeedback) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isCorrect
                    ? AppColors.correct.withValues(alpha: 0.1)
                    : AppColors.incorrect.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isCorrect ? Icons.check_circle : Icons.cancel,
                        color: _isCorrect
                            ? AppColors.correct
                            : AppColors.incorrect,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isCorrect ? 'Excellent!' : 'Not quite right',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _isCorrect
                              ? AppColors.correct
                              : AppColors.incorrect,
                        ),
                      ),
                    ],
                  ),
                  if (!_isCorrect) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Expected answer:',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.exercise.correctAnswer,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _controller.text.isNotEmpty && !_showFeedback
                  ? _checkAnswer
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textPrimary,
                foregroundColor: Colors.black,
                disabledBackgroundColor: AppColors.surfaceRaised,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('CHECK TRANSLATION',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
