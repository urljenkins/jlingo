// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Exercise _$ExerciseFromJson(Map<String, dynamic> json) => Exercise(
  id: json['id'] as String,
  type: $enumDecode(_$ExerciseTypeEnumMap, json['type']),
  question: json['question'] as String,
  audioPath: json['audioPath'] as String?,
  options: (json['options'] as List<dynamic>).map((e) => e as String).toList(),
  correctAnswer: json['correctAnswer'] as String,
  targetLanguage: json['targetLanguage'] as String?,
  nativeLanguage: json['nativeLanguage'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$ExerciseToJson(Exercise instance) => <String, dynamic>{
  'id': instance.id,
  'type': _$ExerciseTypeEnumMap[instance.type]!,
  'question': instance.question,
  'audioPath': instance.audioPath,
  'options': instance.options,
  'correctAnswer': instance.correctAnswer,
  'targetLanguage': instance.targetLanguage,
  'nativeLanguage': instance.nativeLanguage,
  'metadata': instance.metadata,
};

const _$ExerciseTypeEnumMap = {
  ExerciseType.translateThis: 'translateThis',
  ExerciseType.matchPairs: 'matchPairs',
  ExerciseType.multipleChoice: 'multipleChoice',
  ExerciseType.listeningComprehension: 'listeningComprehension',
  ExerciseType.speakThis: 'speakThis',
  ExerciseType.fillInBlank: 'fillInBlank',
};

MatchPair _$MatchPairFromJson(Map<String, dynamic> json) => MatchPair(
  target: json['target'] as String,
  native: json['native'] as String,
);

Map<String, dynamic> _$MatchPairToJson(MatchPair instance) => <String, dynamic>{
  'target': instance.target,
  'native': instance.native,
};
