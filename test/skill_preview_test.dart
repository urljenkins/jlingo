import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lingua_sprint/models/exercise.dart';
import 'package:lingua_sprint/models/skill.dart';
import 'package:lingua_sprint/theme/app_theme.dart';
import 'package:lingua_sprint/widgets/skill_preview_sheet.dart';

Skill _skill() => Skill(
      id: 'basics_1',
      name: 'Basics 1',
      description: 'Learn basic greetings',
      level: 1,
      exercises: [
        Exercise(
          id: 'ex_1',
          type: ExerciseType.translateThis,
          question: 'hola',
          options: const [],
          correctAnswer: 'hello',
        ),
        Exercise(
          id: 'ex_2',
          type: ExerciseType.pronunciationPractice,
          question: 'adios',
          options: const [],
          correctAnswer: 'goodbye',
        ),
      ],
    );

/// Mounts a button that opens the sheet, recording what it resolved to.
Future<List<bool?>> _openSheet(WidgetTester tester) async {
  final results = <bool?>[];

  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.build(),
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            results.add(await SkillPreviewSheet.show(context, _skill()));
          },
          child: const Text('open'),
        ),
      ),
    ),
  ));

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return results;
}

void main() {
  group('SkillPreviewSheet', () {
    testWidgets('shows what the topic covers', (tester) async {
      await _openSheet(tester);

      expect(find.text('Basics 1'), findsOneWidget);
      expect(find.text('Learn basic greetings'), findsOneWidget);
      // The vocabulary the skill teaches, both sides.
      expect(find.text('hola'), findsOneWidget);
      expect(find.text('hello'), findsOneWidget);
      // Practical facts a learner wants before committing.
      expect(find.text('2 exercises'), findsOneWidget);
      expect(find.text('Microphone'), findsOneWidget);
    });

    testWidgets('dismissing reports that the lesson was not started',
        (tester) async {
      final results = await _openSheet(tester);

      // Tapping the barrier outside the sheet dismisses it.
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // False, not null: the caller must not start a lesson on a dismissal.
      expect(results, [false]);
    });

    testWidgets('Start lesson reports that the learner chose to begin',
        (tester) async {
      final results = await _openSheet(tester);

      await tester.tap(find.text('Start lesson'));
      await tester.pumpAndSettle();

      expect(results, [true]);
    });
  });
}
