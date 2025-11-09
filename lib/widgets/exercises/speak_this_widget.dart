import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../models/exercise.dart';

class SpeakThisWidget extends StatefulWidget {
  final Exercise exercise;
  final Function(bool) onAnswer;

  const SpeakThisWidget({
    super.key,
    required this.exercise,
    required this.onAnswer,
  });

  @override
  State<SpeakThisWidget> createState() => _SpeakThisWidgetState();
}

class _SpeakThisWidgetState extends State<SpeakThisWidget> {
  final _speech = SpeechToText();
  bool _isListening = false;
  bool _showFeedback = false;
  bool _isCorrect = false;
  String _recognizedText = '';

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    await _speech.initialize();
  }

  Future<void> _startListening() async {
    if (!_speech.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
      return;
    }

    setState(() {
      _isListening = true;
      _recognizedText = '';
    });

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _recognizedText = result.recognizedWords;
        });
      },
      localeId: widget.exercise.targetLanguage ?? 'es-ES',
    );

    // Auto-stop after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (_isListening) {
        _stopListening();
      }
    });
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);

    if (_recognizedText.isNotEmpty) {
      _checkAnswer();
    }
  }

  void _checkAnswer() {
    final userAnswer = _recognizedText.trim().toLowerCase();
    final correctAnswer = widget.exercise.correctAnswer.toLowerCase();

    // Simple similarity check (in production, use a proper similarity algorithm)
    final similarity = _calculateSimilarity(userAnswer, correctAnswer);
    _isCorrect = similarity > 0.7; // 70% similarity threshold

    setState(() => _showFeedback = true);

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        widget.onAnswer(_isCorrect);
      }
    });
  }

  double _calculateSimilarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;

    // Simple Levenshtein-based similarity
    final distance = _levenshteinDistance(a, b);
    final maxLength = a.length > b.length ? a.length : b.length;
    return 1.0 - (distance / maxLength);
  }

  int _levenshteinDistance(String a, String b) {
    final matrix = List.generate(
      a.length + 1,
      (i) => List.filled(b.length + 1, 0),
    );

    for (var i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }

    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[a.length][b.length];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Speak this phrase',
            style: TextStyle(fontSize: 14, color: Colors.white60),
          ),
          const SizedBox(height: 16),
          Text(
            widget.exercise.question,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          Center(
            child: GestureDetector(
              onTapDown: (_) => _startListening(),
              onTapUp: (_) => _stopListening(),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _isListening
                      ? const Color(0xFFFF4757).withOpacity(0.2)
                      : const Color(0xFF00D9FF).withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isListening ? const Color(0xFFFF4757) : const Color(0xFF00D9FF),
                    width: 3,
                  ),
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  size: 50,
                  color: _isListening ? const Color(0xFFFF4757) : const Color(0xFF00D9FF),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _isListening ? 'Listening...' : 'Tap and hold to speak',
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ),
          if (_recognizedText.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'You said:',
                    style: TextStyle(fontSize: 14, color: Colors.white60),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _recognizedText,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
          if (_showFeedback) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  _isCorrect ? Icons.check_circle : Icons.cancel,
                  color: _isCorrect ? const Color(0xFF00FF85) : const Color(0xFFFF4757),
                ),
                const SizedBox(width: 8),
                Text(
                  _isCorrect ? 'Good!' : 'Try again',
                  style: TextStyle(
                    fontSize: 16,
                    color: _isCorrect ? const Color(0xFF00FF85) : const Color(0xFFFF4757),
                  ),
                ),
              ],
            ),
          ],
          const Spacer(),
        ],
      ),
    );
  }
}
