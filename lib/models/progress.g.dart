// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProgress _$UserProgressFromJson(Map<String, dynamic> json) => UserProgress(
  courseId: json['courseId'] as String,
  skillMastery:
      (json['skillMastery'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ) ??
      const {},
  totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
  currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
  lastStudyDate: json['lastStudyDate'] == null
      ? null
      : DateTime.parse(json['lastStudyDate'] as String),
  achievements:
      (json['achievements'] as List<dynamic>?)
          ?.map((e) => Achievement.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  exerciseStats:
      (json['exerciseStats'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ) ??
      const {},
);

Map<String, dynamic> _$UserProgressToJson(UserProgress instance) =>
    <String, dynamic>{
      'courseId': instance.courseId,
      'skillMastery': instance.skillMastery,
      'totalPoints': instance.totalPoints,
      'currentStreak': instance.currentStreak,
      'lastStudyDate': instance.lastStudyDate?.toIso8601String(),
      'achievements': instance.achievements,
      'exerciseStats': instance.exerciseStats,
    };

Achievement _$AchievementFromJson(Map<String, dynamic> json) => Achievement(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  unlockedAt: DateTime.parse(json['unlockedAt'] as String),
);

Map<String, dynamic> _$AchievementToJson(Achievement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'unlockedAt': instance.unlockedAt.toIso8601String(),
    };
