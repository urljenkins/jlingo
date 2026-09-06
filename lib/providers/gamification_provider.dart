import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/gamification.dart';
import '../models/course_manifest.dart';
import '../models/cefr_level.dart';
import '../models/user_profile.dart';

/// Provider for gamification features: XP, Levels, Streaks, and Progression
class GamificationProvider extends ChangeNotifier {
  UserLevel _userLevel = UserLevel.fromXP(0);
  StreakInfo _streakInfo = StreakInfo(
    currentStreak: 0,
    longestStreak: 0,
    isActiveToday: false,
    studyHistory: [],
  );
  DailyGoal _dailyGoal = DailyGoal(
    targetXP: 50,
    earnedXP: 0,
    date: DateTime.now(),
    isCompleted: false,
  );
  List<XPEvent> _xpHistory = [];
  List<ProgressionPath> _progressionPaths = [];

  // Getters
  UserLevel get userLevel => _userLevel;
  StreakInfo get streakInfo => _streakInfo;
  DailyGoal get dailyGoal => _dailyGoal;
  List<XPEvent> get xpHistory => _xpHistory;
  List<ProgressionPath> get progressionPaths => _progressionPaths;

  /// Load gamification data from storage
  Future<void> loadGamificationData(String courseId) async {
    final prefs = await SharedPreferences.getInstance();

    // Load XP and level
    final totalXP = prefs.getInt('xp_$courseId') ?? 0;
    _userLevel = UserLevel.fromXP(totalXP);

    // Load streak info
    final streakJson = prefs.getString('streak_$courseId');
    if (streakJson != null) {
      try {
        _streakInfo =
            StreakInfo.fromJson(jsonDecode(streakJson) as Map<String, dynamic>);
        // Check if streak is still valid
        _validateStreak();
      } catch (e) {
        _streakInfo = StreakInfo(
          currentStreak: 0,
          longestStreak: 0,
          isActiveToday: false,
          studyHistory: [],
        );
      }
    }

    // Load daily goal
    final goalJson = prefs.getString('daily_goal_$courseId');
    if (goalJson != null) {
      try {
        final savedGoal =
            DailyGoal.fromJson(jsonDecode(goalJson) as Map<String, dynamic>);
        // Check if it's the same day
        if (_isSameDay(savedGoal.date, DateTime.now())) {
          _dailyGoal = savedGoal;
        } else {
          // New day, reset daily goal
          _dailyGoal = DailyGoal(
            targetXP: prefs.getInt('daily_goal_target_$courseId') ?? 50,
            earnedXP: 0,
            date: DateTime.now(),
            isCompleted: false,
          );
        }
      } catch (e) {
        _dailyGoal = DailyGoal(
          targetXP: 50,
          earnedXP: 0,
          date: DateTime.now(),
          isCompleted: false,
        );
      }
    }

    // Load XP history (last 30 events)
    final historyJson = prefs.getString('xp_history_$courseId');
    if (historyJson != null) {
      try {
        final decoded = jsonDecode(historyJson) as List<dynamic>;
        _xpHistory = decoded
            .map((e) => XPEvent.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        _xpHistory = [];
      }
    }

    notifyListeners();
  }

  /// Save gamification data to storage
  Future<void> _saveGamificationData(String courseId) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('xp_$courseId', _userLevel.currentXP);
    await prefs.setString('streak_$courseId', jsonEncode(_streakInfo.toJson()));
    await prefs.setString(
        'daily_goal_$courseId', jsonEncode(_dailyGoal.toJson()));

    // Keep only last 30 XP events
    final recentHistory = _xpHistory.take(30).toList();
    await prefs.setString('xp_history_$courseId',
        jsonEncode(recentHistory.map((e) => e.toJson()).toList()));
  }

