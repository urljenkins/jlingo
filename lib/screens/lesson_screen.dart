import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/skill.dart';
import '../models/exercise.dart';
import '../models/gamification.dart';
import '../providers/progress_provider.dart';
import '../providers/gamification_provider.dart';
import '../providers/course_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/flashcard_provider.dart';
import '../providers/word_knowledge_provider.dart';
import 'package:flutter/services.dart';
import '../services/lesson_order.dart';
import '../services/lesson_topup.dart';
import '../services/word_pool.dart';
import '../widgets/exercises/exercise_renderer_registry.dart';
import '../widgets/responsive/responsive_layout.dart';
import '../widgets/responsive/desktop_scaffold.dart';
import '../widgets/responsive/mobile_scaffold.dart';
import '../widgets/gamification/gamification_widgets.dart';
import '../theme/app_colors.dart';

class LessonScreen extends StatefulWidget {
  final Skill skill;
  final ExerciseType? filterType;

  /// Types the learner has switched off. Excluded from the lesson unless the
  /// skill has nothing else, in which case the lesson runs unfiltered rather
  /// than presenting an empty screen.
  final Set<ExerciseType> disabledTypes;

  const LessonScreen({
    super.key,
    required this.skill,
    this.filterType,
    this.disabledTypes = const {},
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

  /// True when the lesson had to include types the learner switched off,
  /// because honouring the preference would have left nothing to practise.
  bool _includedDisabledTypes = false;

  /// How many of [_exercises] were generated to top up a short skill, as
  /// opposed to authored in the skill file. Drives the notice that tells the
  /// learner where the extra practice came from.
  int _generatedCount = 0;

  void _prepareExercises() {
    if (widget.filterType != null) {
      // An explicit filter is the learner asking for that type right now, so
      // it outranks the disabled list.
      _exercises = widget.skill.exercises
          .where((e) => e.type == widget.filterType)
          .toList();
      return;
    }

    final all = widget.skill.exercises;
    final allowed =
        all.where((e) => !widget.disabledTypes.contains(e.type)).toList();

    // A skill built entirely from switched-off types would otherwise be
    // unreachable, blocking the course. Fall back to the full set and say so.
    _includedDisabledTypes = allowed.isEmpty && all.isNotEmpty;
    final authored = LessonOrder.arrange(
      _includedDisabledTypes ? all : allowed,
    );

    // Most skills carry only five exercises, which is over in a minute and
    // identical on the next visit. Top the lesson up from the course
    // vocabulary so a short skill still runs a full session, and runs a
    // different one each time.
    final pool = WordPool.build(
      deck: context.read<FlashcardProvider>().currentDeck,
      skill: widget.skill,
    );
    final extended = LessonTopUp.extend(
      authored: authored,
      pool: pool.excludingKnown(context.read<WordKnowledgeProvider>()),
      // The visit count is what makes a repeat visit a different lesson.
      seed: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    _generatedCount = extended.length - authored.length;
    _exercises = extended;
  }

  Future<void> _onAnswer(bool isCorrect) async {
    final gamificationProvider = context.read<GamificationProvider>();
    final courseProvider = context.read<CourseProvider>();
    final trackingEnabled =
        context.read<SettingsProvider>().progressTrackingEnabled;
    final courseId = courseProvider.currentManifest?.id ?? '';

    setState(() {
      _totalAnswers++;
    });

    if (isCorrect) {
      setState(() {
        _correctAnswers++;
      });

      if (trackingEnabled) {
        final result = await gamificationProvider.awardXP(
          courseId: courseId,
          type: 'exercise_correct',
          baseAmount: XPRewards.exerciseCorrect,
          description: 'Correct answer',
        );

        if (!mounted) return;

        setState(() {
          _totalXPEarned += result.totalXP;
        });

        context.read<ProgressProvider>().incrementExerciseStat(
              _exercises[_currentExerciseIndex].type.toString(),
            );

        if (result.leveledUp) {
          _showLevelUpCelebration(result.newLevel!);
        }
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
    final settingsProvider = context.read<SettingsProvider>();
    final courseId = courseProvider.currentManifest?.id ?? '';

    // Record study activity for streak if progress tracking is enabled
    int newStreak = 0;
    if (settingsProvider.progressTrackingEnabled) {
      final streakResult =
          await gamificationProvider.recordStudyActivity(courseId);
      newStreak = streakResult.newStreak;
    }

    // One pass through the skill is enough to finish it and open the next.
    // This is the bookmark the course navigates by, so it is recorded
    // whether or not scoring is switched on.
    progressProvider.markSkillCompleted(widget.skill.id);

    if (settingsProvider.progressTrackingEnabled) {
      final completionResult = await gamificationProvider.awardXP(
        courseId: courseId,
        type: 'lesson_complete',
        baseAmount: XPRewards.lessonComplete,
        description: 'Lesson completed: ${widget.skill.name}',
      );

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

      final masteryGain =
          (_correctAnswers / _totalAnswers) * 20; // Up to 20% per session
      final currentMastery =
          progressProvider.progress?.skillMastery[widget.skill.id] ?? 0.0;
      final newMastery = (currentMastery + masteryGain).clamp(0.0, 100.0);

      progressProvider.updateSkillMastery(widget.skill.id, newMastery);
      progressProvider.checkAndUnlockAchievements(
        currentStreak: newStreak,
      );
    }

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
      backgroundColor: AppColors.surface,
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
                color: AppColors.textSecondary.withValues(alpha: 0.2),
              ),
              child: Icon(
                isPerfect ? Icons.star : Icons.check_circle,
                color:
                    isPerfect ? AppColors.textPrimary : AppColors.textSecondary,
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
                  color: AppColors.textSecondary,
                ),
                _buildStatColumn(
                  icon: Icons.speed,
                  value: '$accuracy%',
                  label: 'Accuracy',
                  color: accuracy >= 80 ? AppColors.textPrimary : Colors.orange,
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
                    AppColors.textPrimary.withValues(alpha: 0.2),
                    AppColors.textSecondary.withValues(alpha: 0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star,
                      color: AppColors.textPrimary, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    '+$_totalXPEarned XP',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
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
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${LevelConfig.getXPToNextLevel(userLevel.currentXP)} XP to next',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
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
                  child: const Text('Continue'),
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
            color: AppColors.textMuted,
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
        body: Center(
          child: Text(
            widget.filterType != null
                ? 'No exercises of this type in this skill'
                : 'This skill has no exercises yet',
          ),
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
        backgroundColor: AppColors.surfaceRaised,
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
      ),
    );

    final body = Column(
      children: [
        if (_includedDisabledTypes) _buildFallbackNotice(),
        if (_isGeneratedExercise) _buildExtraPracticeNotice(),
        Expanded(child: _buildExerciseWidget(exercise)),
      ],
    );

    return ResponsiveLayout(
      mobileScaffold: MobileScaffold(topBar: topBar, body: body),
      desktopScaffold: DesktopScaffold(
        topBar: topBar,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: body,
          ),
        ),
      ),
    );
  }

  /// True once the lesson has run past its authored exercises into the ones
  /// generated to top it up.
  bool get _isGeneratedExercise =>
      _generatedCount > 0 &&
      _currentExerciseIndex >= _exercises.length - _generatedCount;

  /// Says plainly that the skill's own exercises are done and the rest is
  /// extra practice from the course vocabulary — otherwise a learner would
  /// reasonably think these words were part of the topic they picked.
  Widget _buildExtraPracticeNotice() {
    return Container(
      width: double.infinity,
      color: AppColors.surfaceRaised,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: const Text(
        'Extra practice — this topic\'s own exercises are done, so these come '
        'from your course vocabulary.',
        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
      ),
    );
  }

  /// Explains why exercise types the learner switched off are showing up,
  /// rather than leaving the preference looking broken.
  Widget _buildFallbackNotice() {
    return Container(
      width: double.infinity,
      color: AppColors.surfaceRaised,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: const Text(
        'This lesson only has exercise types you switched off, so they are '
        'included here.',
        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
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
