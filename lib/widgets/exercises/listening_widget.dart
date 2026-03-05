import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../models/exercise.dart';

class ListeningWidget extends StatefulWidget {
  final Exercise exercise;
  final Function(bool) onAnswer;

  const ListeningWidget({
    super.key,
    required this.exercise,
    required this.onAnswer,
  });

  @override
  State<ListeningWidget> createState() => _ListeningWidgetState();
}

class _ListeningWidgetState extends State<ListeningWidget> {
  final _controller = TextEditingController();
  final _tts = FlutterTts();
  bool _showFeedback = false;
  bool _isCorrect = false;
  bool _isPlaying = false;
  bool _hasPlayedOnce = false;

  @override
  void initState() {
    super.initState();
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    await _tts.setLanguage(widget.exercise.targetLanguage ?? 'es-ES');
    await _tts.setSpeechRate(0.5); // Slower for learning
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _playAudio() async {
    setState(() {
      _isPlaying = true;
      _hasPlayedOnce = true;
    });
    await _tts.speak(widget.exercise.question);
    setState(() => _isPlaying = false);
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
            'Listening Exercise',
            style: TextStyle(fontSize: 14, color: Colors.white60),
          ),
          const SizedBox(height: 16),
          const Text(
            'Click the play button to hear the phrase, then type what you hear',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                IconButton(
                  onPressed: _isPlaying ? null : _playAudio,
                  icon: Icon(
                    _isPlaying ? Icons.volume_up : Icons.play_circle_filled,
                    size: 80,
                    color: _isPlaying ? Colors.white38 : const Color(0xFF00D9FF),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isPlaying ? 'Playing...' : 'Tap to play audio',
                  style: const TextStyle(fontSize: 14, color: Colors.white60),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _controller,
            autofocus: false,
            style: const TextStyle(fontSize: 18),
            decoration: InputDecoration(
              hintText: 'Type what you hear',
              filled: true,
              fillColor: _showFeedback
                  ? (_isCorrect
                      ? const Color(0xFF00FF85).withOpacity(0.1)
                      : const Color(0xFFFF4757).withOpacity(0.1))
                  : const Color(0xFF2A2A2A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _showFeedback
                      ? (_isCorrect ? const Color(0xFF00FF85) : const Color(0xFFFF4757))
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _showFeedback
                      ? (_isCorrect ? const Color(0xFF00FF85) : const Color(0xFFFF4757))
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
                  color: _isCorrect ? const Color(0xFF00FF85) : const Color(0xFFFF4757),
                ),
                const SizedBox(width: 8),
                Text(
                  _isCorrect ? 'Correct!' : 'Incorrect',
                  style: TextStyle(
                    fontSize: 16,
                    color: _isCorrect ? const Color(0xFF00FF85) : const Color(0xFFFF4757),
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
          if (_hasPlayedOnce && !_showFeedback)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: double.infinity,
                height: 40,
                child: TextButton(
                  onPressed: () {
                    _controller.text = widget.exercise.correctAnswer;
                    _checkAnswer();
                  },
                  child: const Text(
                    "Can't hear? Show answer",
                    style: TextStyle(fontSize: 14, color: Colors.white60),
                  ),
                ),
              ),
            ),
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