  /// Award XP for an action
  Future<XPGainResult> awardXP({
    required String courseId,
    required String type,
    required int baseAmount,
    String? description,
  }) async {
    final previousLevel = _userLevel.level;

    // Apply streak multiplier
    final multiplier = _streakInfo.multiplier;
    final bonusXP = (baseAmount * (multiplier - 1)).round();
    final totalXP = baseAmount + bonusXP;

    // Update level
    final newTotalXP = _userLevel.currentXP + totalXP;
    _userLevel = UserLevel.fromXP(newTotalXP);

    // Record XP event
    final event = XPEvent(
      type: type,
      amount: totalXP,
      timestamp: DateTime.now(),
      description: description,
    );
    _xpHistory.insert(0, event);

    // Update daily goal
    final newEarnedXP = _dailyGoal.earnedXP + totalXP;
    final wasCompleted = _dailyGoal.isCompleted;
    final isNowCompleted = newEarnedXP >= _dailyGoal.targetXP;

    _dailyGoal = DailyGoal(
      targetXP: _dailyGoal.targetXP,
      earnedXP: newEarnedXP,
      date: _dailyGoal.date,
      isCompleted: isNowCompleted,
    );

    // Check for level up
    final leveledUp = _userLevel.level > previousLevel;
    int levelUpBonus = 0;
    if (leveledUp) {
      levelUpBonus = XPRewards.levelUp;
      _userLevel = UserLevel.fromXP(_userLevel.currentXP + levelUpBonus);
    }

    // Check for daily goal completion bonus
    int dailyGoalBonus = 0;
    if (!wasCompleted && isNowCompleted) {
      dailyGoalBonus = XPRewards.dailyGoalComplete;
      _userLevel = UserLevel.fromXP(_userLevel.currentXP + dailyGoalBonus);
    }

    // State is already updated in memory: notify and return immediately so the
    // lesson can advance, and let the prefs writes settle in the background.
    notifyListeners();
    unawaited(_saveGamificationData(courseId));

    return XPGainResult(
      baseXP: baseAmount,
      bonusXP: bonusXP,
      totalXP: totalXP + levelUpBonus + dailyGoalBonus,
      leveledUp: leveledUp,
      newLevel: leveledUp ? _userLevel.level : null,
      dailyGoalCompleted: !wasCompleted && isNowCompleted,
    );
  }

  /// Record study activity and update streak
  Future<StreakUpdateResult> recordStudyActivity(String courseId) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    // Check if already studied today
    if (_streakInfo.isActiveToday) {
      return StreakUpdateResult(
        previousStreak: _streakInfo.currentStreak,
        newStreak: _streakInfo.currentStreak,
        streakIncreased: false,
        streakBroken: false,
        isNewRecord: false,
      );
    }

    final previousStreak = _streakInfo.currentStreak;
    int newStreak;
    bool streakBroken = false;

    if (_streakInfo.lastStudyDate == null) {
      // First time studying
      newStreak = 1;
    } else {
      final lastStudyDay = DateTime(
        _streakInfo.lastStudyDate!.year,
        _streakInfo.lastStudyDate!.month,
        _streakInfo.lastStudyDate!.day,
      );
      final daysSinceLastStudy = todayStart.difference(lastStudyDay).inDays;

      if (daysSinceLastStudy == 0) {
        // Same day
        newStreak = previousStreak;
      } else if (daysSinceLastStudy == 1) {
        // Consecutive day
        newStreak = previousStreak + 1;
      } else {
        // Streak broken
        newStreak = 1;
        streakBroken = true;
      }
    }

    // Update study history (keep last 30 days)
    final newHistory = [now, ..._streakInfo.studyHistory].take(30).toList();
    final newLongestStreak = newStreak > _streakInfo.longestStreak
        ? newStreak
        : _streakInfo.longestStreak;

    _streakInfo = StreakInfo(
      currentStreak: newStreak,
      longestStreak: newLongestStreak,
      lastStudyDate: now,
      isActiveToday: true,
      streakFreezeCount: _streakInfo.streakFreezeCount,
      studyHistory: newHistory,
    );

    await _saveGamificationData(courseId);
    notifyListeners();

