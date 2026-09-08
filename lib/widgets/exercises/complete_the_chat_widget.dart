import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../models/exercise.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// "Complete the chat": a short conversation with the learner's turn left
/// blank, filled by choosing a reply.
///
/// Distinct from `interactiveDialogue`, which plays a whole conversation turn
/// by turn. Here the exchange is shown at once with one gap, so the choice is
/// judged against visible context — the reply has to fit what was actually
/// said, which is what makes a wrong-register option obviously wrong.
class CompleteTheChatWidget extends StatefulWidget {
  const CompleteTheChatWidget({
    super.key,
    required this.exercise,
    required this.onAnswer,
  });

  final Exercise exercise;
  final void Function(bool) onAnswer;

  @override
  State<CompleteTheChatWidget> createState() => _CompleteTheChatWidgetState();
}

/// One line of the conversation. [isLearner] marks the turn to be filled.
class _ChatLine {
  const _ChatLine({required this.text, required this.isLearner});

  final String text;
  final bool isLearner;
}

class _CompleteTheChatWidgetState extends State<CompleteTheChatWidget> {
  final _tts = FlutterTts();
  String? _selected;
  bool _showFeedback = false;

  /// The conversation before the gap.
  ///
  /// Read from metadata when authored as turns; otherwise the question is
  /// treated as a single opening line, so simple content works unchanged.
  List<_ChatLine> get _lines {
    final raw = widget.exercise.metadata?['lines'];
    if (raw is List && raw.isNotEmpty) {
      return [
        for (final entry in raw)
          if (entry is Map)
            _ChatLine(
              text: (entry['text'] ?? '').toString(),
              isLearner: entry['isLearner'] == true,
            ),
      ];
    }
    return [_ChatLine(text: widget.exercise.question, isLearner: false)];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _playPrompt());
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _playPrompt() async {
    final opening =
        _lines.where((l) => !l.isLearner).map((l) => l.text).join(' ');
    if (opening.isEmpty) return;
    await _tts.setLanguage(widget.exercise.targetLanguage ?? 'es-ES');
    await _tts.setSpeechRate(0.5);
    await _tts.speak(opening);
  }

  void _select(String option) {
    if (_showFeedback) return;
    setState(() {
      _selected = option;
      _showFeedback = true;
    });

    final isCorrect = option == widget.exercise.correctAnswer;
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) widget.onAnswer(isCorrect);
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Complete the chat',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final line in _lines) _buildBubble(line),
                  // The gap the learner fills, shown in place so the
                  // conversation reads as a whole.
                  _buildAnswerBubble(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final option in widget.exercise.options)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildOption(option),
            ),
        ],
      ),
    );
  }

  Widget _buildBubble(_ChatLine line) {
    return Align(
      alignment: line.isLearner ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!line.isLearner) ...[
              IconButton(
                onPressed: _playPrompt,
                icon: const Icon(Icons.volume_up, size: 18),
                color: AppColors.textSecondary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Play',
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(line.text, style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  /// The learner's turn: an empty bubble before answering, the chosen reply
  /// after, so the effect of the choice is visible in the conversation.
  Widget _buildAnswerBubble() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 280, minWidth: 120),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _showFeedback
                ? (_selected == widget.exercise.correctAnswer
                    ? AppColors.correct
                    : AppColors.incorrect)
                : AppColors.borderStrong,
          ),
        ),
        child: Text(
          _selected ?? '_______',
          style: TextStyle(
            fontSize: 16,
            color:
                _selected == null ? AppColors.textMuted : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildOption(String option) {
    final isAnswer = option == widget.exercise.correctAnswer;
    final isSelected = option == _selected;

    Color background = AppColors.surfaceRaised;
    Color border = AppColors.border;

    if (_showFeedback) {
      if (isAnswer) {
        background = AppColors.correct.withValues(alpha: 0.18);
        border = AppColors.correct;
      } else if (isSelected) {
        background = AppColors.incorrect.withValues(alpha: 0.18);
        border = AppColors.incorrect;
      }
    }

    return GestureDetector(
      onTap: () => _select(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Text(
          option,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
