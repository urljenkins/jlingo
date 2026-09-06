import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingua_sprint/models/progress.dart';
import 'package:lingua_sprint/providers/progress_provider.dart';
import 'package:lingua_sprint/providers/settings_provider.dart';

/// Completion is a bookmark, not a grade: one pass finishes a skill and opens
/// the next, and it is recorded whether or not scoring is switched on.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProgressProvider completion', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('marks a skill completed on a single pass', () async {
      final provider = ProgressProvider();
      await provider.loadProgress('spanish');

      provider.markSkillCompleted('basics_1');

      expect(provider.progress!.completedSkills, contains('basics_1'));
    });

    test('completing the same skill twice is a no-op', () async {
      final provider = ProgressProvider();
      await provider.loadProgress('spanish');

      provider.markSkillCompleted('basics_1');
      provider.markSkillCompleted('basics_1');

      expect(provider.progress!.completedSkills, hasLength(1));
    });

    test('completion survives a reload', () async {
      final provider = ProgressProvider();
      await provider.loadProgress('spanish');
      provider.markSkillCompleted('basics_1');
      await provider.saveProgress();

      final reloaded = ProgressProvider();
      await reloaded.loadProgress('spanish');

      expect(reloaded.progress!.completedSkills, contains('basics_1'));
    });

    test('back-fills completion from pre-existing full mastery', () async {
      final legacy = UserProgress(
        courseId: 'spanish',
        skillMastery: const {
          'alphabet': 100.0,
          'basics_1': 60.0,
          'greetings': 0.0,
        },
      );
      SharedPreferences.setMockInitialValues({
        'progress_spanish': jsonEncode(legacy.toJson()),
      });

      final provider = ProgressProvider();
      await provider.loadProgress('spanish');

      // Only the fully mastered skill counts as finished; a partly studied
      // one is picked up again where it was left.
      expect(provider.progress!.completedSkills, {'alphabet'});
    });
  });

  group('SettingsProvider tracking migration', () {
    test('carries an existing streak preference over to the new key', () async {
      SharedPreferences.setMockInitialValues({
        'settings_streak_monitoring_enabled': true,
      });

      final provider = SettingsProvider();
      await provider.loadSettings();

      expect(provider.progressTrackingEnabled, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('settings_progress_tracking_enabled'), isTrue);
      expect(prefs.getBool('settings_streak_monitoring_enabled'), isNull);
    });

    test('defaults to off for a new install', () async {
      SharedPreferences.setMockInitialValues({});

      final provider = SettingsProvider();
      await provider.loadSettings();

      expect(provider.progressTrackingEnabled, isFalse);
    });
  });
}
