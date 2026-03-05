// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skill.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Skill _$SkillFromJson(Map<String, dynamic> json) => Skill(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String,
  level: (json['level'] as num).toInt(),
  exercises: (json['exercises'] as List<dynamic>)
      .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$SkillToJson(Skill instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'level': instance.level,
  'exercises': instance.exercises,
};
