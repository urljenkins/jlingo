import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/progress_provider.dart';
import '../providers/course_provider.dart';
import '../models/progress.dart';
import 'language_selection_screen.dart';
import 'lesson_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final courseProvider = context.read<CourseProvider>();
    await courseProvider.loadAvailableLanguages();

    // Check if user has a selected language
    // For now, navigate to language selection
    setState(() => _isLoading = false);

    // Navigate to language selection if no course is loaded
    if (mounted && courseProvider.currentCourse == null) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, _, __) => const LanguageSelectionScreen(),
          transitionDuration: Duration.zero,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Consumer2<ProgressProvider, CourseProvider>(
      builder: (context, progressProvider, courseProvider, _) {
        final progress = progressProvider.progress;
        final course = courseProvider.currentCourse;

        if (course == null) {
          return const Scaffold(
            body: Center(child: Text('No course loaded')),
          );
        }

        final currentSkillIndex = courseProvider.getCurrentSkillIndex(
          progress?.skillMastery ?? {},
        );

        final bodyContent = Column(
          children: [
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
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (context, _, __) => LessonScreen(
                            skill: course.skills[currentSkillIndex],
                          ),
                          transitionDuration: Duration.zero,
                        ),
                      );
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (context, _, __) => LessonScreen(
                            skill: course.skills[currentSkillIndex],
                          ),
                          transitionDuration: Duration.zero,
                        ),
                      );
                    },
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
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                itemCount: course.skills.length,
                itemBuilder: (context, index) {
                  final skill = course.skills[index];
                  final mastery = progress?.skillMastery[skill.id] ?? 0.0;

                  return _buildSkillItem(skill.name, mastery, index == currentSkillIndex);
                },
              ),
            ),
          ],
        );

        return ResponsiveLayout(
          mobileScaffold: MobileScaffold(
            topBar: _buildTopBar(progress),
            body: bodyContent,
          ),
          desktopScaffold: DesktopScaffold(
            sideNav: Container(
              color: const Color(0xFF1A1A1A),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      'Lingua Sprint',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                    leading: const Icon(Icons.language),
                    title: const Text('Languages'),
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        PageRouteBuilder(
                          pageBuilder: (context, _, __) => const LanguageSelectionScreen(),
                          transitionDuration: Duration.zero,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            topBar: _buildTopBar(progress),
            body: bodyContent,
          ),
        );
      },
    );
  }

  Widget _buildTopBar(UserProgress? progress) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Streak
          Row(
            children: [
              const Icon(Icons.local_fire_department, color: Color(0xFFFF6B35), size: 28),
              const SizedBox(width: 8),
              Text(
                'Day ${progress?.currentStreak ?? 0}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          // Points
          Row(
            children: [
              const Icon(Icons.star, color: Color(0xFFFFD700), size: 28),
              const SizedBox(width: 8),
              Text(
                '${progress?.totalPoints ?? 0}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkillItem(String name, double mastery, bool isCurrent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: isCurrent ? BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF00D9FF), width: 2),
        ) : null,
        child: HoverCard(
          baseColor: isCurrent ? const Color(0xFF2A2A2A) : const Color(0xFF1A1A1A),
          hoverColor: isCurrent ? const Color(0xFF3A3A3A) : const Color(0xFF2A2A2A),
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
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00FF85)),
                      ),
                      Center(
                        child: Text(
                          '${mastery.toInt()}%',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
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
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
