import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'providers/progress_provider.dart';
import 'providers/course_provider.dart';
import 'providers/flashcard_provider.dart';
import 'providers/vocabulary_provider.dart';
import 'providers/gamification_provider.dart';
import 'providers/book_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/settings_provider.dart';

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
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        title: 'Lingua Sprint',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00D9FF),
            secondary: Color(0xFF00FF85),
            error: Color(0xFFFF4757),
            surface: Color(0xFF0D0D0D),
          ),
          scaffoldBackgroundColor: const Color(0xFF0D0D0D),
          textTheme: const TextTheme(
            displayLarge: TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.32,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            bodyLarge: TextStyle(
                fontFamily: 'Inter',
                letterSpacing: -0.18,
                fontSize: 18,
                color: Colors.white),
            bodyMedium: TextStyle(
                fontFamily: 'Inter',
                letterSpacing: -0.16,
                fontSize: 16,
                color: Colors.white70),
          ),
          // Disable all animations
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: _InstantPageTransitionsBuilder(),
              TargetPlatform.iOS: _InstantPageTransitionsBuilder(),
            },
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}

// Instant page transitions - no animations
class _InstantPageTransitionsBuilder extends PageTransitionsBuilder {
  const _InstantPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
