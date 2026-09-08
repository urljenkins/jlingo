import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lingua_sprint/models/exercise.dart';
import 'package:lingua_sprint/models/skill.dart';
import 'package:lingua_sprint/providers/course_provider.dart';
import 'package:lingua_sprint/providers/flashcard_provider.dart';
import 'package:lingua_sprint/providers/gamification_provider.dart';
import 'package:lingua_sprint/providers/progress_provider.dart';
import 'package:lingua_sprint/providers/settings_provider.dart';
import 'package:lingua_sprint/providers/word_knowledge_provider.dart';
import 'package:lingua_sprint/screens/lesson_screen.dart';
import 'package:lingua_sprint/theme/app_theme.dart';

Exercise _exercise(String id, ExerciseType type) => Exercise(
      id: id,
      type: type,
      question: 'Question $id',
      options: const ['one', 'two'],
      correctAnswer: 'one',
    );

Skill _skill(List<Exercise> exercises) => Skill(
      id: 'skill-1',
      name: 'Test skill',
      description: 'A skill',
      level: 1,
      exercises: exercises,
    );

/// Mounts a real [LessonScreen] with the providers it reads.
Future<void> _pumpLesson(
  WidgetTester tester,
  Skill skill, {
  Set<ExerciseType> disabled = const {},
  ExerciseType? filterType,
}) async {
  SharedPreferences.setMockInitialValues({});
  final settings = SettingsProvider();
  await settings.loadSettings();

  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: settings),
      ChangeNotifierProvider(create: (_) => CourseProvider()),
      ChangeNotifierProvider(create: (_) => ProgressProvider()),
      ChangeNotifierProvider(create: (_) => GamificationProvider()),
      // The lesson tops itself up from the course vocabulary. These start
      // empty here, so a short skill stays short and these tests keep
      // asserting on the authored exercises alone.
      ChangeNotifierProvider(create: (_) => FlashcardProvider()),
      ChangeNotifierProvider(create: (_) => WordKnowledgeProvider()),
    ],
    child: MaterialApp(
      theme: AppTheme.build(),
      home: LessonScreen(
        skill: skill,
        filterType: filterType,
        disabledTypes: disabled,
      ),
    ),
  ));
  await tester.pump();
}

/// Walks the lesson to the end, collecting the question shown at each step.
///
/// The lesson shuffles its exercises, so which one comes first is not fixed —
/// the set it hands out is the stable thing to assert on.
Future<Set<String>> _questionsShown(WidgetTester tester) async {
  final seen = <String>{};

  // Bounded so a bug that never advances fails the test instead of hanging.
  for (var step = 0; step < 10; step++) {
    seen.addAll(tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .where((text) => text.startsWith('Question ')));

    // Past the last exercise the completion dialog covers the screen, and
    // there is nothing further to collect.
    if (find.byType(Dialog).evaluate().isNotEmpty) break;

    final option = find.text('one');
    if (option.evaluate().isEmpty) break;
    // The option can sit under the completion dialog on the last step.
    await tester.tap(option.first, warnIfMissed: false);
    // The choice is held on screen briefly before advancing, so the wait has
    // to clear that delay rather than just settling animations.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  return seen;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a lesson leaves out switched-off types', (tester) async {
    await _pumpLesson(
      tester,
      _skill([
        _exercise('a', ExerciseType.multipleChoice),
        _exercise('b', ExerciseType.speakThis),
        _exercise('c', ExerciseType.multipleChoice),
      ]),
      disabled: {ExerciseType.speakThis},
    );

    expect(await _questionsShown(tester), {'Question a', 'Question c'});
    expect(find.textContaining('you switched off'), findsNothing);
  });

  testWidgets('a lesson with nothing left runs anyway, and says so',
      (tester) async {
    await _pumpLesson(
      tester,
      _skill([
        _exercise('a', ExerciseType.multipleChoice),
        _exercise('b', ExerciseType.multipleChoice),
      ]),
      disabled: {ExerciseType.multipleChoice},
    );

    // Filtering would have emptied the skill and blocked the course, so the
    // exercises are kept and the reason is shown.
    expect(
      find.textContaining('only has exercise types you switched off'),
      findsOneWidget,
    );
    expect(await _questionsShown(tester), {'Question a', 'Question b'});
  });

  testWidgets('an explicit filter outranks the switched-off list',
      (tester) async {
    await _pumpLesson(
      tester,
      _skill([
        _exercise('a', ExerciseType.multipleChoice),
        _exercise('b', ExerciseType.multipleChoice),
        _exercise('c', ExerciseType.matchPairs),
      ]),
      disabled: {ExerciseType.multipleChoice},
      filterType: ExerciseType.multipleChoice,
    );

    // Picking a type on the Learn tab is a deliberate request for it, so the
    // disabled list does not veto it.
    expect(await _questionsShown(tester), {'Question a', 'Question b'});
  });

  testWidgets('no preferences means every exercise is offered', (tester) async {
    await _pumpLesson(
      tester,
      _skill([
        _exercise('a', ExerciseType.multipleChoice),
        _exercise('b', ExerciseType.multipleChoice),
        _exercise('c', ExerciseType.multipleChoice),
      ]),
    );

    expect(
      await _questionsShown(tester),
      {'Question a', 'Question b', 'Question c'},
    );
  });

  testWidgets('custom drillLength limits or extends exercises as requested',
      (tester) async {
    final exercises = List.generate(
      30,
      (i) => _exercise('item_$i', ExerciseType.multipleChoice),
    );

    // Pump with drillLength = 8
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsProvider();
    await settings.loadSettings();

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider(create: (_) => CourseProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => GamificationProvider()),
        ChangeNotifierProvider(create: (_) => FlashcardProvider()),
        ChangeNotifierProvider(create: (_) => WordKnowledgeProvider()),
      ],
      child: MaterialApp(
        theme: AppTheme.build(),
        home: LessonScreen(
          skill: _skill(exercises),
          drillLength: 8,
        ),
      ),
    ));
    await tester.pump();

    // Verify indicator shows "1 of 8"
    expect(find.text('1 of 8'), findsOneWidget);
  });
}
