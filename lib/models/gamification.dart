import 'package:json_annotation/json_annotation.dart';

part 'gamification.g.dart';

/// XP rewards for different actions
class XPRewards {
  static const int lessonComplete = 10;
  static const int exerciseCorrect = 5;
  static const int perfectLesson = 20; // Bonus for no mistakes
  static const int streakBonus = 5; // Per day of streak (capped at 50)
  static const int skillMastered = 50; // First time reaching 100% on a skill
  static const int levelUp = 100; // Bonus XP for leveling up
  static const int dailyGoalComplete = 15;
}

/// Level thresholds and configuration
class LevelConfig {
  /// XP required to reach each level
  /// Level 1: 0 XP, Level 2: 100 XP, Level 3: 250 XP, etc.
  static const List<int> thresholds = [
    0, // Level 1
    100, // Level 2
    250, // Level 3
    500, // Level 4
    850, // Level 5
    1300, // Level 6
    1850, // Level 7
    2500, // Level 8
    3300, // Level 9
    4200, // Level 10
    5250, // Level 11
    6450, // Level 12
    7800, // Level 13
    9300, // Level 14
    11000, // Level 15
    12900, // Level 16
    15000, // Level 17
    17300, // Level 18
    19800, // Level 19
    22500, // Level 20
    25500, // Level 21
    28800, // Level 22
    32400, // Level 23
    36300, // Level 24
    40500, // Level 25
    45000, // Level 26
    50000, // Level 27
    55500, // Level 28
    61500, // Level 29
    68000, // Level 30
  ];

  static const List<String> titles = [
    'Newcomer', // 1
    'Beginner', // 2
    'Apprentice', // 3
    'Student', // 4
    'Learner', // 5
    'Explorer', // 6
    'Adventurer', // 7
    'Scholar', // 8
    'Polyglot', // 9
    'Linguist', // 10
    'Expert', // 11
    'Specialist', // 12
    'Master', // 13
    'Virtuoso', // 14
    'Sage', // 15
    'Guru', // 16
    'Champion', // 17
    'Legend', // 18
    'Hero', // 19
    'Elite', // 20
    'Conqueror', // 21
    'Titan', // 22
    'Wizard', // 23
    'Prodigy', // 24
    'Genius', // 25
    'Paragon', // 26
    'Grandmaster', // 27
    'Overlord', // 28
    'Transcendent', // 29
    'Immortal', // 30
  ];

  /// Get level from total XP
  static int getLevelFromXP(int xp) {
    for (int i = thresholds.length - 1; i >= 0; i--) {
      if (xp >= thresholds[i]) {
        return i + 1;
      }
    }
    return 1;
  }

  /// Get title for a level
  static String getTitleForLevel(int level) {
    if (level < 1) return titles[0];
    if (level > titles.length) return titles.last;
    return titles[level - 1];
  }

  /// Get XP required to reach next level
  static int getXPForNextLevel(int currentXP) {
    final currentLevel = getLevelFromXP(currentXP);
    if (currentLevel >= thresholds.length) {
      return currentXP; // Max level reached
    }
    return thresholds[currentLevel];
  }

  /// Get XP progress within current level (0.0 to 1.0)
  static double getLevelProgress(int xp) {
    final level = getLevelFromXP(xp);
    if (level >= thresholds.length) return 1.0;

    final currentLevelXP = thresholds[level - 1];
    final nextLevelXP = thresholds[level];
    final progressXP = xp - currentLevelXP;
    final requiredXP = nextLevelXP - currentLevelXP;

    return progressXP / requiredXP;
  }

  /// Get XP remaining to next level
  static int getXPToNextLevel(int xp) {
    final nextLevelXP = getXPForNextLevel(xp);
    return nextLevelXP - xp;
  }
}

/// Streak configuration
class StreakConfig {
  /// Days until streak freeze expires
  static const int freezeDays = 1;

  /// Maximum streak bonus multiplier
  static const double maxStreakMultiplier = 2.0;

  /// Days to reach max multiplier
  static const int daysToMaxMultiplier = 30;

  /// Calculate streak bonus multiplier (1.0 to maxStreakMultiplier)
  static double getStreakMultiplier(int streakDays) {
    if (streakDays <= 0) return 1.0;
    final progress = streakDays / daysToMaxMultiplier;
    final multiplier =
        1.0 + (maxStreakMultiplier - 1.0) * progress.clamp(0.0, 1.0);
    return multiplier;
  }

  /// Get streak bonus XP
  static int getStreakBonus(int streakDays) {
    return (streakDays * XPRewards.streakBonus).clamp(0, 50);
  }

  /// Streak milestones for achievements
  static const List<int> milestones = [3, 7, 14, 30, 60, 100, 180, 365];
}

