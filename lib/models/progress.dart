import 'package:json_annotation/json_annotation.dart';

part 'progress.g.dart';

@JsonSerializable()
class UserProgress {
  final String courseId;

  /// Skills finished at least once. This — not [skillMastery] — decides
  /// where the learner is in the course and what is unlocked, so navigation
  /// never depends on a score.
  final Set<String> completedSkills;

  /// Retained for the optional progress-tracking display. Nothing
  /// structural reads it.
  final Map<String, double> skillMastery; // skillId -> percentage (0-100)
  final int totalPoints;
  final int currentStreak;
  final DateTime? lastStudyDate;
  final List<Achievement> achievements;
  final Map<String, int> exerciseStats; // type -> count

  UserProgress({
    required this.courseId,
    this.completedSkills = const {},
    this.skillMastery = const {},
    this.totalPoints = 0,
    this.currentStreak = 0,
    this.lastStudyDate,
    this.achievements = const [],
    this.exerciseStats = const {},
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) =>
      _$UserProgressFromJson(json);
  Map<String, dynamic> toJson() => _$UserProgressToJson(this);

  UserProgress copyWith({
    String? courseId,
    Set<String>? completedSkills,
    Map<String, double>? skillMastery,
    int? totalPoints,
    int? currentStreak,
    DateTime? lastStudyDate,
    List<Achievement>? achievements,
    Map<String, int>? exerciseStats,
  }) {
    return UserProgress(
      courseId: courseId ?? this.courseId,
      completedSkills: completedSkills ?? this.completedSkills,
      skillMastery: skillMastery ?? this.skillMastery,
      totalPoints: totalPoints ?? this.totalPoints,
      currentStreak: currentStreak ?? this.currentStreak,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      achievements: achievements ?? this.achievements,
      exerciseStats: exerciseStats ?? this.exerciseStats,
    );
  }
}

@JsonSerializable()
class Achievement {
  final String id;
  final String name;
  final String description;
  final DateTime unlockedAt;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.unlockedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) =>
      _$AchievementFromJson(json);
  Map<String, dynamic> toJson() => _$AchievementToJson(this);
}