    return StreakUpdateResult(
      previousStreak: previousStreak,
      newStreak: newStreak,
      streakIncreased: newStreak > previousStreak,
      streakBroken: streakBroken,
      isNewRecord: newStreak > _streakInfo.longestStreak,
    );
  }

  /// Validate streak (check if it should be reset)
  void _validateStreak() {
    if (_streakInfo.lastStudyDate == null) return;

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final lastStudyDay = DateTime(
      _streakInfo.lastStudyDate!.year,
      _streakInfo.lastStudyDate!.month,
      _streakInfo.lastStudyDate!.day,
    );
    final daysSinceLastStudy = todayStart.difference(lastStudyDay).inDays;

    // Update isActiveToday
    final isActiveToday = daysSinceLastStudy == 0;

    // Check if streak is broken (more than 1 day since last study)
    if (daysSinceLastStudy > 1) {
      _streakInfo = StreakInfo(
        currentStreak: 0,
        longestStreak: _streakInfo.longestStreak,
        lastStudyDate: _streakInfo.lastStudyDate,
        isActiveToday: false,
        streakFreezeCount: _streakInfo.streakFreezeCount,
        studyHistory: _streakInfo.studyHistory,
      );
    } else {
      _streakInfo = StreakInfo(
        currentStreak: _streakInfo.currentStreak,
        longestStreak: _streakInfo.longestStreak,
        lastStudyDate: _streakInfo.lastStudyDate,
        isActiveToday: isActiveToday,
        streakFreezeCount: _streakInfo.streakFreezeCount,
        studyHistory: _streakInfo.studyHistory,
      );
    }
  }

  /// Update progression paths from course skills
  void updateProgressionPaths(
    List<SkillHeader> skills,
    Set<String> completedSkills,
    Map<String, double> skillMastery, {
    LanguageLevel? entryLevel,
  }) {
    final courseSkillLevels = skills.map((s) => s.level).toList();

    // Group skills by level
    final Map<int, List<SkillNode>> groupedSkills = {};

    for (var i = 0; i < skills.length; i++) {
      final skill = skills[i];
      final mastery = skillMastery[skill.id] ?? 0.0;
      final node = SkillNode(
        skillId: skill.id,
        name: skill.name,
        level: skill.level,
        mastery: mastery / 100,
        isUnlocked: isSkillUnlocked(
          skillLevel: skill.level,
          position: i,
          previousCompleted:
              i > 0 && completedSkills.contains(skills[i - 1].id),
          entryLevel: entryLevel,
          courseSkillLevels: courseSkillLevels,
        ),
        isCompleted: completedSkills.contains(skill.id),
        prerequisites: i > 0 ? [skills[i - 1].id] : [],
      );

      groupedSkills.putIfAbsent(skill.level, () => []).add(node);
    }

    // Create progression paths for each level
    _progressionPaths = groupedSkills.entries.map((entry) {
      final levelSkills = entry.value;
      final completedCount = levelSkills.where((s) => s.isCompleted).length;
      final totalProgress =
          levelSkills.isEmpty ? 0.0 : completedCount / levelSkills.length;

      return ProgressionPath(
        pathId: 'level_${entry.key}',
        name: _getLevelTitle(entry.key),
        skills: levelSkills,
        totalProgress: totalProgress,
      );
    }).toList()
      ..sort((a, b) => int.parse(a.pathId.split('_')[1])
          .compareTo(int.parse(b.pathId.split('_')[1])));

    notifyListeners();
  }

  String _getLevelTitle(int level) {
    switch (level) {
      case 1:
        return 'Fundamentals';
      case 2:
        return 'Building Blocks';
      case 3:
        return 'Expanding Horizons';
      case 4:
        return 'Advanced Topics';
      case 5:
        return 'Mastery';
      default:
        return 'Level $level';
    }
  }

  /// Set daily XP goal
  Future<void> setDailyGoal(String courseId, int targetXP) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('daily_goal_target_$courseId', targetXP);

    _dailyGoal = DailyGoal(
      targetXP: targetXP,
      earnedXP: _dailyGoal.earnedXP,
      date: _dailyGoal.date,
      isCompleted: _dailyGoal.earnedXP >= targetXP,
    );

    await _saveGamificationData(courseId);
    notifyListeners();
  }

  /// Get XP earned today
  int get todayXP {
    final today = DateTime.now();
    return _xpHistory
        .where((e) => _isSameDay(e.timestamp, today))
        .fold(0, (sum, e) => sum + e.amount);
  }

  /// Get XP earned this week
  int get weeklyXP {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return _xpHistory
        .where((e) => e.timestamp.isAfter(weekStart))
        .fold(0, (sum, e) => sum + e.amount);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// Result of XP gain operation
class XPGainResult {
  final int baseXP;
  final int bonusXP;
  final int totalXP;
  final bool leveledUp;
  final int? newLevel;
  final bool dailyGoalCompleted;

  XPGainResult({
    required this.baseXP,
    required this.bonusXP,
    required this.totalXP,
    required this.leveledUp,
    this.newLevel,
    required this.dailyGoalCompleted,
  });
}

/// Result of streak update operation
class StreakUpdateResult {
  final int previousStreak;
  final int newStreak;
  final bool streakIncreased;
  final bool streakBroken;
  final bool isNewRecord;

  StreakUpdateResult({
    required this.previousStreak,
    required this.newStreak,
    required this.streakIncreased,
    required this.streakBroken,
    required this.isNewRecord,
  });
}
