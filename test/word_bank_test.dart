import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lingua_sprint/models/exercise.dart';
import 'package:lingua_sprint/widgets/exercises/word_bank_input.dart';
import 'package:lingua_sprint/widgets/exercises/word_bank_exercise_widget.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

Exercise _ex({
  String question = 'Yo soy de México.',
  String answer = 'I am from Mexico',
  List<String> options = const [],
}) =>
    Exercise(
      id: 'e1',
      type: ExerciseType.wordBankTranslate,
      question: question,
      options: options,
      correctAnswer: answer,
      targetLanguage: 'es-ES',
    );

void main() {
  group('tokenise', () {
    test('splits on whitespace and keeps punctuation attached', () {
      expect(
        WordBankInput.tokenise('Yo soy de México.'),
        ['Yo', 'soy', 'de', 'México.'],
      );
      // Collapsing runs of spaces stops empty tiles appearing.
      expect(WordBankInput.tokenise('a   b'), ['a', 'b']);
      expect(WordBankInput.tokenise('  '), isEmpty);
    });
  });

  group('WordBankInput', () {
    testWidgets('every word of the answer is offered as a tile',
        (tester) async {
      await tester.pumpWidget(_host(WordBankInput(
        correctAnswer: 'I am from Mexico',
        onChanged: (_) {},
      )));

      for (final word in ['I', 'am', 'from', 'Mexico']) {
        expect(find.text(word), findsOneWidget);
      }
    });

    testWidgets('tapping tiles builds the answer in tap order', (tester) async {
      var latest = '';
      await tester.pumpWidget(_host(WordBankInput(
        correctAnswer: 'I am from Mexico',
        onChanged: (value) => latest = value,
      )));

      for (final word in ['I', 'am', 'from', 'Mexico']) {
        await tester.tap(find.text(word));
        await tester.pump();
      }

      expect(latest, 'I am from Mexico');
    });

    testWidgets('tapping a placed tile returns it to the bank', (tester) async {
      var latest = '';
      await tester.pumpWidget(_host(WordBankInput(
        correctAnswer: 'I am',
        onChanged: (value) => latest = value,
      )));

      await tester.tap(find.text('I'));
      await tester.pump();
      await tester.tap(find.text('am'));
      await tester.pump();
      expect(latest, 'I am');

      // Tapping the placed tile takes it back out.
      await tester.tap(find.text('am'));
      await tester.pump();
      expect(latest, 'I');
    });

    testWidgets('a repeated word gives two independently placeable tiles',
        (tester) async {
      var latest = '';
      await tester.pumpWidget(_host(WordBankInput(
        correctAnswer: 'de la de',
        onChanged: (value) => latest = value,
      )));

      // Two "de" tiles exist; placing one must leave the other behind.
      expect(find.text('de'), findsNWidgets(2));
      await tester.tap(find.text('de').first);
      await tester.pump();
      expect(latest, 'de');
      expect(find.text('de'), findsNWidgets(2));
    });

    testWidgets('distractor tiles are offered alongside the answer',
        (tester) async {
      await tester.pumpWidget(_host(WordBankInput(
        correctAnswer: 'I am',
        distractors: const ['nice', 'you'],
        onChanged: (_) {},
      )));

      // Extra tiles mean the bank alone does not give the answer away.
      expect(find.text('nice'), findsOneWidget);
      expect(find.text('you'), findsOneWidget);
    });
  });

  group('WordBankExerciseWidget', () {
    testWidgets('Check is disabled until a tile is placed', (tester) async {
      await tester.pumpWidget(_host(WordBankExerciseWidget(
        exercise: _ex(),
        onAnswer: (_) {},
        listening: false,
      )));
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Check'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('a correctly assembled answer is marked correct',
        (tester) async {
      bool? result;
      await tester.pumpWidget(_host(WordBankExerciseWidget(
        exercise: _ex(),
        onAnswer: (correct) => result = correct,
        listening: false,
      )));
      await tester.pump();

      for (final word in ['I', 'am', 'from', 'Mexico']) {
        await tester.tap(find.text(word));
        await tester.pump();
      }
      await tester.tap(find.widgetWithText(ElevatedButton, 'Check'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      expect(result, isTrue);
    });

    testWidgets('a wrong order is marked incorrect and reveals the answer',
        (tester) async {
      bool? result;
      await tester.pumpWidget(_host(WordBankExerciseWidget(
        exercise: _ex(),
        onAnswer: (correct) => result = correct,
        listening: false,
      )));
      await tester.pump();

      for (final word in ['Mexico', 'from', 'am', 'I']) {
        await tester.tap(find.text(word));
        await tester.pump();
      }
      await tester.tap(find.widgetWithText(ElevatedButton, 'Check'));
      await tester.pump();

      expect(find.textContaining('I am from Mexico'), findsWidgets);

      await tester.pump(const Duration(milliseconds: 1000));
      expect(result, isFalse);
    });

    testWidgets('the listening variant hides the phrase and offers slow audio',
        (tester) async {
      await tester.pumpWidget(_host(WordBankExerciseWidget(
        exercise: _ex(question: 'hidden prompt', answer: 'Yo soy'),
        onAnswer: (_) {},
        listening: true,
      )));
      await tester.pump();

      expect(find.text('Tap what you hear'), findsOneWidget);
      // Normal and slow playback, as in the Duolingo screen.
      expect(find.text('Play'), findsOneWidget);
      expect(find.text('Slow'), findsOneWidget);
      // The written prompt must not leak the answer.
      expect(find.text('hidden prompt'), findsNothing);
    });
  });
}
