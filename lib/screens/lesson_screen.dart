import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/skill.dart';
import '../models/exercise.dart';
import '../models/gamification.dart';
import '../providers/progress_provider.dart';
import '../providers/gamification_provider.dart';
import '../providers/course_provider.dart';
import 'package:flutter/services.dart';
import '../widgets/exercises/exercise_renderer_registry.dart';
import '../widgets/responsive/responsive_layout.dart';
import '../widgets/responsive/desktop_scaffold.dart';
import '../widgets/responsive/mobile_scaffold.dart';
import '../widgets/gamification/gamification_widgets.dart';

class LessonScreen extends StatefulWidget {
  final Skill skill;
  final ExerciseType? filterType;

  const LessonScreen({
    super.key,
    required this.skill,
    this.filterType,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  int _currentExerciseIndex = 0;
  int _correctAnswers = 0;
  int _totalAnswers = 0;
  int _totalXPEarned = 0;
  List<Exercise> _exercises = [];

  @override
  void initState() {
    super.initState();
    _prepareExercises();
  }

  void _prepareExercises() {
    if (widget.filterType != null) {
      _exercises = widget.skill.exercises
          .where((e) => e.type == widget.filterType)
          .toList();
    } else {
      _exercises = List.from(widget.skill.exercises)..shuffle();
    }
  }

  Future<void> _onAnswer(bool isCorrect) async {
    final gamificationProvider = context.read<GamificationProvider>();
    final courseProvider = context.read<CourseProvider>();
    final courseId = courseProvider.currentManifest?.id ?? '';

    setState(() {
      _totalAnswers++;
    });

    if (isCorrect) {
      setState(() {
        _correctAnswers++;
      });

      // Award XP through GamificationProvider
      final result = await gamificationProvider.awardXP(
        courseId: courseId,
        type: 'exercise_correct',
        baseAmount: XPRewards.exerciseCorrect,
        description: 'Correct answer',
      );

      setState(() {
        _totalXPEarned += result.totalXP;
      });

      if (!mounted) return;

      // Update legacy points for compatibility
      context.read<ProgressProvider>().addPoints(result.totalXP);

      // Update exercise stats
      context.read<ProgressProvider>().incrementExerciseStat(
            _exercises[_currentExerciseIndex].type.toString(),
          );

      // Check for level up
      if (result.leveledUp) {
        _showLevelUpCelebration(result.newLevel!);
      }
    }

    // Move to next exercise
    if (_currentExerciseIndex < _exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
      });
    } else {
      await _finishLesson();
    }
  }

  void _showLevelUpCelebration(int newLevel) {
    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => LevelUpCelebration(
        newLevel: newLevel,
        newTitle: LevelConfig.getTitleForLevel(newLevel),
        onDismiss: () {
          Navigator.of(context).pop();
        },
      ),
    ));
  }

  Future<void> _finishLesson() async {
    final progressProvider = context.read<ProgressProvider>();
    final gamificationProvider = context.read<GamificationProvider>();
    final courseProvider = context.read<CourseProvider>();
    final courseId = courseProvider.currentManifest?.id ?? '';

    // Record study activity for streak
    await gamificationProvider.recordStudyActivity(courseId);

    // Award lesson completion bonus
    final completionResult = await gamificationProvider.awardXP(
      courseId: courseId,
      type: 'lesson_complete',
      baseAmount: XPRewards.lessonComplete,
      description: 'Lesson completed: ${widget.skill.name}',
    );

    // Award perfect lesson bonus if applicable
    final isPerfect = _correctAnswers == _totalAnswers && _totalAnswers > 0;
    if (isPerfect) {
      final perfectResult = await gamificationProvider.awardXP(
        courseId: courseId,
        type: 'perfect_lesson',
        baseAmount: XPRewards.perfectLesson,
        description: 'Perfect lesson!',
      );
      _totalXPEarned += perfectResult.totalXP;
    }

    _totalXPEarned += completionResult.totalXP;

    // Update skill mastery
    final masteryGain =
        (_correctAnswers / _totalAnswers) * 20; // Up to 20% per session
    final currentMastery =
        progressProvider.progress?.skillMastery[widget.skill.id] ?? 0.0;
    final newMastery = (currentMastery + masteryGain).clamp(0.0, 100.0);

    progressProvider.updateSkillMastery(widget.skill.id, newMastery);
    progressProvider.updateStreak();
    progressProvider.checkAndUnlockAchievements();

    // Show completion dialog
    if (!mounted) return;
    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildCompletionDialog(),
    ));
  }

  Widget _buildCompletionDialog() {
    final accuracy = (_correctAnswers / _totalAnswers * 100).round();
    final isPerfect = _correctAnswers == _totalAnswers && _totalAnswers > 0;
    final gamificationProvider = context.read<GamificationProvider>();
    final userLevel = gamificationProvider.userLevel;

    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00FF85).withValues(alpha: 0.2),
              ),
              child: Icon(
                isPerfect ? Icons.star : Icons.check_circle,
                color: isPerfect
                    ? const Color(0xFFFFD700)
                    : const Color(0xFF00FF85),
                size: 64,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isPerfect ? 'Perfect!' : 'Lesson Complete!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn(
                  icon: Icons.check,
                  value: '$_correctAnswers/$_totalAnswers',
                  label: 'Correct',
                  color: const Color(0xFF00FF85),
                ),
                _buildStatColumn(
                  icon: Icons.speed,
                  value: '$accuracy%',
                  label: 'Accuracy',
                  color:
                      accuracy >= 80 ? const Color(0xFF00D9FF) : Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // XP earned
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFD700).withValues(alpha: 0.2),
                    const Color(0xFFFF6B35).withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Color(0xFFFFD700), size: 28),
                  const SizedBox(width: 8),
                  Text(
                    '+$_totalXPEarned XP',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Level progress
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Level ${userLevel.level} - ${userLevel.title}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '${LevelConfig.getXPToNextLevel(userLevel.currentXP)} XP to next',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                XPProgressBar(
                  userLevel: userLevel,
                  showLabel: false,
                  height: 8,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Continue button
            SizedBox(
              width: double.infinity,
              child: Focus(
                autofocus: true,
                onKeyEvent: (node, event) {
                  if (event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey == LogicalKeyboardKey.numpadEnter) {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                    return KeyEventResult.handled;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.escape) {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Return to home
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D9FF),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'CONTINUE',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.2),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_exercises.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: Text('No exercises available for this filter'),
        ),
      );
    }

    final exercise = _exercises[_currentExerciseIndex];
    final progress = _currentExerciseIndex / _exercises.length;

    final topBar = AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: LinearProgressIndicator(
        value: progress,
        backgroundColor: const Color(0xFF3A3A3A),
        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00D9FF)),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            '${_currentExerciseIndex + 1}/${_exercises.length}',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );

    return ResponsiveLayout(
      mobileScaffold: MobileScaffold(
        topBar: topBar,
        body: _buildExerciseWidget(exercise),
      ),
      desktopScaffold: DesktopScaffold(
        topBar: topBar,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: _buildExerciseWidget(exercise),
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseWidget(Exercise exercise) {
    return ExerciseRendererRegistry.render(
      exercise: exercise,
      onAnswer: _onAnswer,
    );
  }
}
