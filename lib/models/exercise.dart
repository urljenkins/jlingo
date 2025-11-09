import 'package:json_annotation/json_annotation.dart';

part 'exercise.g.dart';

enum ExerciseType {
  translateThis,
  matchPairs,
  multipleChoice,
  listeningComprehension,
  speakThis,
  fillInBlank,
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
  });

  factory Exercise.fromJson(Map<String, dynamic> json) => _$ExerciseFromJson(json);
  Map<String, dynamic> toJson() => _$ExerciseToJson(this);
}

@JsonSerializable()
class MatchPair {
  final String target;
  final String native;

  MatchPair({required this.target, required this.native});

  factory MatchPair.fromJson(Map<String, dynamic> json) => _$MatchPairFromJson(json);
  Map<String, dynamic> toJson() => _$MatchPairToJson(this);
}
