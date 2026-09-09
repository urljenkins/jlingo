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

Exercise _mc(String id) => Exercise(
      id: id,
      type: ExerciseType.multipleChoice,
      question: 'Question $id',
      options: ['right $id', 'wrong $id'],
      correctAnswer: 'right $id',
    );

Skill _skill(List<Exercise> exercises) => Skill(
      id: 'skill-1',
      name: 'Test skill',
      description: 'A skill',
      level: 1,
      exercises: exercises,
    );

Future<void> _pumpLesson(WidgetTester tester, Skill skill) async {
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
      home: LessonScreen(skill: skill),
    ),
  ));
  await tester.pump();
}

/// The question currently on screen, e.g. 'a' for 'Question a'.
String _currentQuestionId(WidgetTester tester) {
  final texts = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data)
      .whereType<String>()
      .where((t) => t.startsWith('Question '));
  return texts.first.substring('Question '.length);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Reveal shows and hides the current answer', (tester) async {
    await _pumpLesson(tester, _skill([_mc('a')]));

    final id = _currentQuestionId(tester);
    expect(find.text('right $id'), findsOneWidget); // the option itself

    await tester.tap(find.text('Reveal'));
    await tester.pumpAndSettle();
    // Banner label plus the option => the answer text now appears twice.
    expect(find.text('Answer'), findsOneWidget);
    expect(find.text('right $id'), findsNWidgets(2));

    await tester.tap(find.text('Hide'));
    await tester.pumpAndSettle();
    expect(find.text('Answer'), findsNothing);
    expect(find.text('right $id'), findsOneWidget);
  });

  testWidgets('skipping reveals the answer when you step back', (tester) async {
    await _pumpLesson(tester, _skill([_mc('a'), _mc('b')]));

    final first = _currentQuestionId(tester);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(_currentQuestionId(tester), isNot(first));
    expect(find.text('Answer'), findsNothing);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(_currentQuestionId(tester), first);
    expect(find.text('Answer'), findsOneWidget);
    expect(find.text('right $first'), findsNWidgets(2));
  });

  testWidgets('answering after revealing locks the exercise for review',
      (tester) async {
    await _pumpLesson(tester, _skill([_mc('a'), _mc('b')]));

    final first = _currentQuestionId(tester);
    await tester.tap(find.text('Reveal'));
    await tester.pumpAndSettle();
    expect(find.text('Answer'), findsOneWidget);

    // Tapping the option (the interactive one, not the banner echo).
    await tester.tap(find.text('right $first').last);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    // Advanced to the next exercise.
    expect(_currentQuestionId(tester), isNot(first));

    // Stepping back shows the review notice, not the reveal banner or button.
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(_currentQuestionId(tester), first);
    expect(find.textContaining("won't be scored"), findsOneWidget);
    expect(find.text('Answer'), findsNothing);
    expect(find.text('Reveal'), findsNothing);
  });
}
