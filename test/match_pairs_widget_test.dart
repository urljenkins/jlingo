import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lingua_sprint/models/exercise.dart';
import 'package:lingua_sprint/theme/app_colors.dart';
import 'package:lingua_sprint/widgets/exercises/match_pairs_widget.dart';
import 'package:lingua_sprint/widgets/hover_card.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

Future<void> _usePhoneViewport(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

Exercise _exercise({
  List<Map<String, String>> pairs = const [
    {'target': 'gato', 'native': 'cat'},
    {'target': 'perro', 'native': 'dog'},
    {'target': 'casa', 'native': 'house'},
  ],
}) =>
    Exercise(
      id: 'mp1',
      type: ExerciseType.matchPairs,
      question: 'Match the words to their meanings',
      options: const [],
      correctAnswer: '',
      metadata: {
        'pairs': pairs,
      },
    );

BoxDecoration _decorationOf(WidgetTester tester, String text) {
  final hoverCard = tester.widget<HoverCard>(
    find.ancestor(of: find.text(text), matching: find.byType(HoverCard)),
  );
  final decorated = hoverCard.child as DecoratedBox;
  return decorated.decoration as BoxDecoration;
}

void main() {
  group('MatchPairsWidget', () {
    testWidgets('renders instruction line and two distinct columns',
        (tester) async {
      await _usePhoneViewport(tester);
      await tester.pumpWidget(_host(MatchPairsWidget(
        exercise: _exercise(),
        onAnswer: (_) {},
      )));
      await tester.pump();

      expect(
        find.text(
            'Tap a tile on the left, then its match on the right. Correct pairs lock in place; a wrong pair flashes red and clears.'),
        findsOneWidget,
      );

      // Verify all target items are on the left of all native items
      final targetCard = find.ancestor(
        of: find.text('gato'),
        matching: find.byType(HoverCard),
      );
      final nativeCard = find.ancestor(
        of: find.text('cat'),
        matching: find.byType(HoverCard),
      );
      final targetX = tester.getRect(targetCard).left;
      final nativeX = tester.getRect(nativeCard).left;
      expect(targetX, lessThan(nativeX));

      for (final t in ['gato', 'perro', 'casa']) {
        final card = find.ancestor(
          of: find.text(t),
          matching: find.byType(HoverCard),
        );
        expect(tester.getRect(card).left, equals(targetX));
      }
      for (final n in ['cat', 'dog', 'house']) {
        final card = find.ancestor(
          of: find.text(n),
          matching: find.byType(HoverCard),
        );
        expect(tester.getRect(card).left, equals(nativeX));
      }
    });

    testWidgets('a correct pair locks in place with correct color',
        (tester) async {
      await _usePhoneViewport(tester);
      await tester.pumpWidget(_host(MatchPairsWidget(
        exercise: _exercise(),
        onAnswer: (_) {},
      )));
      await tester.pump();

      // Tap target, then matching native
      await tester.tap(find.text('gato'));
      await tester.pump();

      // Selected state
      final selectedDec = _decorationOf(tester, 'gato');
      expect(selectedDec.border?.top.color, equals(AppColors.textPrimary));

      await tester.tap(find.text('cat'));
      await tester.pump();

      // Correct matched state
      final matchedDec = _decorationOf(tester, 'gato');
      expect(matchedDec.border?.top.color, equals(AppColors.correct));

      final nativeDec = _decorationOf(tester, 'cat');
      expect(nativeDec.border?.top.color, equals(AppColors.correct));
    });

    testWidgets('a wrong pair flashes incorrect color then clears',
        (tester) async {
      await _usePhoneViewport(tester);
      await tester.pumpWidget(_host(MatchPairsWidget(
        exercise: _exercise(),
        onAnswer: (_) {},
      )));
      await tester.pump();

      // Tap target 'gato', then wrong native 'dog'
      await tester.tap(find.text('gato'));
      await tester.pump();
      await tester.tap(find.text('dog'));
      await tester.pump();

      // Should show incorrect color
      final wrongTargetDec = _decorationOf(tester, 'gato');
      expect(wrongTargetDec.border?.top.color, equals(AppColors.incorrect));

      final wrongNativeDec = _decorationOf(tester, 'dog');
      expect(wrongNativeDec.border?.top.color, equals(AppColors.incorrect));

      // After 500ms delay, both are cleared back to unselected
      await tester.pump(const Duration(milliseconds: 550));

      final clearedDec = _decorationOf(tester, 'gato');
      expect(clearedDec.border?.top.color, equals(Colors.transparent));
    });

    testWidgets('onAnswer(true) fires once every pair is matched',
        (tester) async {
      await _usePhoneViewport(tester);
      bool? answered;
      await tester.pumpWidget(_host(MatchPairsWidget(
        exercise: _exercise(),
        onAnswer: (correct) => answered = correct,
      )));
      await tester.pump();

      // Match first pair
      await tester.tap(find.text('gato'));
      await tester.pump();
      await tester.tap(find.text('cat'));
      await tester.pump();
      expect(answered, isNull);

      // Match second pair
      await tester.tap(find.text('perro'));
      await tester.pump();
      await tester.tap(find.text('dog'));
      await tester.pump();
      expect(answered, isNull);

      // Match third pair
      await tester.tap(find.text('casa'));
      await tester.pump();
      await tester.tap(find.text('house'));
      await tester.pump();

      // After 500ms delay, onAnswer(true) fires
      await tester.pump(const Duration(milliseconds: 550));
      expect(answered, isTrue);
    });
  });
}
