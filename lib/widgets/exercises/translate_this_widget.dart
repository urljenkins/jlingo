import 'package:flutter/material.dart';
import '../../models/exercise.dart';

class TranslateThisWidget extends StatefulWidget {
  final Exercise exercise;
  final void Function(bool) onAnswer;

  const TranslateThisWidget({
    super.key,
    required this.exercise,
    required this.onAnswer,
  });

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
    final userAnswer = _controller.text.trim().toLowerCase();
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Translate to English',
            style: TextStyle(fontSize: 14, color: Colors.white60),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.exercise.question,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Type the English translation:',
            style: TextStyle(fontSize: 14, color: Colors.white60),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            style: const TextStyle(fontSize: 18),
            decoration: InputDecoration(
              hintText: 'Type your answer',
              filled: true,
              fillColor: _showFeedback
                  ? (_isCorrect
                      ? const Color(0xFF00FF85).withValues(alpha: 0.1)
                      : const Color(0xFFFF4757).withValues(alpha: 0.1))
                  : const Color(0xFF2A2A2A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _showFeedback
                      ? (_isCorrect
                          ? const Color(0xFF00FF85)
                          : const Color(0xFFFF4757))
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _showFeedback
                      ? (_isCorrect
                          ? const Color(0xFF00FF85)
                          : const Color(0xFFFF4757))
                      : const Color(0xFF00D9FF),
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
                      ? const Color(0xFF00FF85)
                      : const Color(0xFFFF4757),
                ),
                const SizedBox(width: 8),
                Text(
                  _isCorrect ? 'Correct!' : 'Incorrect',
                  style: TextStyle(
                    fontSize: 16,
                    color: _isCorrect
                        ? const Color(0xFF00FF85)
                        : const Color(0xFFFF4757),
                  ),
                ),
              ],
            ),
            if (!_isCorrect) ...[
              const SizedBox(height: 8),
              Text(
                'Correct answer: ${widget.exercise.correctAnswer}',
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _showFeedback ? null : _checkAnswer,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D9FF),
                foregroundColor: Colors.black,
                disabledBackgroundColor: const Color(0xFF3A3A3A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'CHECK',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
