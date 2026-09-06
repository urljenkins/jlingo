import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/progress.dart';

class ProgressProvider extends ChangeNotifier {
  UserProgress? _progress;
  UserProgress? get progress => _progress;

  Future<void> loadProgress(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = prefs.getString('progress_$courseId');

    if (progressJson != null) {
      try {
        _progress = _migrateCompletedSkills(
          UserProgress.fromJson(
              jsonDecode(progressJson) as Map<String, dynamic>),
        );
      } catch (e) {
        // Corrupt or old-format data must not brick startup.
        debugPrint('Error loading progress for $courseId: $e');
        _progress = UserProgress(courseId: courseId);
      }
    } else {
      _progress = UserProgress(courseId: courseId);
    }
    notifyListeners();
  }

  /// Back-fills [UserProgress.completedSkills] for progress saved before
  /// completion was a boolean. A skill previously at full mastery counts as
  /// finished; anything short of that is picked up again where it was left.
  UserProgress _migrateCompletedSkills(UserProgress loaded) {
    if (loaded.completedSkills.isNotEmpty || loaded.skillMastery.isEmpty) {
      return loaded;
    }

    final completed = loaded.skillMastery.entries
        .where((entry) => entry.value >= 100.0)
        .map((entry) => entry.key)
        .toSet();

    if (completed.isEmpty) return loaded;

    final migrated = loaded.copyWith(completedSkills: completed);
    unawaited(_persist(migrated));
    return migrated;
  }

  Future<void> _persist(UserProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'progress_${progress.courseId}',
      jsonEncode(progress.toJson()),
    );
  }

  Future<void> saveProgress() async {
    if (_progress == null) return;

    await _persist(_progress!);
  }

  /// Marks a skill finished. One pass is enough — this is a bookmark, not a
  /// grade, and it is what unlocks the next skill.
  void markSkillCompleted(String skillId) {
    if (_progress == null) return;
    if (_progress!.completedSkills.contains(skillId)) return;

    _progress = _progress!.copyWith(
      completedSkills: {..._progress!.completedSkills, skillId},
    );

    unawaited(saveProgress());
    notifyListeners();
  }

  // Streak and points are owned by GamificationProvider; this provider
  // tracks skill mastery, exercise stats and achievements only.

  void updateSkillMastery(String skillId, double percentage) {
    if (_progress == null) return;

    final newMastery = Map<String, double>.from(_progress!.skillMastery);
    newMastery[skillId] = percentage;

    _progress = _progress!.copyWith(skillMastery: newMastery);

    unawaited(saveProgress());
    notifyListeners();
  }

  void incrementExerciseStat(String exerciseType) {
    if (_progress == null) return;

    final newStats = Map<String, int>.from(_progress!.exerciseStats);
    newStats[exerciseType] = (newStats[exerciseType] ?? 0) + 1;

    _progress = _progress!.copyWith(exerciseStats: newStats);

    unawaited(saveProgress());
    notifyListeners();
  }

  void unlockAchievement(Achievement achievement) {
    if (_progress == null) return;

    // Check if already unlocked
    if (_progress!.achievements.any((a) => a.id == achievement.id)) {
      return;
    }

    final newAchievements = [..._progress!.achievements, achievement];
    _progress = _progress!.copyWith(achievements: newAchievements);

    unawaited(saveProgress());
    notifyListeners();
  }

  /// [currentStreak] comes from GamificationProvider, the owner of streak state.
  void checkAndUnlockAchievements({int currentStreak = 0}) {
    if (_progress == null) return;

    final stats = _progress!.exerciseStats;
    final totalExercises = stats.values.fold(0, (sum, count) => sum + count);

    // 100 Correct Answers
    if (totalExercises >= 100 &&
        !_progress!.achievements.any((a) => a.id == 'hundred_answers')) {
      unlockAchievement(Achievement(
        id: 'hundred_answers',
        name: '100 Correct Answers',
        description: 'Completed 100 exercises',
        unlockedAt: DateTime.now(),
      ));
    }

    // 5-Day Streak
    if (currentStreak >= 5 &&
        !_progress!.achievements.any((a) => a.id == 'five_day_streak')) {
      unlockAchievement(Achievement(
        id: 'five_day_streak',
        name: '5-Day Streak',
        description: 'Studied for 5 consecutive days',
        unlockedAt: DateTime.now(),
      ));
    }

    // Vocabulary Master (500 exercises)
    if (totalExercises >= 500 &&
        !_progress!.achievements.any((a) => a.id == 'vocab_master')) {
      unlockAchievement(Achievement(
        id: 'vocab_master',
        name: 'Vocabulary Master',
        description: 'Completed 500 exercises',
        unlockedAt: DateTime.now(),
      ));
    }
  }
}