/// XP gain event for history tracking
@JsonSerializable()
class XPEvent {
  final String type;
  final int amount;
  final DateTime timestamp;
  final String? description;

  XPEvent({
    required this.type,
    required this.amount,
    required this.timestamp,
    this.description,
  });

  factory XPEvent.fromJson(Map<String, dynamic> json) =>
      _$XPEventFromJson(json);
  Map<String, dynamic> toJson() => _$XPEventToJson(this);
}

/// User level information
@JsonSerializable()
class UserLevel {
  final int level;
  final String title;
  final int currentXP;
  final int xpForNextLevel;
  final double progress;

  UserLevel({
    required this.level,
    required this.title,
    required this.currentXP,
    required this.xpForNextLevel,
    required this.progress,
  });

  factory UserLevel.fromXP(int xp) {
    final level = LevelConfig.getLevelFromXP(xp);
    return UserLevel(
      level: level,
      title: LevelConfig.getTitleForLevel(level),
      currentXP: xp,
      xpForNextLevel: LevelConfig.getXPForNextLevel(xp),
      progress: LevelConfig.getLevelProgress(xp),
    );
  }

  factory UserLevel.fromJson(Map<String, dynamic> json) =>
      _$UserLevelFromJson(json);
  Map<String, dynamic> toJson() => _$UserLevelToJson(this);

  bool get isMaxLevel => level >= LevelConfig.thresholds.length;
}

/// Streak information
@JsonSerializable()
class StreakInfo {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastStudyDate;
  final bool isActiveToday;
  final int streakFreezeCount;
  final List<DateTime> studyHistory; // Last 30 days

  StreakInfo({
    required this.currentStreak,
    required this.longestStreak,
    this.lastStudyDate,
    required this.isActiveToday,
    this.streakFreezeCount = 0,
    this.studyHistory = const [],
  });

  factory StreakInfo.fromJson(Map<String, dynamic> json) =>
      _$StreakInfoFromJson(json);
  Map<String, dynamic> toJson() => _$StreakInfoToJson(this);

  double get multiplier => StreakConfig.getStreakMultiplier(currentStreak);
  int get bonusXP => StreakConfig.getStreakBonus(currentStreak);

  /// Check if streak would break tomorrow
  bool get atRisk {
    if (lastStudyDate == null) return false;
    final now = DateTime.now();
    final daysSinceStudy = _daysBetween(lastStudyDate!, now);
    return daysSinceStudy == 1 && !isActiveToday;
  }

  static int _daysBetween(DateTime from, DateTime to) {
    final fromDate = DateTime(from.year, from.month, from.day);
    final toDate = DateTime(to.year, to.month, to.day);
    return toDate.difference(fromDate).inDays;
  }
}

/// Skill node for skill tree visualization
@JsonSerializable()
class SkillNode {
  final String skillId;
  final String name;
  final int level;
  final double mastery; // 0.0 to 1.0
  final bool isUnlocked;
  final bool isCompleted;
  final List<String> prerequisites; // Skill IDs that must be completed first

  SkillNode({
    required this.skillId,
    required this.name,
    required this.level,
    required this.mastery,
    required this.isUnlocked,
    required this.isCompleted,
    this.prerequisites = const [],
  });

  factory SkillNode.fromJson(Map<String, dynamic> json) =>
      _$SkillNodeFromJson(json);
  Map<String, dynamic> toJson() => _$SkillNodeToJson(this);
}

/// Progression path for skill tree
@JsonSerializable()
class ProgressionPath {
  final String pathId;
  final String name;
  final List<SkillNode> skills;
  final double totalProgress; // 0.0 to 1.0

  ProgressionPath({
    required this.pathId,
    required this.name,
    required this.skills,
    required this.totalProgress,
  });

  factory ProgressionPath.fromJson(Map<String, dynamic> json) =>
      _$ProgressionPathFromJson(json);
  Map<String, dynamic> toJson() => _$ProgressionPathToJson(this);

  int get completedSkills => skills.where((s) => s.isCompleted).length;
  int get totalSkills => skills.length;
}

/// Daily goal tracking
@JsonSerializable()
class DailyGoal {
  final int targetXP;
  final int earnedXP;
  final DateTime date;
  final bool isCompleted;

  DailyGoal({
    required this.targetXP,
    required this.earnedXP,
    required this.date,
    required this.isCompleted,
  });

  factory DailyGoal.fromJson(Map<String, dynamic> json) =>
      _$DailyGoalFromJson(json);
  Map<String, dynamic> toJson() => _$DailyGoalToJson(this);

  double get progress => (earnedXP / targetXP).clamp(0.0, 1.0);
  int get remainingXP => (targetXP - earnedXP).clamp(0, targetXP);
}
