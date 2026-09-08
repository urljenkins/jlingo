import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../models/exercise.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class ListeningWidget extends StatefulWidget {
  final Exercise exercise;
  final void Function(bool) onAnswer;

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
  static const double _normalRate = 0.5;
  static const double _halfRate = 0.25;
  static const double _quarterRate = 0.125;
  double _speechRate = _normalRate;

  @override
  void initState() {
    super.initState();
    _initializeTts();
    WidgetsBinding.instance.addPostFrameCallback((_) => _playAudio());
  }

  Future<void> _initializeTts() async {
    await _tts.setLanguage(widget.exercise.targetLanguage ?? 'es-ES');
    await _tts.setSpeechRate(_speechRate);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _playAudio({double? rate}) async {
    if (rate != null) {
      _speechRate = rate;
      await _tts.setSpeechRate(_speechRate);
    }
    setState(() {
      _isPlaying = true;
      _hasPlayedOnce = true;
    });
    await _tts.speak(widget.exercise.question);
    if (mounted) setState(() => _isPlaying = false);
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenInset,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Listening Exercise',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Click the play button to hear the phrase, then type what you hear',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          Center(
            child: Column(
              children: [
                IconButton(
                  onPressed: _isPlaying ? null : _playAudio,
                  icon: Icon(
                    _isPlaying ? Icons.volume_up : Icons.play_circle_filled,
                    size: 120,
                    color: _isPlaying
                        ? AppColors.textDisabled
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _isPlaying ? 'Playing...' : 'Tap to play audio',
                  style: const TextStyle(
                      fontSize: 16, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Speed:',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      _ListeningSpeedButton(
                        label: '1x',
                        isSelected: _speechRate == _normalRate,
                        onTap: _isPlaying
                            ? () {}
                            : () => _playAudio(rate: _normalRate),
                      ),
                      _ListeningSpeedButton(
                        label: '0.5x',
                        isSelected: _speechRate == _halfRate,
                        onTap: _isPlaying
                            ? () {}
                            : () => _playAudio(rate: _halfRate),
                      ),
                      _ListeningSpeedButton(
                        label: '0.25x',
                        isSelected: _speechRate == _quarterRate,
                        onTap: _isPlaying
                            ? () {}
                            : () => _playAudio(rate: _quarterRate),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          TextField(
            controller: _controller,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22),
            decoration: InputDecoration(
              hintText: 'Type what you hear',
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
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
                      ? (_isCorrect ? AppColors.correct : AppColors.incorrect)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _showFeedback
                      ? (_isCorrect ? AppColors.correct : AppColors.incorrect)
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
              mainAxisAlignment: MainAxisAlignment.center,
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
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ],
          const Spacer(flex: 2),
          if (_hasPlayedOnce && !_showFeedback)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: TextButton(
                  onPressed: () {
                    _controller.text = widget.exercise.correctAnswer;
                    _checkAnswer();
                  },
                  child: const Text(
                    "Can't hear? Show answer",
                    style:
                        TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _showFeedback ? null : _checkAnswer,
              child: const Text('Check', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListeningSpeedButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ListeningSpeedButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textPrimary : AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? Colors.black : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
