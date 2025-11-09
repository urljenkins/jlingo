import 'package:json_annotation/json_annotation.dart';
import 'skill.dart';

part 'course.g.dart';

@JsonSerializable()
class Course {
  final String id;
  final String name;
  final String targetLanguage;
  final String nativeLanguage;
  final List<Skill> skills;

  Course({
    required this.id,
    required this.name,
    required this.targetLanguage,
    required this.nativeLanguage,
    required this.skills,
  });

  factory Course.fromJson(Map<String, dynamic> json) => _$CourseFromJson(json);
  Map<String, dynamic> toJson() => _$CourseToJson(this);
}
