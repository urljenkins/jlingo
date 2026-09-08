import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:lingua_sprint/providers/course_provider.dart';
import 'package:lingua_sprint/screens/alphabet_screen.dart';
import 'package:lingua_sprint/theme/app_theme.dart';

Future<void> _pump(WidgetTester tester, {CourseProvider? course}) async {
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: course ?? CourseProvider()),
    ],
    child: MaterialApp(
      theme: AppTheme.build(),
      home: const AlphabetScreen(),
    ),
  ));
  await tester.pump();
}

void main() {
  group('AlphabetScreen', () {
    testWidgets('says so when no course is loaded, rather than blanking',
        (tester) async {
      await _pump(tester);

      expect(find.text('Alphabet & Sounds'), findsOneWidget);
      expect(
        find.text('No alphabet chart for this course yet.'),
        findsOneWidget,
      );
    });

    testWidgets('draws the real chart for a loaded course', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final course = CourseProvider();
      // Reading the manifest off the asset bundle needs the real async
      // elapse that runAsync provides; pump() alone would never complete it.
      await tester.runAsync(() => course.loadCourse('spanish_latam'));
      // Guards the rest of the test against silently passing on an empty
      // chart if the asset ever stops loading.
      expect(course.currentManifest, isNotNull);

      await _pump(tester, course: course);

      // The five vowels are the section a beginner needs first.
      expect(find.text('The five vowels'), findsOneWidget);
      for (final vowel in ['A', 'E', 'I', 'O', 'U']) {
        expect(find.text(vowel), findsWidgets, reason: vowel);
      }
      // Ñ is the letter the course's own exercises ask about.
      expect(find.text('Ñ'), findsOneWidget);
      // The phonetic spelling is on the tile, which is the point.
      expect(find.text('/a/'), findsWidgets);
    });

    testWidgets('tapping a letter opens its detail', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final course = CourseProvider();
      await tester.runAsync(() => course.loadCourse('spanish_latam'));
      await _pump(tester, course: course);

      await tester.tap(find.text('Ñ'));
      await tester.pump();

      // The detail panel explains the sound rather than only naming it.
      expect(find.text('Like "ny" in "canyon"'), findsOneWidget);
      expect(find.text('eñe'), findsOneWidget);
    });
  });
}
