import 'package:flutter/material.dart';
import '../../models/exercise.dart';

class MultipleChoiceWidget extends StatefulWidget {
  final Exercise exercise;
  final Function(bool) onAnswer;

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
      return const Color(0xFF00FF85).withOpacity(0.2);
    }

    if (option == _selectedAnswer && option != widget.exercise.correctAnswer) {
      return const Color(0xFFFF4757).withOpacity(0.2);
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
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose the correct answer',
            style: TextStyle(fontSize: 14, color: Colors.white60),
          ),
          const SizedBox(height: 16),
          Text(
            widget.exercise.question,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          ...widget.exercise.options.map((option) => _buildOption(option)),
        ],
      ),
    );
  }

  Widget _buildOption(String option) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: _getOptionColor(option),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _selectAnswer(option),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getBorderColor(option),
                width: 2,
              ),
            ),
            padding: const EdgeInsets.all(16),
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
    );
  }
}
