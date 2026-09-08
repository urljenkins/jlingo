import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../models/exercise_samples.dart';
import '../theme/app_colors.dart';
import 'exercises/exercise_renderer_registry.dart';

/// A live, playable instance of one exercise type.
///
/// The catalogue used to describe each type in prose, but a learner deciding
/// whether to switch one off is really asking "do I want to do this?" — and
/// the honest way to answer is to let them do one. This renders the real
/// widget through the same registry a lesson uses, so what they try is
/// exactly what they would get.
///
/// Nothing here touches progress: the sample answer is caught and shown, and
/// never reaches XP, streaks or word knowledge.
class ExercisePreview extends StatefulWidget {
  const ExercisePreview({
    super.key,
    required this.type,
    this.onDisable,
  });

  final ExerciseType type;

  /// "Not for me" — offered right where the learner formed the opinion,
  /// rather than making them scroll back to the switch.
  final VoidCallback? onDisable;

  @override
  State<ExercisePreview> createState() => _ExercisePreviewState();
}

class _ExercisePreviewState extends State<ExercisePreview> {
  /// The surface the exercise is laid out on, then scaled from. Roughly a
  /// phone: exercises assume that much room, and giving it to them here is
  /// what keeps their own layout intact.
  static const double _lessonWidth = 420;
  static const double _lessonHeight = 620;

  /// Height the scaled preview occupies in the catalogue row.
  static const double _previewHeight = 380;

  /// Types with wide control rows or long transcripts — audio scrubbers,
  /// dialogue bubbles, story text. They are laid out on a roomier surface and
  /// scaled down, rather than squeezed until their controls overlap.
  static const Set<ExerciseType> _roomyTypes = {
    ExerciseType.storyLesson,
    ExerciseType.dialogueListening,
    ExerciseType.interactiveDialogue,
    ExerciseType.nativeAudio,
    ExerciseType.songFill,
    ExerciseType.translationExercise,
  };

  bool get _isRoomy => _roomyTypes.contains(widget.type);
  double get _surfaceWidth => _isRoomy ? 560 : _lessonWidth;
  double get _surfaceHeight => _isRoomy ? 900 : _lessonHeight;

  /// Bumped to rebuild the exercise from scratch for another go.
  int _attempt = 0;
  bool? _lastResult;

  Exercise get _sample => ExerciseSamples.of(widget.type);

  void _onAnswer(bool correct) {
    // Deliberately terminal: the preview reports the outcome and stops,
    // rather than advancing as a lesson would.
    setState(() => _lastResult = correct);
  }

  void _again() {
    setState(() {
      _attempt++;
      _lastResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSunken,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Text(
              'TRY IT',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.2,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Exercises are laid out for a full lesson screen, so they are
          // given one here and scaled down to fit the row. Clipping instead
          // would cut off the very controls the learner is meant to try.
          SizedBox(
            height: _previewHeight,
            child: FittedBox(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: _surfaceWidth,
                height: _surfaceHeight,
                child: KeyedSubtree(
                  // A new key per attempt gives the exercise fresh state.
                  key: ValueKey('${widget.type}_$_attempt'),
                  child: ExerciseRendererRegistry.render(
                    exercise: _sample,
                    onAnswer: _onAnswer,
                  ),
                ),
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Row(
        children: [
          if (_lastResult != null)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Icon(
                _lastResult! ? Icons.check_circle : Icons.cancel,
                size: 18,
                color: _lastResult! ? AppColors.correct : AppColors.incorrect,
              ),
            ),
          TextButton.icon(
            onPressed: _again,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Try again'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              textStyle: const TextStyle(fontSize: 13),
            ),
          ),
          const Spacer(),
          if (widget.onDisable != null)
            TextButton(
              onPressed: widget.onDisable,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textMuted,
                textStyle: const TextStyle(fontSize: 13),
              ),
              child: const Text('Not for me'),
            ),
        ],
      ),
    );
  }
}
