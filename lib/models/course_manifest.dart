import 'package:json_annotation/json_annotation.dart';

part 'course_manifest.g.dart';

@JsonSerializable()
class SkillHeader {
  final String id;
  final String name;
  final int level;

  /// Authoring group from the manifest ('foundational', 'intermediate',
  /// 'advanced', 'mastery'). Absent in some courses, and not consistent
  /// enough across them to drive UI headings — those come from the CEFR
  /// tier instead. Parsed so the data is not silently dropped.
  final String? section;

  SkillHeader({
    required this.id,
    required this.name,
    required this.level,
    this.section,
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
