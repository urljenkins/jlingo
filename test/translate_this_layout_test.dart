import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_sprint/models/exercise.dart';
import 'package:lingua_sprint/widgets/exercises/translate_this_widget.dart';

Exercise _exercise({String question = 'Hola', String answer = 'Hello'}) =>
    Exercise(
      id: 'ex_translate_1',
      type: ExerciseType.translateThis,
      question: question,
      options: const [],
      correctAnswer: answer,
    );

Widget _buildWidget({
  required Exercise exercise,
  void Function(bool)? onAnswer,
}) {
  return MaterialApp(
    home: Scaffold(
      body: TranslateThisWidget(
        exercise: exercise,
        onAnswer: onAnswer ?? (_) {},
      ),
    ),
  );
}

void main() {
  group('TranslateThisWidget layout', () {
    testWidgets('renders prompt, field, and button without redundant label',
        (tester) async {
      await tester.pumpWidget(_buildWidget(exercise: _exercise()));

      // Top instruction is present
      expect(find.text('Translate to English'), findsOneWidget);
      // Prompt text is present
      expect(find.text('Hola'), findsOneWidget);
      // TextField is present
      expect(find.byType(TextField), findsOneWidget);
      // Check button is present
      expect(find.text('Check'), findsOneWidget);

      // Redundant middle label must be absent
      expect(find.text('Type the English translation:'), findsNothing);
    });

    testWidgets(
        'does not overflow in a height-constrained viewport (tall keyboard)',
        (tester) async {
      // Set a small viewport height simulating a screen shrunk by a tall keyboard
      tester.view.physicalSize = const Size(400, 320);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildWidget(exercise: _exercise()));

      // No overflow errors should be thrown
      expect(tester.takeException(), isNull);

      // SingleChildScrollView is present for graceful scrolling
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      // Check button remains rendered on screen
      expect(find.text('Check'), findsOneWidget);
    });

    testWidgets(
        'shows correct and incorrect feedback without overflow under constraint',
        (tester) async {
      tester.view.physicalSize = const Size(400, 320);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildWidget(exercise: _exercise()));

      // Type wrong answer
      await tester.enterText(find.byType(TextField), 'Goodbye');
      await tester.tap(find.text('Check'));
      await tester.pump();

      // Feedback shows without throwing layout exceptions
      expect(tester.takeException(), isNull);
      expect(find.text('Incorrect'), findsOneWidget);
      expect(find.text('Correct answer: Hello'), findsOneWidget);

      // Settle the timer for onAnswer
      await tester.pump(const Duration(milliseconds: 850));
    });
  });
}
