import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../models/exercise.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'word_bank_input.dart';

/// Assemble-the-answer exercise, in both its written and spoken forms.
///
/// One widget serves `wordBankTranslate` ("Translate this sentence") and
/// `tapWhatYouHear` ("Tap what you hear"). They differ only in whether the
/// prompt is shown or played, and sharing the widget keeps the tile
/// behaviour, marking and feedback identical between them.
class WordBankExerciseWidget extends StatefulWidget {
  const WordBankExerciseWidget({
    super.key,
    required this.exercise,
    required this.onAnswer,
    required this.listening,
  });

  final Exercise exercise;
  final void Function(bool) onAnswer;

  /// When true the prompt is audio-only until answered — the difference
  /// between reading a sentence and hearing one.
  final bool listening;

  @override
  State<WordBankExerciseWidget> createState() => _WordBankExerciseWidgetState();
}

class _WordBankExerciseWidgetState extends State<WordBankExerciseWidget> {
  final _tts = FlutterTts();
  String _answer = '';
  bool _showFeedback = false;
  bool _isCorrect = false;

  /// Normal and slow playback, mirroring the two speaker buttons Duolingo
  /// shows. Slow is what makes a run-together phrase separate into words.
  static const double _normalRate = 0.5;
  static const double _slowRate = 0.25;

  @override
  void initState() {
    super.initState();
    if (widget.listening) {
      // Play once on arrival: the exercise is unanswerable in silence, so
      // making the learner press play first is a step with no purpose.
      WidgetsBinding.instance.addPostFrameCallback((_) => _play());
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _play({double rate = _normalRate}) async {
    await _tts.setLanguage(widget.exercise.targetLanguage ?? 'es-ES');
    await _tts.setSpeechRate(rate);
    await _tts.speak(_prompt);
  }

  /// What is spoken or shown. For listening the learner rebuilds what they
  /// hear, so the prompt is the answer itself; for translation the question
  /// is the source sentence.
  String get _prompt => widget.listening
      ? widget.exercise.correctAnswer
      : widget.exercise.question;

  /// Distractor tiles the author supplied. Options are reused for this rather
  /// than adding a field, so existing content shapes carry over.
  List<String> get _distractors =>
      widget.exercise.options.where((o) => o.trim().isNotEmpty).toList();

  void _check() {
    if (_showFeedback) return;

    // Compared on collapsed whitespace and case: the learner assembled the
    // tiles, so spacing is an artefact of assembly rather than an error.
    String normalise(String s) => s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

    setState(() {
      _isCorrect =
          normalise(_answer) == normalise(widget.exercise.correctAnswer);
      _showFeedback = true;
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) widget.onAnswer(_isCorrect);
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
          Text(
            widget.listening ? 'Tap what you hear' : 'Translate this sentence',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          _buildPrompt(),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: WordBankInput(
                correctAnswer: widget.exercise.correctAnswer,
                distractors: _distractors,
                enabled: !_showFeedback,
                onChanged: (value) => setState(() => _answer = value),
              ),
            ),
          ),
          if (_showFeedback) _buildFeedback(),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _answer.isEmpty || _showFeedback ? null : _check,
            child: const Text('Check'),
          ),
        ],
      ),
    );
  }

  Widget _buildPrompt() {
    if (!widget.listening) {
      return Text(
        widget.exercise.question,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      );
    }

    // Two speakers, normal and slow — the phrase itself stays hidden until
    // the answer is in, so this trains the ear rather than reading.
    return Row(
      children: [
        _AudioButton(
          icon: Icons.volume_up,
          label: 'Play',
          onTap: _play,
        ),
        const SizedBox(width: 12),
        _AudioButton(
          icon: Icons.slow_motion_video,
          label: 'Slow',
          onTap: () => _play(rate: _slowRate),
        ),
      ],
    );
  }

  Widget _buildFeedback() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (_isCorrect ? AppColors.correct : AppColors.incorrect)
            .withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            _isCorrect ? Icons.check_circle : Icons.cancel,
            color: _isCorrect ? AppColors.correct : AppColors.incorrect,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _isCorrect
                  ? 'Correct'
                  : 'Answer: ${widget.exercise.correctAnswer}',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _AudioButton extends StatelessWidget {
  const _AudioButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
    );
  }
}
