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
      _progress = UserProgress.fromJson(jsonDecode(progressJson));
    } else {
      _progress = UserProgress(courseId: courseId);
    }
    notifyListeners();
  }

  Future<void> saveProgress() async {
    if (_progress == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'progress_${_progress!.courseId}',
      jsonEncode(_progress!.toJson()),
    );
  }

  void updateStreak() {
    if (_progress == null) return;

    final now = DateTime.now();
    final lastStudy = _progress!.lastStudyDate;

    int newStreak = _progress!.currentStreak;

    if (lastStudy == null) {
      newStreak = 1;
    } else {
      final daysSinceLastStudy = now.difference(lastStudy).inDays;
      if (daysSinceLastStudy == 0) {
        // Same day, no change
      } else if (daysSinceLastStudy == 1) {
        // Consecutive day
        newStreak++;
      } else {
        // Streak broken
        newStreak = 1;
      }
    }

    _progress = _progress!.copyWith(
      currentStreak: newStreak,
      lastStudyDate: now,
    );

    saveProgress();
    notifyListeners();
  }

  void addPoints(int points) {
    if (_progress == null) return;

    _progress = _progress!.copyWith(
      totalPoints: _progress!.totalPoints + points,
    );

    saveProgress();
    notifyListeners();
  }

  void updateSkillMastery(String skillId, double percentage) {
    if (_progress == null) return;

    final newMastery = Map<String, double>.from(_progress!.skillMastery);
    newMastery[skillId] = percentage;

    _progress = _progress!.copyWith(skillMastery: newMastery);

    saveProgress();
    notifyListeners();
  }

  void incrementExerciseStat(String exerciseType) {
    if (_progress == null) return;

    final newStats = Map<String, int>.from(_progress!.exerciseStats);
    newStats[exerciseType] = (newStats[exerciseType] ?? 0) + 1;

    _progress = _progress!.copyWith(exerciseStats: newStats);

    saveProgress();
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

    saveProgress();
    notifyListeners();
  }

  void checkAndUnlockAchievements() {
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
    if (_progress!.currentStreak >= 5 &&
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
