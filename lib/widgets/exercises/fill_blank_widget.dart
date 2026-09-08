import 'package:flutter/material.dart';
import '../../models/exercise.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class FillBlankWidget extends StatefulWidget {
  final Exercise exercise;
  final void Function(bool) onAnswer;

  const FillBlankWidget({
    super.key,
    required this.exercise,
    required this.onAnswer,
  });

  @override
  State<FillBlankWidget> createState() => _FillBlankWidgetState();
}

class _FillBlankWidgetState extends State<FillBlankWidget> {
  final _controller = TextEditingController();
  bool _showFeedback = false;
  bool _isCorrect = false;
  bool _useWordBank = false;
  String? _selectedWord;

  @override
  void initState() {
    super.initState();
    // Check if word bank is provided
    _useWordBank = widget.exercise.options.isNotEmpty;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkAnswer() {
    final userAnswer = _useWordBank
        ? (_selectedWord ?? '').trim().toLowerCase()
        : _controller.text.trim().toLowerCase();
    final correctAnswer = widget.exercise.correctAnswer.toLowerCase();

    setState(() {
      _isCorrect = userAnswer == correctAnswer;
      _showFeedback = true;
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        widget.onAnswer(_isCorrect);
      }
    });
  }

  void _selectWord(String word) {
    if (_showFeedback) return;

    setState(() {
      _selectedWord = word;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Split the question to show blank
    final parts = widget.exercise.question.split('___');

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenInset,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fill in the blank',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),

          // Show sentence with blank
          Wrap(
            children: [
              if (parts.isNotEmpty)
                Text(
                  parts[0],
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: _showFeedback
                      ? (_isCorrect
                          ? AppColors.correct.withValues(alpha: 0.2)
                          : AppColors.incorrect.withValues(alpha: 0.2))
                      : AppColors.textPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _showFeedback
                        ? (_isCorrect ? AppColors.correct : AppColors.incorrect)
                        : AppColors.textPrimary,
                    width: 2,
                  ),
                ),
                child: Text(
                  _useWordBank
                      ? (_selectedWord ?? '____')
                      : (_controller.text.isEmpty ? '____' : _controller.text),
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              if (parts.length > 1)
                Text(
                  parts[1],
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
            ],
          ),

          const SizedBox(height: 40),

          if (_useWordBank) ...[
            // Word bank options
            const Text(
              'Select the correct word:',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: widget.exercise.options.map((word) {
                final isSelected = _selectedWord == word;
                final isCorrectAnswer = word == widget.exercise.correctAnswer;

                Color backgroundColor = AppColors.surfaceRaised;
                Color borderColor = Colors.transparent;

                if (_showFeedback && isCorrectAnswer) {
                  backgroundColor = AppColors.correct.withValues(alpha: 0.2);
                  borderColor = AppColors.correct;
                } else if (isSelected) {
                  backgroundColor =
                      AppColors.textPrimary.withValues(alpha: 0.2);
                  borderColor = AppColors.textPrimary;
                }

                return Material(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () => _selectWord(word),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor, width: 2),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      child: Text(word, style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ] else ...[
            // Text input
            TextField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                hintText: 'Type the missing word',
                filled: true,
                fillColor: AppColors.surfaceRaised,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _checkAnswer(),
            ),
          ],

          if (_showFeedback) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  _isCorrect ? Icons.check_circle : Icons.cancel,
                  color: _isCorrect ? AppColors.correct : AppColors.incorrect,
                ),
                const SizedBox(width: 8),
                Text(
                  _isCorrect ? 'Correct!' : 'Incorrect',
                  style: TextStyle(
                    fontSize: 16,
                    color: _isCorrect ? AppColors.correct : AppColors.incorrect,
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

          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  _showFeedback || (_useWordBank && _selectedWord == null)
                      ? null
                      : _checkAnswer,
              child: const Text('Check'),
            ),
          ),
        ],
      ),
    );
  }
}
