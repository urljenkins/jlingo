import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingua_sprint/models/cefr_level.dart';
import 'package:lingua_sprint/models/course_manifest.dart';
import 'package:lingua_sprint/models/user_profile.dart';
import 'package:lingua_sprint/providers/course_provider.dart';
import 'package:lingua_sprint/providers/gamification_provider.dart';
import 'package:lingua_sprint/providers/onboarding_provider.dart';

/// Covers the promise the level picker makes: choosing a level opens material
/// rather than gating it, and never hides anything the learner could reach
/// before.

CourseManifest _manifestFor(String course) => CourseManifest.fromJson(
    jsonDecode(File('assets/courses/$course/manifest.json').readAsStringSync())
        as Map<String, dynamic>);

CourseManifest _manifest() => CourseManifest(
      id: 'test',
      name: 'Test',
      targetLanguage: 'es-ES',
      nativeLanguage: 'en-US',
      skills: [
        SkillHeader(id: 's1', name: 'One', level: 1),
        SkillHeader(id: 's2', name: 'Two', level: 5),
        SkillHeader(id: 's3', name: 'Three', level: 8),
        SkillHeader(id: 's4', name: 'Four', level: 17),
        SkillHeader(id: 's5', name: 'Five', level: 21),
      ],
    );

bool _unlocked(SkillHeader s, int pos, LanguageLevel? level,
        {bool prevDone = false}) =>
    isSkillUnlocked(
      skillLevel: s.level,
      position: pos,
      previousCompleted: prevDone,
      entryLevel: level,
    );

