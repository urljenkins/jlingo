import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lingua_sprint/models/exercise.dart';
import 'package:lingua_sprint/models/exercise_type_info.dart';
import 'package:lingua_sprint/providers/course_provider.dart';
import 'package:lingua_sprint/providers/settings_provider.dart';
import 'package:lingua_sprint/screens/exercise_types_screen.dart';
import 'package:lingua_sprint/theme/app_theme.dart';

/// Wraps the screen in the providers it reads, with the tutorial already
/// dismissed unless [tourSeen] says otherwise.
Future<SettingsProvider> _pumpScreen(
  WidgetTester tester, {
  bool tourSeen = true,
}) async {
  SharedPreferences.setMockInitialValues(
    tourSeen ? {'settings_exercise_tour_seen': true} : {},
  );
  final settings = SettingsProvider();
  await settings.loadSettings();

  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: settings),
      ChangeNotifierProvider(create: (_) => CourseProvider()),
    ],
    child: MaterialApp(
      theme: AppTheme.build(),
      home: const ExerciseTypesScreen(),
    ),
  ));
  await tester.pumpAndSettle();
  return settings;
}

void main() {
  testWidgets('lists types by category, leading with recall', (tester) async {
    await _pumpScreen(tester);

    expect(find.text('Exercise types'), findsOneWidget);
    expect(find.text('These apply to every course.'), findsOneWidget);
    expect(find.text('VOCABULARY & RECALL'), findsOneWidget);
    expect(find.text('Match'), findsOneWidget);
    expect(find.text('Pair each word with its translation.'), findsOneWidget);
  });

  testWidgets('the explanation opens on demand', (tester) async {
    await _pumpScreen(tester);

    expect(find.text('Hide details'), findsNothing);
    await tester.tap(find.text('How it works').first);
    await tester.pumpAndSettle();

    expect(find.text('Hide details'), findsOneWidget);
    expect(
      find.textContaining('type what it means in the other language'),
      findsOneWidget,
    );
  });

  testWidgets('a switch disables the type it sits on', (tester) async {
    final settings = await _pumpScreen(tester);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(settings.disabledTypes, {ExerciseType.translateThis});
    // Derived from the catalogue rather than hardcoded, so adding an
    // exercise type does not break this test.
    final total = ExerciseType.values.length;
    expect(
      find.textContaining('${total - 1} of $total are on'),
      findsOneWidget,
    );
  });

  testWidgets('a category header clears the whole family', (tester) async {
    final settings = await _pumpScreen(tester);

    await tester.tap(find.text('Turn all off').first);
    await tester.pumpAndSettle();

    // The whole recall family went off together, and nothing else did.
    final recallCount =
        ExerciseTypeInfo.inCategory(ExerciseCategory.recall).length;
    expect(settings.disabledTypes, hasLength(recallCount));
    expect(settings.isTypeEnabled(ExerciseType.storyLesson), isTrue);
    expect(find.text('Turn all on'), findsOneWidget);
  });

  testWidgets('the tutorial appears on the first visit only', (tester) async {
    final settings = await _pumpScreen(tester, tourSeen: false);

    expect(find.text('A lesson is a stack of exercises'), findsOneWidget);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Globally, or one course at a time'), findsOneWidget);

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    expect(find.text('A lesson is a stack of exercises'), findsNothing);
    expect(settings.exerciseTourSeen, isTrue);
  });

  testWidgets('the tutorial can be reopened from the help icon',
      (tester) async {
    await _pumpScreen(tester);

    expect(find.text('A lesson is a stack of exercises'), findsNothing);
    await tester.tap(find.byIcon(Icons.help_outline));
    await tester.pumpAndSettle();

    expect(find.text('A lesson is a stack of exercises'), findsOneWidget);
  });

  testWidgets('the per-course tab explains itself without a course loaded',
      (tester) async {
    await _pumpScreen(tester);

    await tester.tap(find.text('This course'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Pick a course first'), findsOneWidget);
  });
}
