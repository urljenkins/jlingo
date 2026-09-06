import 'package:flutter/material.dart';
import '../../models/exercise.dart';
import '../hover_card.dart';
import '../../theme/app_colors.dart';

class MultipleChoiceWidget extends StatefulWidget {
  final Exercise exercise;
  final void Function(bool) onAnswer;

  const MultipleChoiceWidget({
    super.key,
    required this.exercise,
    required this.onAnswer,
  });

  @override
  State<MultipleChoiceWidget> createState() => _MultipleChoiceWidgetState();
}

class _MultipleChoiceWidgetState extends State<MultipleChoiceWidget> {
  String? _selectedAnswer;
  bool _showFeedback = false;

  void _selectAnswer(String answer) {
    if (_showFeedback) return;

    setState(() {
      _selectedAnswer = answer;
      _showFeedback = true;
    });

    final isCorrect = answer == widget.exercise.correctAnswer;

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        widget.onAnswer(isCorrect);
      }
    });
  }

  Color _getOptionColor(String option) {
    if (!_showFeedback) return AppColors.surfaceRaised;

    if (option == widget.exercise.correctAnswer) {
      return AppColors.correct.withValues(alpha: 0.2);
    }

    if (option == _selectedAnswer && option != widget.exercise.correctAnswer) {
      return AppColors.incorrect.withValues(alpha: 0.2);
    }

    return AppColors.surfaceRaised;
  }

  Color _getBorderColor(String option) {
    if (!_showFeedback) return Colors.transparent;

    if (option == widget.exercise.correctAnswer) {
      return AppColors.correct;
    }

    if (option == _selectedAnswer && option != widget.exercise.correctAnswer) {
      return AppColors.incorrect;
    }

    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Choose the correct answer',
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Text(
            widget.exercise.question,
            textAlign: TextAlign.left,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          ...widget.exercise.options.map(_buildOption),
        ],
      ),
    );
  }

  Widget _buildOption(String option) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      // Cap the width so short options ("Y sound") don't stretch edge to edge;
      // text stays left-aligned inside for fast vertical scanning.
      child: Align(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: HoverCard(
            baseColor: _getOptionColor(option),
            hoverColor: _showFeedback
                ? _getOptionColor(option)
                : AppColors.surfaceRaised,
            onTap: () => _selectAnswer(option),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getBorderColor(option),
                  width: 2,
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
              constraints: const BoxConstraints(minHeight: 56),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      option,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  if (_showFeedback && option == widget.exercise.correctAnswer)
                    const Icon(Icons.check_circle, color: AppColors.correct),
                  if (_showFeedback &&
                      option == _selectedAnswer &&
                      option != widget.exercise.correctAnswer)
                    const Icon(Icons.cancel, color: AppColors.incorrect),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
