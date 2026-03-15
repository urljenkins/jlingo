import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/progress_provider.dart';
import '../providers/course_provider.dart';
import '../providers/flashcard_provider.dart';
import '../providers/vocabulary_provider.dart';
import '../providers/gamification_provider.dart';
import '../models/exercise.dart';
import '../models/course_manifest.dart';
import '../models/gamification.dart';
import '../widgets/gamification/xp_widgets.dart'; // For XPProgressBar
import 'language_selection_screen.dart';
import 'lesson_screen.dart';
import 'vocabulary_screen.dart';
import '../widgets/responsive/responsive_layout.dart';
import '../widgets/responsive/desktop_scaffold.dart';
import 'package:flutter/services.dart';
import '../widgets/responsive/mobile_scaffold.dart';
import '../widgets/hover_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  ExerciseType? _selectedFilter;

  @override
  void initState() {
    super.initState();
    // ignore: discarded_futures
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final courseProvider = context.read<CourseProvider>();
    final progressProvider = context.read<ProgressProvider>();
    final flashcardProvider = context.read<FlashcardProvider>();
    final vocabularyProvider = context.read<VocabularyProvider>();
    final gamificationProvider = context.read<GamificationProvider>();
    await courseProvider.loadAvailableLanguages();

    if (courseProvider.currentManifest == null) {
      final savedLanguage = await courseProvider.getSavedLanguage();
      if (savedLanguage != null) {
        await courseProvider.loadCourse(savedLanguage);
        if (courseProvider.currentManifest != null) {
          await progressProvider
              .loadProgress(courseProvider.currentManifest!.id);
          // Load gamification data
          await gamificationProvider
              .loadGamificationData(courseProvider.currentManifest!.id);
          // Load vocabulary data
          await flashcardProvider.loadDecks(courseProvider.currentManifest!.id);
          await vocabularyProvider
              .loadVocabularyData(courseProvider.currentManifest!.id);
        }
      }
    }

    setState(() => _isLoading = false);

    // Navigate to language selection if no course is loaded
    if (mounted && courseProvider.currentManifest == null) {
      // ignore: unawaited_futures
      Navigator.of(context).pushReplacement(
        PageRouteBuilder<void>(
          pageBuilder: (context, _, __) => const LanguageSelectionScreen(),
          transitionDuration: Duration.zero,
        ),
      );
    }
  }

  Future<void> _startLesson(String skillId) async {
    setState(() => _isLoading = true);
    final skill = await context.read<CourseProvider>().loadSkill(skillId);
    setState(() => _isLoading = false);

    if (mounted && skill != null) {
      unawaited(Navigator.of(context).push(
        PageRouteBuilder<void>(
          pageBuilder: (context, _, __) => LessonScreen(
            skill: skill,
            filterType: _selectedFilter,
          ),
          transitionDuration: Duration.zero,
        ),
      ));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading lesson content')),
      );
    }
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All'),
            selected: _selectedFilter == null,
            onSelected: (selected) {
              setState(() {
                _selectedFilter = null;
              });
            },
            selectedColor: const Color(0xFF00D9FF),
            labelStyle: TextStyle(
              color: _selectedFilter == null ? Colors.black : Colors.white,
            ),
          ),
          ...ExerciseType.values.map((type) {
            return Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: FilterChip(
                label: Text(_formatExerciseType(type)),
                selected: _selectedFilter == type,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = selected ? type : null;
                  });
                },
                selectedColor: const Color(0xFF00D9FF),
                labelStyle: TextStyle(
                  color: _selectedFilter == type ? Colors.black : Colors.white,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatExerciseType(ExerciseType type) {
    switch (type) {
      case ExerciseType.translateThis:
        return 'Translate';
      case ExerciseType.matchPairs:
        return 'Match';
      case ExerciseType.multipleChoice:
        return 'Multiple Choice';
      case ExerciseType.listeningComprehension:
        return 'Listening';
      case ExerciseType.speakThis:
        return 'Speaking';
      case ExerciseType.fillInBlank:
        return 'Fill Blank';
      case ExerciseType.nativeAudio:
        return 'Native Audio';
      case ExerciseType.pronunciationPractice:
        return 'Pronunciation';
      case ExerciseType.dialogueListening:
        return 'Dialogue';
      case ExerciseType.songFill:
        return 'Song Fill';
      case ExerciseType.interactiveDialogue:
        return 'Interactive';
      case ExerciseType.storyLesson:
        return 'Story';
      case ExerciseType.translationExercise:
        return 'Translation';
      case ExerciseType.clozeTest:
        return 'Cloze Test';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Consumer3<ProgressProvider, CourseProvider, GamificationProvider>(
      builder:
          (context, progressProvider, courseProvider, gamificationProvider, _) {
        final progress = progressProvider.progress;
        final manifest = courseProvider.currentManifest;
        final userLevel = gamificationProvider.userLevel;
        final streakInfo = gamificationProvider.streakInfo;
        final dailyGoal = gamificationProvider.dailyGoal;

        if (manifest == null) {
          return const Scaffold(
            body: Center(child: Text('No course loaded')),
          );
        }

        final currentSkillIndex = courseProvider.getCurrentSkillIndex(
          progress?.skillMastery ?? {},
        );

        final bodyContent = Column(
          children: [
            // XP Progress and Daily Goal
            _buildHomeGamificationHeader(userLevel, dailyGoal),

            // Filter Bar
            _buildFilterBar(),

            // Continue Button
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: Focus(
                  autofocus: true,
                  onKeyEvent: (node, event) {
                    if (event.logicalKey == LogicalKeyboardKey.enter ||
                        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
                      unawaited(
                          _startLesson(manifest.skills[currentSkillIndex].id));
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: ElevatedButton(
                    onPressed: () =>
                        _startLesson(manifest.skills[currentSkillIndex].id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'CONTINUE',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Skills List
            Expanded(
              child: _buildSkillList(manifest, progressProvider),
            ),
          ],
        );

        return ResponsiveLayout(
          mobileScaffold: MobileScaffold(
            topBar: _buildHomeTopBar(userLevel, streakInfo),
            body: bodyContent,
          ),
          desktopScaffold: DesktopScaffold(
            sideNav: ColoredBox(
              color: const Color(0xFF1A1A1A),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      'Lingua Sprint',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.home),
                    title: const Text('Home'),
                    onTap: () {},
                    selected: true,
                    selectedColor: Theme.of(context).colorScheme.primary,
                  ),
                  ListTile(
                    leading: const Icon(Icons.library_books),
                    title: const Text('Vocabulary'),
                    onTap: _navigateToVocabulary,
                  ),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: const Text('Languages'),
                    onTap: _navigateToLanguageSelection,
                  ),
                ],
              ),
            ),
            topBar: _buildHomeTopBar(userLevel, streakInfo),
            body: bodyContent,
          ),
        );
      },
    );
  }

  void _navigateToLanguageSelection() {
    unawaited(Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, _, __) => const LanguageSelectionScreen(),
        transitionDuration: Duration.zero,
      ),
    ));
  }

  void _navigateToVocabulary() {
    unawaited(Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (context, _, __) => const VocabularyScreen(),
        transitionDuration: Duration.zero,
      ),
    ));
  }

  Widget _buildHomeGamificationHeader(
      UserLevel userLevel, DailyGoal dailyGoal) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Column(
        children: [
          XPProgressBar(userLevel: userLevel),
          const SizedBox(height: 8),
          DailyGoalWidget(dailyGoal: dailyGoal),
        ],
      ),
    );
  }

  Widget _buildHomeTopBar(UserLevel userLevel, StreakInfo streakInfo) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Streak
          Row(
            children: [
              const Icon(Icons.local_fire_department,
                  color: Color(0xFFFF6B35), size: 28),
              const SizedBox(width: 8),
              Text(
                'Day ${streakInfo.currentStreak}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          // XP + vocabulary + language switch
          Row(
            children: [
              const Icon(Icons.star, color: Color(0xFFFFD700), size: 28),
              const SizedBox(width: 8),
              Text(
                '${userLevel.currentXP}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.library_books),
                tooltip: 'Vocabulary',
                onPressed: _navigateToVocabulary,
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.language),
                tooltip: 'Change language',
                onPressed: _navigateToLanguageSelection,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkillList(
      CourseManifest manifest, ProgressProvider progressProvider) {
    final progress = progressProvider.progress;
    final Map<int, List<SkillHeader>> groupedSkills = {};
    for (final skill in manifest.skills) {
      groupedSkills.putIfAbsent(skill.level, () => []).add(skill);
    }

    final sortedLevels = groupedSkills.keys.toList()..sort();
    final currentSkillIndex =
        context.read<CourseProvider>().getCurrentSkillIndex(
              progress?.skillMastery ?? {},
            );
    final currentSkillId = currentSkillIndex < manifest.skills.length
        ? manifest.skills[currentSkillIndex].id
        : null;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      itemCount: sortedLevels.length,
      itemBuilder: (context, index) {
        final level = sortedLevels[index];
        final levelSkills = groupedSkills[level]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
              child: Text(
                _getLevelTitle(level),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00D9FF),
                ),
              ),
            ),
            ...levelSkills.map((skill) {
              final mastery = progress?.skillMastery[skill.id] ?? 0.0;
              return _buildSkillItem(
                skill.name,
                mastery,
                skill.id == currentSkillId,
                onTap: () => _startLesson(skill.id),
              );
            }),
          ],
        );
      },
    );
  }

  String _getLevelTitle(int level) {
    switch (level) {
      case 1:
        return 'Foundational Building Blocks';
      case 2:
        return 'Intermediate Communication';
      case 3:
        return 'Numbers & Counting';
      case 4:
        return 'Food & Drink';
      case 5:
        return 'Daily Routine';
      case 6:
        return 'Getting Around';
      default:
        return 'Level $level';
    }
  }

  Widget _buildSkillItem(String name, double mastery, bool isCurrent,
      {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: isCurrent
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF00D9FF), width: 2),
              )
            : const BoxDecoration(),
        child: HoverCard(
          onTap: onTap,
          baseColor:
              isCurrent ? const Color(0xFF2A2A2A) : const Color(0xFF1A1A1A),
          hoverColor:
              isCurrent ? const Color(0xFF3A3A3A) : const Color(0xFF2A2A2A),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Mastery Circle
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    children: [
                      CircularProgressIndicator(
                        value: mastery / 100,
                        strokeWidth: 4,
                        backgroundColor: const Color(0xFF3A3A3A),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF00FF85)),
                      ),
                      Center(
                        child: Text(
                          '${mastery.toInt()}%',
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Skill Name
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
