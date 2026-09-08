import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lingua_sprint/models/exercise.dart';
import 'package:lingua_sprint/models/exercise_type_info.dart';
import 'package:lingua_sprint/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExerciseTypeInfo catalogue', () {
    test('describes every exercise type exactly once', () {
      expect(ExerciseTypeInfo.all.length, ExerciseType.values.length);

      final covered = ExerciseTypeInfo.all.map((i) => i.type).toSet();
      expect(covered, ExerciseType.values.toSet());
    });

    test('every entry carries a label, summary and explanation', () {
      for (final info in ExerciseTypeInfo.all) {
        expect(info.label, isNotEmpty, reason: '${info.type} label');
        expect(info.summary, isNotEmpty, reason: '${info.type} summary');
        // The explanation is the point of the screen — a stub would ship
        // silently otherwise.
        expect(info.howItWorks.length, greaterThan(80),
            reason: '${info.type} howItWorks');
      }
    });

    test('categories between them cover the whole catalogue', () {
      final grouped = ExerciseCategory.values
          .expand(ExerciseTypeInfo.inCategory)
          .map((i) => i.type)
          .toSet();
      expect(grouped, ExerciseType.values.toSet());
    });
  });

  group('SettingsProvider exercise types', () {
    late SettingsProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      provider = SettingsProvider();
      await provider.loadSettings();
    });

    test('every type is enabled by default', () {
      expect(provider.disabledTypes, isEmpty);
      expect(provider.enabledTypesFor(null).length, ExerciseType.values.length);
      expect(provider.isTypeEnabled(ExerciseType.speakThis), isTrue);
    });

    test('disabling globally persists across a reload', () async {
      expect(
          await provider.setTypeEnabled(ExerciseType.speakThis, false), isTrue);
      expect(provider.isTypeEnabled(ExerciseType.speakThis), isFalse);

      final fresh = SettingsProvider();
      await fresh.loadSettings();
      expect(fresh.isTypeEnabled(ExerciseType.speakThis), isFalse);
      expect(fresh.isTypeEnabled(ExerciseType.matchPairs), isTrue);
    });

    test('refuses to disable the last remaining type', () async {
      const all = ExerciseType.values;
      for (final type in all.take(all.length - 1)) {
        expect(await provider.setTypeEnabled(type, false), isTrue);
      }

      expect(await provider.setTypeEnabled(all.last, false), isFalse);
      expect(provider.isTypeEnabled(all.last), isTrue);
      expect(provider.enabledTypesFor(null), [all.last]);
    });

    test('a course without an override follows the global set', () async {
      await provider.setTypeEnabled(ExerciseType.songFill, false);

      expect(provider.hasLanguageOverride('spanish'), isFalse);
      expect(provider.isTypeEnabled(ExerciseType.songFill, language: 'spanish'),
          isFalse);
    });

    test('an override seeds from global, then diverges', () async {
      await provider.setTypeEnabled(ExerciseType.songFill, false);
      await provider.setTypeEnabledForLanguage(
          'spanish', ExerciseType.speakThis, false);

      // Seeded: the global choice carried over rather than being reset.
      expect(provider.isTypeEnabled(ExerciseType.songFill, language: 'spanish'),
          isFalse);
      expect(
          provider.isTypeEnabled(ExerciseType.speakThis, language: 'spanish'),
          isFalse);

      // Diverged: the global set is untouched, as is any other course.
      expect(provider.isTypeEnabled(ExerciseType.speakThis), isTrue);
      expect(provider.isTypeEnabled(ExerciseType.speakThis, language: 'french'),
          isTrue);
    });

    test('per-language overrides survive a reload', () async {
      await provider.setTypeEnabledForLanguage(
          'japanese', ExerciseType.storyLesson, false);

      final fresh = SettingsProvider();
      await fresh.loadSettings();
      expect(fresh.hasLanguageOverride('japanese'), isTrue);
      expect(
          fresh.isTypeEnabled(ExerciseType.storyLesson, language: 'japanese'),
          isFalse);
    });

    test('clearing an override returns the course to the global set', () async {
      await provider.setTypeEnabledForLanguage(
          'french', ExerciseType.clozeTest, false);
      await provider.clearLanguageOverride('french');

      expect(provider.hasLanguageOverride('french'), isFalse);
      expect(provider.isTypeEnabled(ExerciseType.clozeTest, language: 'french'),
          isTrue);
    });

    test('a whole category can be switched off at once', () async {
      final speaking = ExerciseTypeInfo.inCategory(ExerciseCategory.speaking)
          .map((i) => i.type)
          .toList();

      expect(await provider.setTypesEnabled(speaking, false), isTrue);
      for (final type in speaking) {
        expect(provider.isTypeEnabled(type), isFalse);
      }
    });

    test('bulk disable stops short of emptying the set', () async {
      final complete =
          await provider.setTypesEnabled(ExerciseType.values, false);

      expect(complete, isFalse);
      expect(provider.enabledTypesFor(null), hasLength(1));
    });

    test('reset turns everything back on everywhere', () async {
      await provider.setTypeEnabled(ExerciseType.songFill, false);
      await provider.setTypeEnabledForLanguage(
          'dutch', ExerciseType.speakThis, false);

      await provider.resetExerciseTypes();

      expect(provider.disabledTypes, isEmpty);
      expect(provider.disabledTypesByLanguage, isEmpty);
      expect(provider.hasLanguageOverride('dutch'), isFalse);
    });

    test('unknown stored type names are ignored, not fatal', () async {
      SharedPreferences.setMockInitialValues({
        'settings_disabled_exercise_types': '["speakThis","typeFromTheFuture"]',
        'settings_disabled_exercise_types_by_language':
            '{"spanish":["gonePhase","songFill"]}',
      });

      final fresh = SettingsProvider();
      await fresh.loadSettings();

      expect(fresh.disabledTypes, {ExerciseType.speakThis});
      expect(fresh.disabledTypesFor('spanish'), {ExerciseType.songFill});
    });

    test('the tutorial is unseen until it is marked seen', () async {
      expect(provider.exerciseTourSeen, isFalse);
      await provider.setExerciseTourSeen(true);

      final fresh = SettingsProvider();
      await fresh.loadSettings();
      expect(fresh.exerciseTourSeen, isTrue);
    });
  });
}
