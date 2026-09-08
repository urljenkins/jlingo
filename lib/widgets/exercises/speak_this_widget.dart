import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../models/exercise.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

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

  /// Set once the answer has been graded so a late final result from the
  /// recognizer cannot grade the same attempt twice.
  bool _graded = false;

  /// Null while [_initializeSpeech] is still running, then true/false once the
  /// recognizer has reported whether it can be used on this device.
  bool? _speechAvailable;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeSpeech());
  }

  Future<void> _initializeSpeech() async {
    // initialize() returns false when the device has no recognizer or the
    // microphone permission was denied; both mean the exercise can only be
    // skipped.
    final available = await _speech.initialize(
      onStatus: _onSpeechStatus,
      onError: (_) {
        // An error ends the session; drop back to idle so the mic can be
        // started again rather than leaving the button stuck on "Listening".
        if (mounted) setState(() => _isListening = false);
      },
    );
    if (!mounted) return;
    setState(() => _speechAvailable = available);
  }

  /// The recognizer stops on its own when it hears a long enough pause, so the
  /// UI has to follow its status rather than assume a button release ended it.
  void _onSpeechStatus(String status) {
    if (!mounted) return;
    final listening = status == SpeechToText.listeningStatus;
    if (_isListening != listening) {
      setState(() => _isListening = listening);
    }
    if (!listening) _grade();
  }

  @override
  void dispose() {
    // Stop the recognizer so it does not keep listening after the exercise
    // has been left.
    unawaited(_speech.cancel());
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_speechAvailable != true) return;
    if (_isListening) {
      await _speech.stop();
      return;
    }

    setState(() {
      _isListening = true;
      _recognizedText = '';
      _showFeedback = false;
      _graded = false;
    });

    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() => _recognizedText = result.recognizedWords);
        // The final transcript is the one worth grading, and it can land after
        // the mic has already been released.
        if (result.finalResult) _grade();
      },
      localeId: widget.exercise.targetLanguage ?? 'es-ES',
      // Keep the mic open until the learner has clearly finished, instead of
      // cutting them off mid-phrase.
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
  }

  /// Scores whatever was heard. Safe to call more than once per attempt.
  void _grade() {
    if (_graded || _recognizedText.trim().isEmpty) return;
    _graded = true;

    final userAnswer = _recognizedText.trim().toLowerCase();
    final correctAnswer = widget.exercise.correctAnswer.toLowerCase();

    final similarity = _calculateSimilarity(userAnswer, correctAnswer);
    _isCorrect = similarity > 0.7; // 70% similarity threshold

    setState(() => _showFeedback = true);

    if (_isCorrect) {
      unawaited(Future<void>.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) widget.onAnswer(true);
      }));
    }
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

  void _tryAgain() {
    setState(() {
      _showFeedback = false;
      _recognizedText = '';
      _graded = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final unavailable = _speechAvailable == false;
    final enabled = _speechAvailable == true;
    const disabledColor = AppColors.textDisabled;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenInset,
        vertical: AppSpacing.lg,
      ),
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
              onTap: enabled ? _toggleListening : null,
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
                          ? 'Listening — tap to stop'
                          : 'Tap to speak',
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
                  _isCorrect ? 'Good!' : 'Not quite',
                  style: TextStyle(
                    fontSize: 16,
                    color: _isCorrect ? AppColors.correct : AppColors.incorrect,
                  ),
                ),
              ],
            ),
          ],
          const Spacer(),
          // There is always a way forward, whether or not the recognizer
          // heard anything usable.
          if (unavailable)
            _bottomButton(
              label: 'Skip - Speech not available',
              onPressed: () => widget.onAnswer(true),
            )
          else if (_showFeedback && !_isCorrect)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => widget.onAnswer(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Continue'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _tryAgain,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.textPrimary,
                      foregroundColor: AppColors.onAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Try Again',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            )
          else if (!_isListening)
            _bottomButton(
              label: 'Skip',
              onPressed: () => widget.onAnswer(false),
            ),
        ],
      ),
    );
  }

  Widget _bottomButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surfaceRaised,
          foregroundColor: AppColors.textSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
