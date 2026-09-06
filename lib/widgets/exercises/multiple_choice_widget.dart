import 'package:flutter/material.dart';
import '../../models/exercise.dart';
import '../hover_card.dart';

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
    if (!_showFeedback) return const Color(0xFF2A2A2A);

    if (option == widget.exercise.correctAnswer) {
      return const Color(0xFF00FF85).withValues(alpha: 0.2);
    }

    if (option == _selectedAnswer && option != widget.exercise.correctAnswer) {
      return const Color(0xFFFF4757).withValues(alpha: 0.2);
    }

    return const Color(0xFF2A2A2A);
  }

  Color _getBorderColor(String option) {
    if (!_showFeedback) return Colors.transparent;

    if (option == widget.exercise.correctAnswer) {
      return const Color(0xFF00FF85);
    }

    if (option == _selectedAnswer && option != widget.exercise.correctAnswer) {
      return const Color(0xFFFF4757);
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
            style: TextStyle(fontSize: 14, color: Colors.white60),
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
                : const Color(0xFF3A3A3A),
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
                    const Icon(Icons.check_circle, color: Color(0xFF00FF85)),
                  if (_showFeedback &&
                      option == _selectedAnswer &&
                      option != widget.exercise.correctAnswer)
                    const Icon(Icons.cancel, color: Color(0xFFFF4757)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
