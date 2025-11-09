import 'package:json_annotation/json_annotation.dart';
import 'exercise.dart';

part 'skill.g.dart';

@JsonSerializable()
class Skill {
  final String id;
  final String name;
  final String description;
  final int level;
  final List<Exercise> exercises;

  Skill({
    required this.id,
    required this.name,
    required this.description,
    required this.level,
    required this.exercises,
  });

  factory Skill.fromJson(Map<String, dynamic> json) => _$SkillFromJson(json);
  Map<String, dynamic> toJson() => _$SkillToJson(this);
}
