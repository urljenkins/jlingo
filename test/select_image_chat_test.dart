import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lingua_sprint/models/exercise.dart';
import 'package:lingua_sprint/widgets/exercises/complete_the_chat_widget.dart';
import 'package:lingua_sprint/widgets/exercises/select_image_widget.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

/// The default 800x600 test viewport is shorter than a phone, which pushes
/// the lower grid row and the reply buttons off-screen. Size the surface to a
/// phone so taps land where they would in the app.
Future<void> _usePhoneViewport(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

void main() {
  group('SelectImageWidget', () {
    Exercise image({Map<String, dynamic>? metadata}) => Exercise(
          id: 'i1',
          type: ExerciseType.selectImage,
          question: 'helado',
          options: const ['taco', 'sandwich', 'ice cream', 'tea'],
          correctAnswer: 'ice cream',
          targetLanguage: 'es-ES',
          metadata: metadata,
        );

    testWidgets('every option is shown with its label', (tester) async {
      await _usePhoneViewport(tester);
      await tester.pumpWidget(_host(SelectImageWidget(
        exercise: image(),
        onAnswer: (_) {},
      )));
      await tester.pump();

      for (final option in ['taco', 'sandwich', 'ice cream', 'tea']) {
        expect(find.text(option), findsOneWidget);
      }
    });

    testWidgets('emoji artwork is rendered when supplied', (tester) async {
      await _usePhoneViewport(tester);
      await tester.pumpWidget(_host(SelectImageWidget(
        exercise: image(metadata: {
          'emoji': {
            'taco': '🌮',
            'sandwich': '🥪',
            'ice cream': '🍦',
            'tea': '🍵',
          },
        }),
        onAnswer: (_) {},
      )));
      await tester.pump();

      expect(find.text('🍦'), findsOneWidget);
      expect(find.text('🌮'), findsOneWidget);
    });

    testWidgets('falls back to a wireframe when there is no artwork',
        (tester) async {
      await _usePhoneViewport(tester);
      await tester.pumpWidget(_host(SelectImageWidget(
        exercise: image(),
        onAnswer: (_) {},
      )));
      await tester.pump();

      // No assets exist yet, so all four options draw the placeholder —
      // the exercise stays answerable rather than rendering blank boxes.
      expect(find.byType(DottedFrame), findsNWidgets(4));
    });

    testWidgets('picking the right picture reports correct', (tester) async {
      await _usePhoneViewport(tester);
      bool? result;
      await tester.pumpWidget(_host(SelectImageWidget(
        exercise: image(),
        onAnswer: (correct) => result = correct,
      )));
      await tester.pump();

      await tester.tap(find.text('ice cream'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      expect(result, isTrue);
    });

    testWidgets('picking wrong reports incorrect', (tester) async {
      await _usePhoneViewport(tester);
      bool? result;
      await tester.pumpWidget(_host(SelectImageWidget(
        exercise: image(),
        onAnswer: (correct) => result = correct,
      )));
      await tester.pump();

      await tester.tap(find.text('tea'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      expect(result, isFalse);
    });
  });

  group('CompleteTheChatWidget', () {
    Exercise chat({Map<String, dynamic>? metadata}) => Exercise(
          id: 'c1',
          type: ExerciseType.completeTheChat,
          question: 'Hola, yo soy Luis. Yo soy de México.',
          options: const ['¡Mucho gusto, Luis!', 'No, un café, por favor.'],
          correctAnswer: '¡Mucho gusto, Luis!',
          targetLanguage: 'es-ES',
          metadata: metadata,
        );

    testWidgets('the opening line and both replies are shown', (tester) async {
      await _usePhoneViewport(tester);
      await tester.pumpWidget(_host(CompleteTheChatWidget(
        exercise: chat(),
        onAnswer: (_) {},
      )));
      await tester.pump();

      expect(find.textContaining('yo soy Luis'), findsOneWidget);
      expect(find.text('¡Mucho gusto, Luis!'), findsOneWidget);
      expect(find.text('No, un café, por favor.'), findsOneWidget);
    });

    testWidgets('the learner turn shows a gap until answered', (tester) async {
      await _usePhoneViewport(tester);
      await tester.pumpWidget(_host(CompleteTheChatWidget(
        exercise: chat(),
        onAnswer: (_) {},
      )));
      await tester.pump();

      expect(find.text('_______'), findsOneWidget);

      await tester.tap(find.text('¡Mucho gusto, Luis!'));
      await tester.pump();

      // The chosen reply lands in the conversation, so the exchange reads
      // as a whole rather than the choice vanishing.
      expect(find.text('_______'), findsNothing);
      expect(find.text('¡Mucho gusto, Luis!'), findsNWidgets(2));

      // Let the advance delay elapse so no timer outlives the widget tree.
      await tester.pump(const Duration(milliseconds: 1000));
    });

    testWidgets('a multi-turn conversation renders every authored line',
        (tester) async {
      await _usePhoneViewport(tester);
      await tester.pumpWidget(_host(CompleteTheChatWidget(
        exercise: chat(metadata: {
          'lines': [
            {'text': '¿Cómo estás?', 'isLearner': false},
            {'text': 'Muy bien.', 'isLearner': true},
            {'text': '¿Y de dónde eres?', 'isLearner': false},
          ],
        }),
        onAnswer: (_) {},
      )));
      await tester.pump();

      expect(find.text('¿Cómo estás?'), findsOneWidget);
      expect(find.text('Muy bien.'), findsOneWidget);
      expect(find.text('¿Y de dónde eres?'), findsOneWidget);
    });

    testWidgets('choosing the fitting reply reports correct', (tester) async {
      await _usePhoneViewport(tester);
      bool? result;
      await tester.pumpWidget(_host(CompleteTheChatWidget(
        exercise: chat(),
        onAnswer: (correct) => result = correct,
      )));
      await tester.pump();

      await tester.tap(find.text('¡Mucho gusto, Luis!'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      expect(result, isTrue);
    });
  });
}
