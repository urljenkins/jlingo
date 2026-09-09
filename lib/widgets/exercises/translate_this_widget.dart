import 'package:flutter/material.dart';
import '../../models/exercise.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class TranslateThisWidget extends StatefulWidget {
  final Exercise exercise;
  final void Function(bool) onAnswer;

  const TranslateThisWidget({
    super.key,
    required this.exercise,
    required this.onAnswer,
  });

  static String _clean(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool isAnswerMatch(String userInput, String target) {
    final cleanUser = _clean(userInput);
    if (cleanUser.isEmpty) return false;

    // Check exact stripped match first
    final cleanTarget = _clean(target);
    if (cleanUser == cleanTarget) return true;

    // Split on slashes or semicolons to support multiple accepted answers:
    // e.g. "That's fine / OK" -> accepts either "that's fine" or "ok"
    final alternatives = target
        .split(RegExp(r'[/;]'))
        .map((alt) {
          // Also ignore parenthetical explanations e.g. "(informal)"
          final stripped = alt.replaceAll(RegExp(r'\([^)]*\)'), '');
          return _clean(stripped);
        })
        .where((alt) => alt.isNotEmpty)
        .toList();

    if (alternatives.contains(cleanUser)) return true;

    // Also compare after removing all parentheticals from the full target
    final targetWithoutParens =
        _clean(target.replaceAll(RegExp(r'\([^)]*\)'), ''));
    if (targetWithoutParens.isNotEmpty && targetWithoutParens == cleanUser) {
      return true;
    }

    return false;
  }

  @override
  State<TranslateThisWidget> createState() => _TranslateThisWidgetState();
}

class _TranslateThisWidgetState extends State<TranslateThisWidget> {
  final _controller = TextEditingController();
  bool _showFeedback = false;
  bool _isCorrect = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkAnswer() {
    final isMatch = TranslateThisWidget.isAnswerMatch(
      _controller.text,
      widget.exercise.correctAnswer,
    );

    setState(() {
      _isCorrect = isMatch;
      _showFeedback = true;
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        widget.onAnswer(_isCorrect);
      }
    });
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
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Translate to English',
                    style:
                        TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.exercise.question,
                      style: const TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    style: const TextStyle(fontSize: 18),
                    decoration: InputDecoration(
                      hintText: 'Type your answer',
                      filled: true,
                      fillColor: _showFeedback
                          ? (_isCorrect
                              ? AppColors.correct.withValues(alpha: 0.1)
                              : AppColors.incorrect.withValues(alpha: 0.1))
                          : AppColors.surfaceRaised,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: _showFeedback
                              ? (_isCorrect
                                  ? AppColors.correct
                                  : AppColors.incorrect)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: _showFeedback
                              ? (_isCorrect
                                  ? AppColors.correct
                                  : AppColors.incorrect)
                              : AppColors.textPrimary,
                          width: 2,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _checkAnswer(),
                  ),
                  if (_showFeedback) ...[
                    const SizedBox(height: 16),
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
                          _isCorrect ? 'Correct!' : 'Incorrect',
                          style: TextStyle(
                            fontSize: 16,
                            color: _isCorrect
                                ? AppColors.correct
                                : AppColors.incorrect,
                          ),
                        ),
                      ],
                    ),
                    if (!_isCorrect) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Correct answer: ${widget.exercise.correctAnswer}',
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _showFeedback ? null : _checkAnswer,
              child: const Text('Check'),
            ),
          ),
          // The keyboard sits right under this button; the scaffold covers
          // the safe-area inset, this is the breathing room on top of it.
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
