import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_sprint/models/gamification.dart';

/// Covers the level and streak arithmetic that drives XP rewards and the
/// home-screen streak counter. GamificationProvider is the sole owner of both.

void main() {
  group('LevelConfig.getLevelFromXP', () {
    test('starts at level 1', () {
      expect(LevelConfig.getLevelFromXP(0), 1);
    });

    test('stays at level 1 just below the level 2 threshold', () {
      expect(LevelConfig.getLevelFromXP(99), 1);
    });

    test('advances exactly on a threshold', () {
      expect(LevelConfig.getLevelFromXP(100), 2);
      expect(LevelConfig.getLevelFromXP(250), 3);
      expect(LevelConfig.getLevelFromXP(500), 4);
    });

    test('advances between thresholds', () {
      expect(LevelConfig.getLevelFromXP(101), 2);
      expect(LevelConfig.getLevelFromXP(249), 2);
    });

    test('caps at the highest configured level', () {
      final maxLevel = LevelConfig.thresholds.length;
      expect(LevelConfig.getLevelFromXP(LevelConfig.thresholds.last), maxLevel);
      expect(LevelConfig.getLevelFromXP(999999), maxLevel);
    });

    test('never returns a level below 1', () {
      expect(LevelConfig.getLevelFromXP(-50), greaterThanOrEqualTo(1));
    });
  });

  group('UserLevel.fromXP', () {
    test('reports the matching title for the level', () {
      expect(UserLevel.fromXP(0).title, LevelConfig.getTitleForLevel(1));
      expect(UserLevel.fromXP(100).title, LevelConfig.getTitleForLevel(2));
    });

    test('keeps the raw XP it was built from', () {
      expect(UserLevel.fromXP(1234).currentXP, 1234);
    });

    test('progress stays within 0..1', () {
      for (final xp in [0, 50, 100, 249, 250, 12345, 999999]) {
        final progress = UserLevel.fromXP(xp).progress;
        expect(progress, inInclusiveRange(0.0, 1.0),
            reason: 'progress out of range at $xp XP');
      }
    });

    test('is flagged max level only at the top', () {
      expect(UserLevel.fromXP(0).isMaxLevel, isFalse);
      expect(UserLevel.fromXP(999999).isMaxLevel, isTrue);
    });

    test('level is monotonic as XP grows', () {
      var previous = 0;
      for (var xp = 0; xp <= 70000; xp += 250) {
        final level = UserLevel.fromXP(xp).level;
        expect(level, greaterThanOrEqualTo(previous),
            reason: 'level went backwards at $xp XP');
        previous = level;
      }
    });
  });

  group('StreakConfig.getStreakMultiplier', () {
    test('is neutral with no streak', () {
      expect(StreakConfig.getStreakMultiplier(0), 1.0);
      expect(StreakConfig.getStreakMultiplier(-3), 1.0);
    });

    test('grows with the streak', () {
      expect(StreakConfig.getStreakMultiplier(10),
          greaterThan(StreakConfig.getStreakMultiplier(5)));
    });

    test('reaches the cap at daysToMaxMultiplier and does not exceed it', () {
      expect(StreakConfig.getStreakMultiplier(StreakConfig.daysToMaxMultiplier),
          StreakConfig.maxStreakMultiplier);
      expect(StreakConfig.getStreakMultiplier(9999),
          StreakConfig.maxStreakMultiplier);
    });
  });

  group('StreakConfig.getStreakBonus', () {
    test('is zero with no streak', () {
      expect(StreakConfig.getStreakBonus(0), 0);
    });

    test('is clamped to 50', () {
      expect(StreakConfig.getStreakBonus(9999), 50);
    });

    test('never goes negative', () {
      expect(StreakConfig.getStreakBonus(-10), greaterThanOrEqualTo(0));
    });
  });

  group('StreakInfo.atRisk', () {
    StreakInfo streak({DateTime? lastStudy, bool activeToday = false}) =>
        StreakInfo(
          currentStreak: 3,
          longestStreak: 5,
          isActiveToday: activeToday,
          lastStudyDate: lastStudy,
        );

    test('is false when the user has never studied', () {
      expect(streak().atRisk, isFalse);
    });

    test('is true the day after studying, while today is unstudied', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(streak(lastStudy: yesterday).atRisk, isTrue);
    });

    test('is false once today has been studied', () {
      expect(
          streak(lastStudy: DateTime.now(), activeToday: true).atRisk, isFalse);
    });

    test('is false when the streak is already long broken', () {
      final lastWeek = DateTime.now().subtract(const Duration(days: 7));
      expect(streak(lastStudy: lastWeek).atRisk, isFalse);
    });
  });

  group('StreakInfo multiplier and bonus', () {
    test('derive from the current streak', () {
      final info = StreakInfo(
        currentStreak: 10,
        longestStreak: 10,
        isActiveToday: true,
      );
      expect(info.multiplier, StreakConfig.getStreakMultiplier(10));
      expect(info.bonusXP, StreakConfig.getStreakBonus(10));
    });
  });
}
