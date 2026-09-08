import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_sprint/models/exercise.dart';
import 'package:lingua_sprint/widgets/exercises/multiple_choice_widget.dart';

Exercise _exercise(List<String> options) => Exercise(
      id: 'e1',
      type: ExerciseType.multipleChoice,
      question: "How do you pronounce double 'L' (LL)?",
      options: options,
      correctAnswer: options.first,
    );

Future<void> _pump(WidgetTester tester, Exercise exercise) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MultipleChoiceWidget(
          exercise: exercise,
          onAnswer: (_) {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('four short options are laid out as a 2x2 grid', (tester) async {
    await _pump(
        tester, _exercise(['Y sound', 'L sound', 'R sound', 'S sound']));

    expect(find.byType(GridView), findsOneWidget);

    // Two per row, two rows: the first two share a top edge, and the third
    // sits below them.
    final first = tester.getRect(find.text('Y sound'));
    final second = tester.getRect(find.text('L sound'));
    final third = tester.getRect(find.text('R sound'));

    expect(first.top, equals(second.top));
    expect(second.left, greaterThan(first.left));
    expect(third.top, greaterThan(first.bottom));
  });

  testWidgets('a long option falls back to the full-width list',
      (tester) async {
    await _pump(
      tester,
      _exercise([
        'It is pronounced like the Y in yellow, in most dialects',
        'L sound',
        'R sound',
        'S sound',
      ]),
    );

    expect(find.byType(GridView), findsNothing);

    // Stacked vertically, each starting at the same left edge.
    final first = tester.getRect(find.text('L sound'));
    final second = tester.getRect(find.text('R sound'));
    expect(second.top, greaterThan(first.bottom));
    expect(second.left, equals(first.left));
  });

  testWidgets('three options keep the list layout', (tester) async {
    await _pump(tester, _exercise(['Uno', 'Dos', 'Tres']));

    expect(find.byType(GridView), findsNothing);
  });

  testWidgets('an unanswered option is outlined so it stays visible',
      (tester) async {
    await _pump(
        tester, _exercise(['Y sound', 'L sound', 'R sound', 'S sound']));

    final container = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('Y sound'),
            matching: find.byType(Container),
          )
          .first,
    );
    final border = (container.decoration! as BoxDecoration).border!;

    expect(border.top.color, isNot(Colors.transparent));
    expect(border.top.color.a, greaterThan(0));
  });
}
