import 'package:flutter/material.dart';
import '../../models/exercise.dart';
import 'translate_this_widget.dart';
import 'match_pairs_widget.dart';
import 'multiple_choice_widget.dart';
import 'listening_widget.dart';
import 'speak_this_widget.dart';
import 'fill_blank_widget.dart';
import 'interactive_dialogue_widget.dart';
import 'story_lesson_widget.dart';
import 'translation_exercise_widget.dart';
import 'cloze_test_widget.dart';
import 'native_audio_widget.dart';
import 'pronunciation_practice_widget.dart';
import 'dialogue_listening_widget.dart';
import 'song_fill_widget.dart';
import 'word_bank_exercise_widget.dart';
import 'select_image_widget.dart';
import 'complete_the_chat_widget.dart';

typedef ExerciseRenderer = Widget Function({
  required Exercise exercise,
  required void Function(bool) onAnswer,
});

class ExerciseRendererRegistry {
  static final Map<ExerciseType, ExerciseRenderer> _registry = {
    ExerciseType.translateThis: ({required exercise, required onAnswer}) =>
        TranslateThisWidget(exercise: exercise, onAnswer: onAnswer),
    ExerciseType.matchPairs: ({required exercise, required onAnswer}) =>
        MatchPairsWidget(exercise: exercise, onAnswer: onAnswer),
    ExerciseType.multipleChoice: ({required exercise, required onAnswer}) =>
        MultipleChoiceWidget(exercise: exercise, onAnswer: onAnswer),
    ExerciseType.listeningComprehension: (
            {required exercise, required onAnswer}) =>
        ListeningWidget(exercise: exercise, onAnswer: onAnswer),
    ExerciseType.speakThis: ({required exercise, required onAnswer}) =>
        SpeakThisWidget(exercise: exercise, onAnswer: onAnswer),
    ExerciseType.fillInBlank: ({required exercise, required onAnswer}) =>
        FillBlankWidget(exercise: exercise, onAnswer: onAnswer),
    // Reading & Writing exercise types
    ExerciseType.interactiveDialogue: (
            {required exercise, required onAnswer}) =>
        InteractiveDialogueWidget(exercise: exercise, onAnswer: onAnswer),
    ExerciseType.storyLesson: ({required exercise, required onAnswer}) =>
        StoryLessonWidget(exercise: exercise, onAnswer: onAnswer),
    ExerciseType.translationExercise: (
            {required exercise, required onAnswer}) =>
        TranslationExerciseWidget(exercise: exercise, onAnswer: onAnswer),
    ExerciseType.clozeTest: ({required exercise, required onAnswer}) =>
        ClozeTestWidget(exercise: exercise, onAnswer: onAnswer),
    // Listening & Pronunciation exercise types
    ExerciseType.nativeAudio: ({required exercise, required onAnswer}) =>
        NativeAudioWidget(exercise: exercise, onAnswer: onAnswer),
    ExerciseType.pronunciationPractice: (
            {required exercise, required onAnswer}) =>
        PronunciationPracticeWidget(exercise: exercise, onAnswer: onAnswer),
    ExerciseType.dialogueListening: ({required exercise, required onAnswer}) =>
        DialogueListeningWidget(exercise: exercise, onAnswer: onAnswer),
    ExerciseType.songFill: ({required exercise, required onAnswer}) =>
        SongFillWidget(exercise: exercise, onAnswer: onAnswer),
    // Tap-to-assemble and visual types.
    ExerciseType.wordBankTranslate: ({required exercise, required onAnswer}) =>
        WordBankExerciseWidget(
            exercise: exercise, onAnswer: onAnswer, listening: false),
    ExerciseType.tapWhatYouHear: ({required exercise, required onAnswer}) =>
        WordBankExerciseWidget(
            exercise: exercise, onAnswer: onAnswer, listening: true),
    ExerciseType.selectImage: ({required exercise, required onAnswer}) =>
        SelectImageWidget(exercise: exercise, onAnswer: onAnswer),
    ExerciseType.completeTheChat: ({required exercise, required onAnswer}) =>
        CompleteTheChatWidget(exercise: exercise, onAnswer: onAnswer),
  };

  static Widget render({
    required Exercise exercise,
    required void Function(bool) onAnswer,
  }) {
    final renderer = _registry[exercise.type];
    if (renderer == null) {
      return Center(
        child: Text('No renderer registered for ${exercise.type}'),
      );
    }
    // Key by exercise id so advancing to a new exercise of the same type
    // builds a fresh State instead of reusing the previous one's answer state.
    return KeyedSubtree(
      key: ValueKey(exercise.id),
      child: renderer(exercise: exercise, onAnswer: onAnswer),
    );
  }

  static void register(ExerciseType type, ExerciseRenderer renderer) {
    _registry[type] = renderer;
  }
}
