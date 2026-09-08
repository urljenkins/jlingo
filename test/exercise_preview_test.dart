import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lingua_sprint/models/exercise.dart';
import 'package:lingua_sprint/models/exercise_samples.dart';
import 'package:lingua_sprint/widgets/exercise_preview.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

Future<void> _phone(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

void main() {
  group('samples', () {
    test('every exercise type has a playable sample', () {
      // A type with no sample would render an empty or broken preview in the
      // catalogue, which is worse than no preview at all.
      for (final type in ExerciseType.values) {
        final sample = ExerciseSamples.of(type);
        expect(sample.type, type, reason: '$type sample has the wrong type');
        // Listening types deliberately leave `question` empty — the phrase
        // is hidden and carried in the answer — so accept any of the three.
        final hasContent = sample.question.isNotEmpty ||
            sample.correctAnswer.isNotEmpty ||
            sample.metadata != null;
        expect(hasContent, isTrue, reason: '$type sample has nothing to show');
      }
    });

    test('samples share a reserved id so they cannot be mistaken for real work',
        () {
      for (final type in ExerciseType.values) {
        expect(ExerciseSamples.of(type).id, ExerciseSamples.sampleId);
      }
    });
  });

  group('ExercisePreview', () {
    testWidgets('renders a real, answerable exercise', (tester) async {
      await _phone(tester);
      await tester.pumpWidget(_host(
        const ExercisePreview(type: ExerciseType.multipleChoice),
      ));
      await tester.pump();

      expect(find.text('TRY IT'), findsOneWidget);
      // The actual sample content, not a description of it.
      expect(find.text('cat'), findsOneWidget);
      expect(find.text('dog'), findsOneWidget);
    });

    testWidgets('answering shows the outcome and stays put', (tester) async {
      await _phone(tester);
      await tester.pumpWidget(_host(
        const ExercisePreview(type: ExerciseType.multipleChoice),
      ));
      await tester.pump();

      await tester.tap(find.text('cat'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));

      // A preview reports and stops; it must not advance like a lesson.
      expect(find.byIcon(Icons.check_circle), findsWidgets);
      expect(find.text('TRY IT'), findsOneWidget);
    });

    testWidgets('try again resets the exercise', (tester) async {
      await _phone(tester);
      await tester.pumpWidget(_host(
        const ExercisePreview(type: ExerciseType.multipleChoice),
      ));
      await tester.pump();

      await tester.tap(find.text('cat'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));

      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));

      expect(find.text('cat'), findsOneWidget);
    });

    testWidgets('"Not for me" reports the decision', (tester) async {
      await _phone(tester);
      var disabled = false;
      await tester.pumpWidget(_host(ExercisePreview(
        type: ExerciseType.multipleChoice,
        onDisable: () => disabled = true,
      )));
      await tester.pump();

      await tester.tap(find.text('Not for me'));
      await tester.pump();

      expect(disabled, isTrue);
    });

    testWidgets('the disable action is hidden when it cannot be used',
        (tester) async {
      await _phone(tester);
      await tester.pumpWidget(_host(
        const ExercisePreview(type: ExerciseType.multipleChoice),
      ));
      await tester.pump();

      expect(find.text('Not for me'), findsNothing);
    });

    testWidgets('every type builds a preview without throwing', (tester) async {
      await _phone(tester);
      for (final type in ExerciseType.values) {
        await tester.pumpWidget(_host(ExercisePreview(type: type)));
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('TRY IT'), findsOneWidget, reason: '$type failed');
        // Drain any timers the sample exercise started.
        await tester.pump(const Duration(seconds: 2));
      }
    });
  });
}
