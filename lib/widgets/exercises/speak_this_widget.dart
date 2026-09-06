import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../models/exercise.dart';
import '../../theme/app_colors.dart';

class SpeakThisWidget extends StatefulWidget {
  final Exercise exercise;
  final void Function(bool) onAnswer;

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

  /// Null while [_initializeSpeech] is still running, then true/false once the
  /// recognizer has reported whether it can be used on this device.
  bool? _speechAvailable;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
  }

  Future<void> _initializeSpeech() async {
    // initialize() returns false when the device has no recognizer or the
    // microphone permission was denied; both mean the exercise can only be
    // skipped.
    final available = await _speech.initialize();
    if (!mounted) return;
    setState(() => _speechAvailable = available);
  }

  @override
  void dispose() {
    // Stop the recognizer so it does not keep listening after the exercise
    // has been left.
    unawaited(_speech.cancel());
    super.dispose();
  }

  Future<void> _startListening() async {
    if (_speechAvailable != true) return;

    setState(() {
      _isListening = true;
      _recognizedText = '';
    });

    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _recognizedText = result.recognizedWords;
        });
      },
      localeId: widget.exercise.targetLanguage ?? 'es-ES',
    );

    // Auto-stop after 3 seconds
    unawaited(Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted && _isListening) {
        unawaited(_stopListening());
      }
    }));
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    if (!mounted) return;
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

    unawaited(Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        widget.onAnswer(_isCorrect);
      }
    }));
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
    final unavailable = _speechAvailable == false;
    final enabled = _speechAvailable == true;
    const disabledColor = AppColors.textDisabled;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Speak this phrase',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Text(
            widget.exercise.question,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          Center(
            child: GestureDetector(
              onTapDown: enabled ? (_) => _startListening() : null,
              onTapUp: enabled ? (_) => _stopListening() : null,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: !enabled
                      ? AppColors.border
                      : _isListening
                          ? AppColors.incorrect.withValues(alpha: 0.2)
                          : AppColors.textPrimary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: !enabled
                        ? disabledColor
                        : _isListening
                            ? AppColors.incorrect
                            : AppColors.textPrimary,
                    width: 3,
                  ),
                ),
                child: Icon(
                  unavailable
                      ? Icons.mic_off
                      : _isListening
                          ? Icons.mic
                          : Icons.mic_none,
                  size: 50,
                  color: !enabled
                      ? disabledColor
                      : _isListening
                          ? AppColors.incorrect
                          : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              unavailable
                  ? 'Speech not available on this device'
                  : _speechAvailable == null
                      ? 'Checking microphone...'
                      : _isListening
                          ? 'Listening...'
                          : 'Tap and hold to speak',
              style: TextStyle(
                fontSize: 16,
                color: unavailable ? disabledColor : AppColors.textSecondary,
              ),
            ),
          ),
          if (_recognizedText.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'You said:',
                    style:
                        TextStyle(fontSize: 14, color: AppColors.textSecondary),
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
                  color: _isCorrect ? AppColors.correct : AppColors.incorrect,
                ),
                const SizedBox(width: 8),
                Text(
                  _isCorrect ? 'Good!' : 'Try again',
                  style: TextStyle(
                    fontSize: 16,
                    color: _isCorrect ? AppColors.correct : AppColors.incorrect,
                  ),
                ),
              ],
            ),
          ],
          const Spacer(),
          if (unavailable)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => widget.onAnswer(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surfaceRaised,
                  foregroundColor: AppColors.textSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Skip - Speech not available',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