void main() {
  // OnboardingProvider reads SharedPreferences on construction.
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('entry level unlocking', () {
    test('a beginner starts with only the first skill open', () {
      final m = _manifest();
      expect(_unlocked(m.skills[0], 0, LanguageLevel.beginner), isTrue);
      expect(_unlocked(m.skills[1], 1, LanguageLevel.beginner), isFalse);
      expect(_unlocked(m.skills[3], 3, LanguageLevel.beginner), isFalse);
    });

    test('choosing B1 opens everything up to and including B1', () {
      final m = _manifest();
      for (var i = 0; i < 3; i++) {
        expect(_unlocked(m.skills[i], i, LanguageLevel.intermediate), isTrue,
            reason: 'skill ${m.skills[i].id} should be open at B1');
      }
      // Advanced material still has to be earned.
      expect(_unlocked(m.skills[3], 3, LanguageLevel.intermediate), isFalse);
    });

    test('earlier material stays open, so dropping back is never blocked', () {
      final m = _manifest();
      expect(_unlocked(m.skills[0], 0, LanguageLevel.advanced), isTrue);
      expect(_unlocked(m.skills[1], 1, LanguageLevel.advanced), isTrue);
    });

    test('completing the previous skill still unlocks the next one', () {
      final m = _manifest();
      expect(
        _unlocked(m.skills[3], 3, LanguageLevel.beginner, prevDone: true),
        isTrue,
      );
    });

    test('an unset level behaves exactly like a beginner', () {
      final m = _manifest();
      expect(_unlocked(m.skills[1], 1, null), isFalse);
      expect(_unlocked(m.skills[0], 0, null), isTrue);
    });
  });

  group('resume point', () {
    test('resumes at the entry level rather than the first skill', () {
      final provider = CourseProvider();
      final index = provider.getCurrentSkillIndex(
        const {},
        entryLevel: LanguageLevel.intermediate,
        manifest: _manifest(),
      );
      expect(_manifest().skills[index].id, 's3');
    });

    test('falls back to unfinished earlier work once the tier is done', () {
      final provider = CourseProvider();
      final index = provider.getCurrentSkillIndex(
        const {'s3', 's4', 's5'},
        entryLevel: LanguageLevel.intermediate,
        manifest: _manifest(),
      );
      expect(_manifest().skills[index].id, 's1');
    });

    test('a beginner resumes at the very first unfinished skill', () {
      final provider = CourseProvider();
      final index = provider.getCurrentSkillIndex(
        const {'s1'},
        entryLevel: LanguageLevel.beginner,
        manifest: _manifest(),
      );
      expect(_manifest().skills[index].id, 's2');
    });
  });

  group('retaking the level check', () {
    test('every shipped course loads questions for a retake', () {
      // The quiz keys off the course language code; a code with no questions
      // would silently score 0 and demote the learner.
      const courses = [
        'spanish',
        'spanish_latam',
        'french',
        'dutch',
        'portuguese',
        'japanese',
        'chinese',
      ];

      for (final course in courses) {
        final provider = OnboardingProvider();
        provider.restartQuiz(language: course);
        expect(provider.quizQuestions, isNotEmpty,
            reason: 'no quiz questions for course "$course"');
      }
    });

    test('restarting with no language known leaves the quiz empty', () {
      final provider = OnboardingProvider();
      provider.restartQuiz();
      expect(provider.quizQuestions, isEmpty);
    });
  });

  group('per-language levels', () {
    test('levels are independent across courses', () {
      final profile = UserProfile()
          .withLevelFor('spanish', LanguageLevel.intermediate)
          .withLevelFor('japanese', LanguageLevel.beginner);

      expect(profile.levelFor('spanish'), LanguageLevel.intermediate);
      expect(profile.levelFor('japanese'), LanguageLevel.beginner);
    });

    test('an untouched course has no level of its own', () {
      final profile =
          UserProfile().withLevelFor('spanish', LanguageLevel.advanced);

      expect(profile.levelFor('french'), isNull);
      expect(profile.levelFor(null), isNull);
    });

    test('setting one course does not disturb another', () {
      final profile = UserProfile()
          .withLevelFor('spanish', LanguageLevel.advanced)
          .withLevelFor('dutch', LanguageLevel.elementary)
          .withLevelFor('spanish', LanguageLevel.beginner);

      expect(profile.levelFor('spanish'), LanguageLevel.beginner);
      expect(profile.levelFor('dutch'), LanguageLevel.elementary);
    });

    test('survives a round trip through JSON', () {
      final profile = UserProfile()
          .withLevelFor('spanish', LanguageLevel.upperIntermediate)
          .withLevelFor('chinese', LanguageLevel.elementary);

      final restored = UserProfile.fromJson(profile.toJson());

      expect(restored.levelFor('spanish'), LanguageLevel.upperIntermediate);
      expect(restored.levelFor('chinese'), LanguageLevel.elementary);
    });
  });

  group('migrating legacy single-level profiles', () {
    test('an existing level is kept, under the course being studied', () {
      // Written by a build that stored one level for all courses.
      final legacy = <String, dynamic>{
        'onboardingComplete': true,
        'assessedLevel': 'intermediate',
        'goals': <String>[],
        'quizScore': 6,
        'quizTotal': 10,
        'legacyLevelLanguage': 'spanish',
      };

      final migrated = UserProfile.fromJson(legacy);

      expect(migrated.levelFor('spanish'), LanguageLevel.intermediate);
      expect(migrated.levelFor('japanese'), isNull);
      expect(migrated.onboardingComplete, isTrue);
      expect(migrated.quizScore, 6);
    });

    test('a legacy level with no known course is dropped, not misfiled', () {
      final legacy = <String, dynamic>{
        'onboardingComplete': true,
        'assessedLevel': 'advanced',
        'goals': <String>[],
      };

      final migrated = UserProfile.fromJson(legacy);

      expect(migrated.assessedLevels, isEmpty);
    });

    test('a profile already using the map is left alone', () {
      final current = <String, dynamic>{
        'onboardingComplete': true,
        'assessedLevels': {'french': 'elementary'},
        'assessedLevel': 'advanced',
        'goals': <String>[],
        'legacyLevelLanguage': 'spanish',
      };

      final migrated = UserProfile.fromJson(current);

      expect(migrated.levelFor('french'), LanguageLevel.elementary);
      expect(migrated.levelFor('spanish'), isNull);
    });

    test('a profile that never set a level migrates to empty', () {
      final migrated = UserProfile.fromJson(<String, dynamic>{
        'onboardingComplete': false,
        'goals': <String>[],
      });

      expect(migrated.assessedLevels, isEmpty);
    });
  });

  group('C-tier content', () {
    test('the mastery tier maps onto the level the C content ships at', () {
      // C2 mastery skills are authored at level 27; if the
      // mapping drifts from that, picking C2 opens nothing new.
      expect(CefrLevel.startLevelFor(LanguageLevel.proficient), 27);
    });

    test('every course with C content exposes it at the top tier', () {
      const allCourses = [
        'spanish',
        'spanish_latam',
        'french',
        'japanese',
        'chinese',
        'dutch',
        'portuguese'
      ];

      for (final course in allCourses) {
        final manifest = _manifestFor(course);
        final top = CefrLevel.startLevelFor(LanguageLevel.proficient);
        expect(
          manifest.skills.any((s) => s.level >= top),
          isTrue,
          reason: '$course should have a skill at or above level $top',
        );
      }
    });

    test('a manifest without top tier skills still resolves a resume point',
        () {
      // Manifest without level 27 degrades cleanly to last skill
      final manifest = _manifest();
      final index = CourseProvider().getCurrentSkillIndex(
        const {},
        entryLevel: LanguageLevel.proficient,
        manifest: manifest,
      );

      expect(index, inInclusiveRange(0, manifest.skills.length - 1));
    });
  });

  group('sparse courses never overshoot the chosen tier', () {
    test('a gap in the course pulls the entry point down, not up', () {
      // Japanese jumps from level 8 to 26: a B2 learner must not be dropped
      // into the C1/C2 capstone, which is a higher tier than they chose.
      final levels =
          _manifestFor('japanese').skills.map((s) => s.level).toList();
      final effective = CefrLevel.effectiveStartLevel(
          LanguageLevel.upperIntermediate, levels);

      expect(
          effective, lessThan(CefrLevel.startLevelFor(LanguageLevel.advanced)),
          reason: 'B2 must stay below the C1 entry level');
      expect(levels, contains(effective));
    });

    test('B2 on a sparse course resumes below the C content', () {
      final manifest = _manifestFor('japanese');
      final index = CourseProvider().getCurrentSkillIndex(
        const {},
        entryLevel: LanguageLevel.upperIntermediate,
        manifest: manifest,
      );

      expect(manifest.skills[index].level, lessThan(26),
          reason: 'a B2 learner should not land on C1/C2 material');
    });

    test('a dense course honours the requested start exactly', () {
      final levels =
          _manifestFor('spanish').skills.map((s) => s.level).toList();

      for (final level in CefrLevel.ordered) {
        expect(
          CefrLevel.effectiveStartLevel(level, levels),
          CefrLevel.startLevelFor(level),
          reason: 'spanish has content for every tier, so none should clamp',
        );
      }
    });

    test('clamping never opens more than the requested tier would', () {
      for (final course in ['japanese', 'french', 'portuguese']) {
        final levels = _manifestFor(course).skills.map((s) => s.level).toList();
        for (final level in CefrLevel.ordered) {
          expect(
            CefrLevel.effectiveStartLevel(level, levels),
            lessThanOrEqualTo(CefrLevel.startLevelFor(level)),
            reason: '$course must never clamp upward',
          );
        }
      }
    });

    test('an empty course falls back to the requested start', () {
      expect(
        CefrLevel.effectiveStartLevel(LanguageLevel.intermediate, const []),
        CefrLevel.startLevelFor(LanguageLevel.intermediate),
      );
    });
  });

  group('content availability labelling', () {
    test('reports C2 as available for all courses with C2 content', () {
      for (final course in [
        'spanish',
        'spanish_latam',
        'french',
        'japanese',
        'chinese',
        'dutch',
        'portuguese'
      ]) {
        final levels = _manifestFor(course).skills.map((s) => s.level).toList();
        expect(
            CefrLevel.hasContentFor(LanguageLevel.proficient, levels), isTrue,
            reason: '$course should have C2 available');
      }
    });

    test('reports C2 as unavailable for a course manifest that lacks it', () {
      // The synthetic manifest tops out at level 17, below both C tiers.
      final levels = _manifest().skills.map((s) => s.level).toList();
      expect(
          CefrLevel.hasContentFor(LanguageLevel.proficient, levels), isFalse);
      expect(CefrLevel.hasContentFor(LanguageLevel.advanced, levels), isFalse);
      // Lower tiers are unaffected.
      expect(
          CefrLevel.hasContentFor(LanguageLevel.intermediate, levels), isTrue);
    });

    test('an empty course reports nothing available', () {
      expect(
          CefrLevel.hasContentFor(LanguageLevel.beginner, const []), isFalse);
    });
  });

  group('level headings', () {
    test('every authored level gets a real name, not a bare number', () {
      // Levels run 1-27; the previous per-level switch named only 1-6 and
      // rendered the other 21 as "Level 17".
      for (var level = 1; level <= 27; level++) {
        final heading = CefrLevel.headingForSkillLevel(level);
        expect(heading, isNot(contains('Level $level')));
        expect(heading, isNotEmpty);
      }
    });

    test('headings follow the tier boundaries', () {
      expect(CefrLevel.headingForSkillLevel(1), contains('A1'));
      expect(CefrLevel.headingForSkillLevel(7), contains('A2'));
      expect(CefrLevel.headingForSkillLevel(8), contains('B1'));
      expect(CefrLevel.headingForSkillLevel(14), contains('B2'));
      expect(CefrLevel.headingForSkillLevel(26), contains('C1'));
      expect(CefrLevel.headingForSkillLevel(27), contains('C2'));
    });

    test('a level maps back to the tier that owns it', () {
      for (final tier in CefrLevel.ordered) {
        expect(
          CefrLevel.tierForSkillLevel(CefrLevel.startLevelFor(tier)),
          tier,
          reason: 'a tier start should resolve to that tier',
        );
      }
    });

    test('levels below the first tier still resolve', () {
      expect(CefrLevel.tierForSkillLevel(0), LanguageLevel.beginner);
    });

    test('every real course level produces a heading', () {
      for (final course in ['spanish', 'japanese', 'french']) {
        for (final skill in _manifestFor(course).skills) {
          expect(CefrLevel.headingForSkillLevel(skill.level), isNotEmpty);
        }
      }
    });
  });

  group('progression paths', () {
    test('one path per tier, in CEFR order, with no repeated names', () {
      final provider = GamificationProvider();
      final skills = _manifestFor('spanish').skills;

      provider.updateProgressionPaths(skills, const {}, const {});
      final paths = provider.progressionPaths;

      // Spanish spans every tier; 27 raw levels must collapse to 6 paths.
      expect(paths.length, CefrLevel.ordered.length);

      final names = paths.map((p) => p.name).toList();
      expect(names.toSet().length, names.length,
          reason: 'tier headings must not repeat');

      // Order follows the CEFR ladder.
      expect(
        names,
        CefrLevel.ordered
            .map((t) => '${CefrLevel.nameFor(t)} · ${CefrLevel.codeFor(t)}')
            .toList(),
      );
    });

    test('building paths does not throw on a sparse course', () {
      // The previous ordering parsed an int out of pathId; a non-numeric id
      // would have thrown on every call.
      final provider = GamificationProvider();
      expect(
        () => provider.updateProgressionPaths(
            _manifestFor('japanese').skills, const {}, const {}),
        returnsNormally,
      );
      expect(provider.progressionPaths, isNotEmpty);
    });
  });

  group('manifest section parsing', () {
    test('the section field is read rather than dropped', () {
      final spanish = _manifestFor('spanish');
      expect(
        spanish.skills.any((s) => s.section == 'mastery'),
        isTrue,
        reason: 'spanish declares a mastery section',
      );
    });

    test('a manifest without sections still parses', () {
      final japanese = _manifestFor('japanese');
      expect(japanese.skills, isNotEmpty);
      expect(japanese.skills.every((s) => s.section == null), isTrue);
    });
  });

  group('tier metadata', () {
    test('every tier has a code, name and description', () {
      for (final level in CefrLevel.ordered) {
        expect(CefrLevel.codeFor(level), isNotEmpty);
        expect(CefrLevel.nameFor(level), isNotEmpty);
        expect(CefrLevel.descriptionFor(level), isNotEmpty);
      }
    });

    test('start levels increase monotonically across tiers', () {
      final starts = CefrLevel.ordered.map(CefrLevel.startLevelFor).toList();
      for (var i = 1; i < starts.length; i++) {
        expect(starts[i], greaterThan(starts[i - 1]));
      }
    });
  });
}
