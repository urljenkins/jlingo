import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_sprint/models/exercise.dart';
import 'package:lingua_sprint/widgets/exercises/dialogue_listening_widget.dart';
import 'package:lingua_sprint/widgets/exercises/listening_widget.dart';
import 'package:lingua_sprint/widgets/exercises/native_audio_widget.dart';
import 'package:lingua_sprint/widgets/exercises/song_fill_widget.dart';
import 'package:lingua_sprint/widgets/exercises/word_bank_exercise_widget.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

Future<void> _phone(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

void main() {
  group(
      'Audio exercises autoplay and reduced playback speed (including quarter speed)',
      () {
    testWidgets('ListeningWidget has 1x, 0.5x, and 0.25x speed options',
        (tester) async {
      await _phone(tester);
      final exercise = Exercise(
        id: 'listen_1',
        type: ExerciseType.listeningComprehension,
        question: 'Hola mundo',
        options: const [],
        correctAnswer: 'Hola mundo',
        targetLanguage: 'es-ES',
      );

      await tester.pumpWidget(_host(ListeningWidget(
        exercise: exercise,
        onAnswer: (_) {},
      )));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('1x'), findsOneWidget);
      expect(find.text('0.5x'), findsOneWidget);
      expect(find.text('0.25x'), findsOneWidget);

      await tester.tap(find.text('0.25x'));
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets(
        'WordBankExerciseWidget (listening mode) has Play, Slow, and 0.25x options',
        (tester) async {
      await _phone(tester);
      final exercise = Exercise(
        id: 'wb_listen_1',
        type: ExerciseType.tapWhatYouHear,
        question: '',
        options: const ['mundo', 'amigo'],
        correctAnswer: 'Hola mundo',
        targetLanguage: 'es-ES',
      );

      await tester.pumpWidget(_host(WordBankExerciseWidget(
        exercise: exercise,
        onAnswer: (_) {},
        listening: true,
      )));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Play'), findsOneWidget);
      expect(find.text('Slow'), findsOneWidget);
      expect(find.text('0.25x'), findsOneWidget);

      await tester.tap(find.text('0.25x'));
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('NativeAudioWidget offers 0.25x speed option', (tester) async {
      await _phone(tester);
      final exercise = Exercise(
        id: 'native_1',
        type: ExerciseType.nativeAudio,
        question: 'Listen carefully',
        options: const ['Option 1', 'Option 2'],
        correctAnswer: 'Option 1',
        targetLanguage: 'es-ES',
      );

      await tester.pumpWidget(_host(NativeAudioWidget(
        exercise: exercise,
        onAnswer: (_) {},
      )));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('0.25x'), findsOneWidget);
      expect(find.text('0.5x'), findsOneWidget);
      expect(find.text('1x'), findsOneWidget);

      await tester.tap(find.text('0.25x'));
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('DialogueListeningWidget offers 0.25x speed option',
        (tester) async {
      await _phone(tester);
      final exercise = Exercise(
        id: 'dialogue_1',
        type: ExerciseType.dialogueListening,
        question: 'What was said?',
        options: const ['A', 'B'],
        correctAnswer: 'A',
        targetLanguage: 'es-ES',
        metadata: const {
          'dialogue': [
            {'speaker': 'Carlos', 'text': 'Buenos días'},
          ],
          'options': ['A', 'B'],
          'question': 'What was said?',
        },
      );

      await tester.pumpWidget(_host(DialogueListeningWidget(
        exercise: exercise,
        onAnswer: (_) {},
      )));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('0.25x'), findsOneWidget);
      expect(find.text('0.5x'), findsOneWidget);

      await tester.tap(find.text('0.25x'));
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('SongFillWidget offers 0.25x speed option', (tester) async {
      await _phone(tester);
      final exercise = Exercise(
        id: 'song_1',
        type: ExerciseType.songFill,
        question: 'La ___ es bella',
        options: const ['vida', 'casa'],
        correctAnswer: 'vida',
        targetLanguage: 'es-ES',
        metadata: const {
          'lyrics': ['La ___ es bella'],
          'blanks': ['vida'],
        },
      );

      await tester.pumpWidget(_host(SongFillWidget(
        exercise: exercise,
        onAnswer: (_) {},
      )));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('0.25x'), findsOneWidget);
      expect(find.text('0.5x'), findsOneWidget);

      await tester.tap(find.text('0.25x'));
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
