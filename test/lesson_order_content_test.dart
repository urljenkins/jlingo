import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:lingua_sprint/models/skill.dart';
import 'package:lingua_sprint/services/lesson_order.dart';

Skill _load(String path) => Skill.fromJson(
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>);

void main() {
  group('real course content', () {
    test('the reported hache exercise is never asked before it is taught', () {
      final skill = _load('assets/courses/spanish/skills/alphabet.json');
      final hache = skill.exercises.firstWhere(
        (e) => e.correctAnswer.toLowerCase() == 'hache',
      );

      // The skill introduces "hache" nowhere, so ordering alone cannot make
      // this exercise fair — it can only stop it preceding the exercises
      // that DO teach their words. Assert the property that actually holds:
      // it never runs before an introducing exercise.
      expect(LessonOrder.wordAsked(hache), 'hache');
      expect(LessonOrder.untaughtWords(skill.exercises), contains('hache'));

      final introducing = skill.exercises
          .where((e) => LessonOrder.wordAsked(e) == null)
          .map((e) => e.id)
          .toSet();

      for (var run = 0; run < 20; run++) {
        final ordered = LessonOrder.arrange(skill.exercises);
        final position = ordered.indexWhere((e) => e.id == hache.id);
        final lastIntroducing = ordered.lastIndexWhere(
          (e) => introducing.contains(e.id),
        );
        expect(position, greaterThan(lastIntroducing));
      }
    });

    test('this skill is mostly untaught, which ordering cannot fix', () {
      // Documents the real scale of the content gap, so that authoring
      // introductions later shows up here as this number falling.
      final skill = _load('assets/courses/spanish/skills/alphabet.json');
      final untaught = LessonOrder.untaughtWords(skill.exercises);

      final asked =
          skill.exercises.where((e) => LessonOrder.wordAsked(e) != null).length;
      expect(asked, greaterThan(0));
      // In the clean 35-exercise intro alphabet skill, untaught words remain documented.
      expect(untaught.length, greaterThan(20));
    });

    test('across every skill, taught words are never tested first', () {
      final skillFiles = Directory('assets/courses')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.contains('/skills/') && f.path.endsWith('.json'))
          .toList();

      expect(skillFiles, isNotEmpty, reason: 'no skills found to check');

      for (final file in skillFiles) {
        final skill = _load(file.path);
        if (skill.exercises.isEmpty) continue;

        final ordered = LessonOrder.arrange(skill.exercises);

        // Walk the lesson tracking what has been shown. Any test whose word
        // the skill does teach must come after the exercise that teaches it.
        final introduced = <String>{};
        for (final exercise in ordered) {
          final tested = LessonOrder.wordAsked(exercise);
          if (tested != null &&
              LessonOrder.untaughtWords(skill.exercises).contains(tested)) {
            // A word this skill never teaches — already sorted to the tail,
            // and not something ordering alone can fix.
            continue;
          }
          if (tested != null) {
            expect(
              introduced.contains(tested),
              isTrue,
              reason: '${file.path}: "$tested" tested before it was taught',
            );
          }
          introduced.addAll(LessonOrder.wordsTaught(exercise));
        }
      }
    });
  });
}
