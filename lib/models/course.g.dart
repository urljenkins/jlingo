// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Course _$CourseFromJson(Map<String, dynamic> json) => Course(
  id: json['id'] as String,
  name: json['name'] as String,
  targetLanguage: json['targetLanguage'] as String,
  nativeLanguage: json['nativeLanguage'] as String,
  skills: (json['skills'] as List<dynamic>)
      .map((e) => Skill.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$CourseToJson(Course instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'targetLanguage': instance.targetLanguage,
  'nativeLanguage': instance.nativeLanguage,
  'skills': instance.skills,
};
