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

  /// Target number of exercises for this drill session.
  final int drillLength;

  const LessonScreen({
    super.key,
    required this.skill,
    this.filterType,
    this.disabledTypes = const {},
    this.drillLength = LessonTopUp.targetLength,
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

  /// Indices the learner has already answered. Going back to review one of
  /// these must not score it again, and the exercise renders in a resolved,
  /// non-interactive state.
  final Set<int> _answeredIndices = {};

  /// Indices the learner skipped without answering. Tracked so the completion
  /// summary can report them, and so re-skipping the same one doesn't count
  /// twice.
  final Set<int> _skippedIndices = {};

  /// Indices whose answer the learner has asked to see (via the Reveal button,
  /// or by skipping). Kept so stepping back onto a skipped exercise still shows
  /// its answer, as a learner would expect.
  final Set<int> _revealedIndices = {};

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
      final filtered = widget.skill.exercises
          .where((e) => e.type == widget.filterType)
          .toList();
      _exercises = filtered.length > widget.drillLength
          ? filtered.sublist(0, widget.drillLength)
          : filtered;
      return;
    }

    final all = widget.skill.exercises;
    final allowed =
        all.where((e) => !widget.disabledTypes.contains(e.type)).toList();

    // A skill built entirely from switched-off types would otherwise be
    // unreachable, blocking the course. Fall back to the full set and say so.
    _includedDisabledTypes = allowed.isEmpty && all.isNotEmpty;
    final source = _includedDisabledTypes ? all : allowed;
    final authored = LessonOrder.arrange(source);

    // If we have more authored exercises than the target drill length (e.g. 100
    // exercises in a deep skill), sample a fresh window rotating by current timestamp
    // so repeat visits cycle through different exercises without seeing the same pool.
    List<Exercise> baseAuthored = authored;
    if (authored.length > widget.drillLength) {
      final seed = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      // Preserve introduction/teaching groups if possible by selecting a contiguous
      // rotating slice across the ordered exercises.
      final offset = seed % authored.length;
      final rotated = [
        ...authored.sublist(offset),
        ...authored.sublist(0, offset),
      ];
      baseAuthored =
          LessonOrder.arrange(rotated.sublist(0, widget.drillLength));
    }

    // Top the lesson up from the course vocabulary if fewer than drillLength.
    final pool = WordPool.build(
      deck: context.read<FlashcardProvider>().currentDeck,
      skill: widget.skill,
    );
    final extended = LessonTopUp.extend(
      authored: baseAuthored,
      pool: pool.excludingKnown(context.read<WordKnowledgeProvider>()),
      seed: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      targetLength: widget.drillLength,
    );

    _generatedCount = extended.length - baseAuthored.length;
    _exercises = extended;
  }

  Future<void> _onAnswer(bool isCorrect) async {
    // Reviewing an exercise that was already answered (the learner stepped
    // back to it). The widget is wrapped in an IgnorePointer while reviewing,
    // so this shouldn't fire — but guard anyway and never re-score.
    if (_answeredIndices.contains(_currentExerciseIndex)) {
      return;
    }

    final gamificationProvider = context.read<GamificationProvider>();
    final courseProvider = context.read<CourseProvider>();
    final trackingEnabled =
        context.read<SettingsProvider>().progressTrackingEnabled;
    final courseId = courseProvider.currentManifest?.id ?? '';

    setState(() {
      _totalAnswers++;
      _answeredIndices.add(_currentExerciseIndex);
      _skippedIndices.remove(_currentExerciseIndex);
      _revealedIndices.remove(_currentExerciseIndex);
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

    await _advanceOrFinish();
  }

  /// Advance to the next exercise, or finish the lesson if this was the last
  /// one. Used both after an answer and by the skip button.
  Future<void> _advanceOrFinish() async {
    if (_currentExerciseIndex < _exercises.length - 1) {
      _goToNext();
    } else {
      await _finishLesson();
    }
  }

  void _goToNext() {
    if (_currentExerciseIndex >= _exercises.length - 1) return;
    setState(() {
      _currentExerciseIndex++;
    });
  }

  void _goToPrevious() {
    if (_currentExerciseIndex == 0) return;
    setState(() {
      _currentExerciseIndex--;
    });
  }

  /// Move past the current exercise without answering it. It stays unanswered,
  /// so stepping back to it later still lets the learner attempt it — but its
  /// answer is revealed, so stepping back shows what it was.
  Future<void> _skipExercise() async {
    if (!_answeredIndices.contains(_currentExerciseIndex)) {
      setState(() {
        _skippedIndices.add(_currentExerciseIndex);
        _revealedIndices.add(_currentExerciseIndex);
      });
    }
    await _advanceOrFinish();
  }

  /// Toggle the answer banner for the current exercise.
  void _toggleReveal() {
    setState(() {
      if (!_revealedIndices.remove(_currentExerciseIndex)) {
        _revealedIndices.add(_currentExerciseIndex);
      }
    });
  }

  /// A readable form of the exercise's expected answer, for the reveal banner.
  /// Most exercises carry it in [Exercise.correctAnswer]; matchPairs keep the
  /// pairing in metadata instead.
  String _answerText(Exercise exercise) {
    if (exercise.correctAnswer.trim().isNotEmpty) {
      return exercise.correctAnswer;
    }
    final pairs = exercise.metadata?['pairs'];
    if (pairs is List) {
      final lines = <String>[];
      for (final pair in pairs) {
        if (pair is Map) {
          lines.add('${pair['target']} → ${pair['native']}');
        }
      }
      if (lines.isNotEmpty) return lines.join('\n');
    }
    return '—';
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

      final masteryGain = _totalAnswers > 0
          ? (_correctAnswers / _totalAnswers) * 20 // Up to 20% per session
          : 0.0;
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
    final accuracy =
        _totalAnswers > 0 ? (_correctAnswers / _totalAnswers * 100).round() : 0;
    final isPerfect = _correctAnswers == _totalAnswers && _totalAnswers > 0;
    final skipped = _skippedIndices.length;
    final trackingEnabled =
        context.read<SettingsProvider>().progressTrackingEnabled;
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
                if (trackingEnabled)
                  _buildStatColumn(
                    icon: Icons.speed,
                    value: '$accuracy%',
                    label: 'Accuracy',
                    color:
                        accuracy >= 80 ? AppColors.textPrimary : Colors.orange,
                  ),
                if (skipped > 0)
                  _buildStatColumn(
                    icon: Icons.skip_next,
                    value: '$skipped',
                    label: 'Skipped',
                    color: AppColors.textMuted,
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // XP and level progress are only meaningful when progress
            // tracking is on; with it off, scoring never ran.
            if (trackingEnabled) ...[
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
            ],

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
    final total = _exercises.length;
    // Fill the bar by exercises resolved (answered or skipped), so it reflects
    // how much of the lesson is behind the learner rather than just position.
    final resolved = _answeredIndices.length + _skippedIndices.length;
    final progress = resolved / total;
    final alreadyAnswered = _answeredIndices.contains(_currentExerciseIndex);
    final answerRevealed =
        !alreadyAnswered && _revealedIndices.contains(_currentExerciseIndex);

    final topBar = AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.skill.name,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.surfaceRaised,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            '${_currentExerciseIndex + 1} of $total',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );

    final body = Column(
      children: [
        if (_includedDisabledTypes) _buildFallbackNotice(),
        if (_isGeneratedExercise) _buildExtraPracticeNotice(),
        if (alreadyAnswered) _buildReviewNotice(),
        if (answerRevealed) _buildAnswerBanner(exercise),
        Expanded(
          child: alreadyAnswered
              // Locked review: the outcome is already recorded, so the
              // learner can look but not re-answer (which would show fresh
              // "correct" feedback and mislead).
              ? IgnorePointer(
                  child: Opacity(
                    opacity: 0.6,
                    child: _buildExerciseWidget(exercise),
                  ),
                )
              : _buildExerciseWidget(exercise),
        ),
        _buildNavBar(alreadyAnswered, answerRevealed),
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

  /// Shown when the learner has stepped back onto an exercise they already
  /// answered. Its outcome is locked in; attempting it again won't re-score.
  Widget _buildReviewNotice() {
    return Container(
      width: double.infinity,
      color: AppColors.surfaceRaised,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: const Text(
        'Reviewing — you already answered this one, so it won\'t be scored '
        'again.',
        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
      ),
    );
  }

  /// Shows the expected answer for the current exercise, either because the
  /// learner asked to see it or because they skipped and stepped back.
  Widget _buildAnswerBanner(Exercise exercise) {
    return Container(
      width: double.infinity,
      color: AppColors.surfaceRaised,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Answer',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            _answerText(exercise),
            style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  /// Back / Reveal / Skip controls beneath the exercise. Back steps to the
  /// previous exercise without undoing any score; Reveal shows the answer for
  /// the current one; Skip moves past it without answering.
  Widget _buildNavBar(bool alreadyAnswered, bool answerRevealed) {
    final atStart = _currentExerciseIndex == 0;
    final isLast = _currentExerciseIndex == _exercises.length - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: atStart ? null : _goToPrevious,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back'),
          ),
          const Spacer(),
          if (!alreadyAnswered)
            TextButton.icon(
              onPressed: _toggleReveal,
              icon: Icon(answerRevealed
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined),
              label: Text(answerRevealed ? 'Hide' : 'Reveal'),
            ),
          const Spacer(),
          TextButton.icon(
            onPressed: alreadyAnswered ? _advanceOrFinish : _skipExercise,
            icon: Icon(alreadyAnswered
                ? (isLast ? Icons.check : Icons.arrow_forward)
                : Icons.skip_next),
            label: Text(
              alreadyAnswered ? (isLast ? 'Finish' : 'Next') : 'Skip',
            ),
          ),
        ],
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
