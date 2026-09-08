import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/app_shell.dart';
import 'providers/progress_provider.dart';
import 'providers/course_provider.dart';
import 'providers/flashcard_provider.dart';
import 'providers/vocabulary_provider.dart';
import 'providers/gamification_provider.dart';
import 'providers/book_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/word_knowledge_provider.dart';
import 'providers/settings_provider.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const LinguaSprintApp());
}

class LinguaSprintApp extends StatefulWidget {
  const LinguaSprintApp({super.key});

  @override
  State<LinguaSprintApp> createState() => _LinguaSprintAppState();
}

class _LinguaSprintAppState extends State<LinguaSprintApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => CourseProvider()),
        ChangeNotifierProvider(create: (_) => FlashcardProvider()),
        ChangeNotifierProvider(create: (_) => VocabularyProvider()),
        ChangeNotifierProvider(create: (_) => GamificationProvider()),
        ChangeNotifierProvider(create: (_) => BookProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(create: (_) => WordKnowledgeProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final settings = SettingsProvider();
            unawaited(settings.loadSettings());
            return settings;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Lingua Sprint',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(),
        home: const AppShell(),
      ),
    );
  }
}
