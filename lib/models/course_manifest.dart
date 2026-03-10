import 'package:json_annotation/json_annotation.dart';

part 'course_manifest.g.dart';

@JsonSerializable()
class SkillHeader {
  final String id;
  final String name;
  final int level;

  SkillHeader({
    required this.id,
    required this.name,
    required this.level,
  });

  factory SkillHeader.fromJson(Map<String, dynamic> json) =>
      _$SkillHeaderFromJson(json);

  Map<String, dynamic> toJson() => _$SkillHeaderToJson(this);
}

@JsonSerializable()
class CourseManifest {
  final String id;
  final String name;
  final String targetLanguage;
  final String nativeLanguage;
  final List<SkillHeader> skills;

  CourseManifest({
    required this.id,
    required this.name,
    required this.targetLanguage,
    required this.nativeLanguage,
    required this.skills,
  });

  factory CourseManifest.fromJson(Map<String, dynamic> json) =>
      _$CourseManifestFromJson(json);

  Map<String, dynamic> toJson() => _$CourseManifestToJson(this);
}
