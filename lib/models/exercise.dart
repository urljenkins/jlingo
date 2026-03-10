import 'package:json_annotation/json_annotation.dart';

part 'exercise.g.dart';

enum ExerciseType {
  translateThis,
  matchPairs,
  multipleChoice,
  listeningComprehension,
  speakThis,
  fillInBlank,
  // New listening & pronunciation types
  nativeAudio, // Audio from native speakers (pre-recorded)
  pronunciationPractice, // Speech recognition with accent/accuracy feedback
  dialogueListening, // Short dialogues followed by comprehension questions
  songFill, // Listen to a song and fill in missing lyrics
  // Reading & Writing types
  interactiveDialogue, // Short conversations on various topics
  storyLesson, // Graded readers (stories for specific language levels)
  translationExercise, // Translate sentences/paragraphs (both ways)
  clozeTest, // Fill-in-the-blank with multiple blanks in context
}

@JsonSerializable()
class Exercise {
  final String id;
  final ExerciseType type;
  final String question;
  final String? audioPath;
  final List<String> options;
  final String correctAnswer;
  final String? targetLanguage;
  final String? nativeLanguage;
  final Map<String, dynamic>? metadata;
  final double? difficultyRating;
  final bool isFlashcardEligible;

  Exercise({
    required this.id,
    required this.type,
    required this.question,
    this.audioPath,
    required this.options,
    required this.correctAnswer,
    this.targetLanguage,
    this.nativeLanguage,
    this.metadata,
    this.difficultyRating,
    this.isFlashcardEligible = false,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) =>
      _$ExerciseFromJson(json);
  Map<String, dynamic> toJson() => _$ExerciseToJson(this);
}

@JsonSerializable()
class MatchPair {
  final String target;
  final String native;

  MatchPair({required this.target, required this.native});

  factory MatchPair.fromJson(Map<String, dynamic> json) =>
      _$MatchPairFromJson(json);
  Map<String, dynamic> toJson() => _$MatchPairToJson(this);
}
