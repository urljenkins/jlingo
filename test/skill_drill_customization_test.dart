import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lingua_sprint/providers/settings_provider.dart';
import 'package:lingua_sprint/theme/app_theme.dart';
import 'package:lingua_sprint/widgets/skill_exercise_types_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Skill drill length customization', () {
    test('SettingsProvider defaults to 12, persists and clamps drill length',
        () async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsProvider();
      await settings.loadSettings();

      // Default is 12
      expect(settings.drillLengthForSkill('alphabet'), 12);
      expect(settings.hasSkillOverride('alphabet'), isFalse);

      // Customize to 50
      await settings.setDrillLengthForSkill('alphabet', 50);
      expect(settings.drillLengthForSkill('alphabet'), 50);
      expect(settings.hasSkillOverride('alphabet'), isTrue);

      // Clamp max 100
      await settings.setDrillLengthForSkill('alphabet', 150);
      expect(settings.drillLengthForSkill('alphabet'), 100);

      // Clamp min 5
      await settings.setDrillLengthForSkill('alphabet', 2);
      expect(settings.drillLengthForSkill('alphabet'), 5);

      // Clears override
      await settings.clearSkillOverride('alphabet');
      expect(settings.drillLengthForSkill('alphabet'), 12);
      expect(settings.hasSkillOverride('alphabet'), isFalse);
    });

    testWidgets(
        'SkillExerciseTypesSheet displays drill length controls and updates settings',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsProvider();
      await settings.loadSettings();

      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
        ],
        child: MaterialApp(
          theme: AppTheme.build(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  SkillExerciseTypesSheet.show(
                    context,
                    skillId: 'alphabet',
                    skillName: 'Alphabet & Sounds',
                  );
                },
                child: const Text('Configure'),
              ),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('Configure'));
      await tester.pumpAndSettle();

      expect(find.text('Alphabet & Sounds'), findsOneWidget);
      expect(find.text('DRILL SIZE'), findsOneWidget);
      expect(find.text('Exercises per session'), findsOneWidget);
      expect(find.text('12 exercises'), findsOneWidget);

      // Tap preset chip 25
      final chip25 = find.widgetWithText(ChoiceChip, '25');
      expect(chip25, findsOneWidget);
      await tester.tap(chip25);
      await tester.pumpAndSettle();

      expect(settings.drillLengthForSkill('alphabet'), 25);
      expect(find.text('25 exercises'), findsOneWidget);

      // Tap preset chip 100
      final chip100 = find.widgetWithText(ChoiceChip, '100');
      expect(chip100, findsOneWidget);
      await tester.tap(chip100);
      await tester.pumpAndSettle();

      expect(settings.drillLengthForSkill('alphabet'), 100);
      expect(find.text('100 exercises'), findsOneWidget);
    });
  });
}
