import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/cefr_level.dart';
import '../models/user_profile.dart';
import '../models/course_manifest.dart';
import '../models/exercise.dart';
import '../models/gamification.dart';
import '../providers/course_provider.dart';
import '../providers/flashcard_provider.dart';
import '../providers/gamification_provider.dart';
import '../providers/onboarding_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/vocabulary_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/language_display.dart';
import '../widgets/gamification/xp_widgets.dart';
import '../widgets/responsive/mobile_scaffold.dart';
import 'language_selection_screen.dart';
import 'lesson_screen.dart';
import 'vocabulary_screen.dart';
import 'word_of_day_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;

  /// Restricts a lesson to a single exercise type. Null means "All".
  ExerciseType? _selectedFilter;

  Future<void> _startLesson(String skillId) async {
    setState(() => _isLoading = true);
    final skill = await context.read<CourseProvider>().loadSkill(skillId);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (skill == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading lesson content')),
      );
      return;
    }

    // The skill list is built from manifest headers, which carry no exercise
    // types, so a filter can only be checked once the skill itself is loaded.
    // Catching it here keeps the lesson screen off the stack entirely rather
    // than opening it on an empty state the user has to back out of.
    final filter = _selectedFilter;
    if (filter != null && !skill.exercises.any((e) => e.type == filter)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No ${_formatExerciseType(filter)} exercises in ${skill.name}',
          ),
        ),
      );
      return;
    }

    unawaited(Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => LessonScreen(skill: skill, filterType: filter),
      ),
    ));
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
        final manifest = courseProvider.currentManifest;
        if (manifest == null) {
          return const Scaffold(
            body: Center(child: Text('No course loaded')),
          );
        }

        final trackingEnabled =
            context.watch<SettingsProvider>().progressTrackingEnabled;
        final completed =
            progressProvider.progress?.completedSkills ?? const <String>{};
        final currentSkillIndex =
            courseProvider.getCurrentSkillIndex(completed);

        final body = Column(
          children: [
            if (trackingEnabled)
              _buildTrackingCard(
                gamificationProvider.userLevel,
                gamificationProvider.dailyGoal,
              )
            else
              _buildWordOfDayCard(),
            _buildContinueButton(manifest, currentSkillIndex),
            _buildFilterBar(),
            Expanded(child: _buildSkillList(manifest, progressProvider)),
          ],
        );

        final topBar = _buildTopBar(
          manifest,
          gamificationProvider.userLevel,
          gamificationProvider.streakInfo,
          trackingEnabled,
        );

        return MobileScaffold(topBar: topBar, body: body);
      },
    );
  }

  // ---------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------

  void _push(Widget screen) {
    unawaited(Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => screen),
    ));
  }

  void _navigateToWordOfDay() => _push(const WordOfDayScreen());
  void _navigateToVocabulary() => _push(const VocabularyScreen());

  // Pushed, not replaced: replacing would tear down the shell and take the
  // navigation with it.
  void _navigateToLanguageSelection() => _push(const LanguageSelectionScreen());

  // ---------------------------------------------------------------------
  // Exercise type filter
  // ---------------------------------------------------------------------

  /// Horizontal chip row restricting lessons to one exercise type.
  Widget _buildFilterBar() {
    return SizedBox(
      height: 32 + AppSpacing.md,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        itemCount: ExerciseType.values.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _FilterChip(
              label: 'All',
              selected: _selectedFilter == null,
              onTap: () => setState(() => _selectedFilter = null),
            );
          }
          final type = ExerciseType.values[index - 1];
          return _FilterChip(
            label: _formatExerciseType(type),
            selected: _selectedFilter == type,
            // Tapping the active chip clears it, so the row never traps the
            // user in a filtered state.
            onTap: () => setState(
              () => _selectedFilter = _selectedFilter == type ? null : type,
            ),
          );
        },
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

  // ---------------------------------------------------------------------
  // Top bar
  // ---------------------------------------------------------------------

  Widget _buildTopBar(CourseManifest manifest, UserLevel userLevel,
      StreakInfo streakInfo, bool trackingEnabled) {
    final vocabulary = context.watch<VocabularyProvider>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenInset,
        AppSpacing.md,
        AppSpacing.screenInset,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: trackingEnabled
                    ? _trackingChips(userLevel, streakInfo)
                    : _libraryChips(vocabulary),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _buildLanguageChip(manifest),
        ],
      ),
    );
  }

  /// Counters shown only when the learner has opted into scoring.
  List<Widget> _trackingChips(UserLevel userLevel, StreakInfo streakInfo) {
    return [
      _Chip(
        icon: Icons.local_fire_department_outlined,
        label: 'Day ${streakInfo.currentStreak}',
      ),
      const SizedBox(width: AppSpacing.sm),
      _Chip(icon: Icons.bolt_outlined, label: '${userLevel.currentXP} XP'),
    ];
  }

  /// The default. Inventory rather than achievement: what is in the library
  /// and what is waiting, never what has been earned.
  List<Widget> _libraryChips(VocabularyProvider vocabulary) {
    final saved = vocabulary.savedWords.length;
    final due = context.watch<FlashcardProvider>().remainingCards;

    return [
      if (vocabulary.todaysWord != null)
        _Chip(
          icon: Icons.auto_stories_outlined,
          label: vocabulary.todaysWord!.word,
          onTap: _navigateToWordOfDay,
        ),
      if (saved > 0) ...[
        const SizedBox(width: AppSpacing.sm),
        _Chip(
          icon: Icons.bookmark_outline,
          label: '$saved saved',
          onTap: _navigateToVocabulary,
        ),
      ],
      if (due > 0) ...[
        const SizedBox(width: AppSpacing.sm),
        _Chip(icon: Icons.style_outlined, label: '$due due'),
      ],
    ];
  }

  Widget _buildLanguageChip(CourseManifest manifest) {
    return _Chip(
      label: LanguageDisplay.name(manifest.targetLanguage),
      trailing: Icons.expand_more,
      onTap: _navigateToLanguageSelection,
    );
  }

  // ---------------------------------------------------------------------
  // Hero card
  // ---------------------------------------------------------------------

  /// Occupies the slot the level/daily-target card holds when scoring is on.
  Widget _buildWordOfDayCard() {
    final word = context.watch<VocabularyProvider>().todaysWord;
    if (word == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenInset,
        AppSpacing.sm,
        AppSpacing.screenInset,
        AppSpacing.md,
      ),
      child: _Surface(
        onTap: _navigateToWordOfDay,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('WORD OF THE DAY', style: AppTypography.sectionLabel),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(word.word, style: AppTypography.title),
                      const SizedBox(height: AppSpacing.xs),
                      Text(word.translation, style: AppTypography.subtitle),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_outward,
                    size: 18, color: AppColors.textMuted),
              ],
            ),
            if (word.exampleSentence.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.md),
              Text(
                word.exampleSentence,
                style: AppTypography.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingCard(UserLevel userLevel, DailyGoal dailyGoal) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenInset,
        AppSpacing.sm,
        AppSpacing.screenInset,
        AppSpacing.md,
      ),
      child: _Surface(
        child: Column(
          children: [
            XPProgressBar(userLevel: userLevel),
            const SizedBox(height: AppSpacing.md),
            const Divider(),
            const SizedBox(height: AppSpacing.md),
            DailyGoalWidget(dailyGoal: dailyGoal),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Continue
  // ---------------------------------------------------------------------

  Widget _buildContinueButton(CourseManifest manifest, int currentSkillIndex) {
    final skill = manifest.skills[currentSkillIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenInset),
      child: SizedBox(
        width: double.infinity,
        child: Focus(
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.numpadEnter) {
              unawaited(_startLesson(skill.id));
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: ElevatedButton(
            onPressed: () => _startLesson(skill.id),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Continue'),
                const SizedBox(height: 2),
                Text(
                  'Next up: ${skill.name}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.onAccent.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Skill list
  // ---------------------------------------------------------------------

  Widget _buildSkillList(
      CourseManifest manifest, ProgressProvider progressProvider) {
    final completed = progressProvider.progress?.completedSkills ?? const {};
    final language = context.watch<CourseProvider>().currentLanguageCode;
    final entryLevel =
        context.watch<OnboardingProvider>().profile.levelFor(language);
    final currentIndex = context.read<CourseProvider>().getCurrentSkillIndex(
          completed,
          entryLevel: entryLevel,
          manifest: manifest,
        );
    final currentSkillId = currentIndex < manifest.skills.length
        ? manifest.skills[currentIndex].id
        : null;

    final courseSkillLevels = manifest.skills.map((s) => s.level).toList();

    // Group by CEFR tier rather than by raw level: levels run 1-27, so
    // grouping by number would repeat "UPPER INTERMEDIATE · B2" a dozen times
    // down the list. Skills keep their manifest order within a tier.
    final Map<LanguageLevel, List<SkillHeader>> groupedSkills = {};
    for (final skill in manifest.skills) {
      groupedSkills
          .putIfAbsent(CefrLevel.tierForSkillLevel(skill.level), () => [])
          .add(skill);
    }
    final sortedTiers = CefrLevel.ordered
        .where(groupedSkills.containsKey)
        .toList(growable: false);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenInset,
        AppSpacing.lg,
        AppSpacing.screenInset,
        AppSpacing.xxl,
      ),
      itemCount: sortedTiers.length,
      itemBuilder: (context, index) {
        final tier = sortedTiers[index];
        final levelSkills = groupedSkills[tier]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) const SizedBox(height: AppSpacing.xl),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                '${CefrLevel.nameFor(tier)} · ${CefrLevel.codeFor(tier)}'
                    .toUpperCase(),
                style: AppTypography.sectionLabel,
              ),
            ),
            ...levelSkills.map((skill) {
              // A skill opens if it sits at or below the learner's chosen
              // entry level, or once the one before it has been finished.
              final position = manifest.skills.indexOf(skill);
              final unlocked = isSkillUnlocked(
                skillLevel: skill.level,
                position: position,
                previousCompleted: position > 0 &&
                    completed.contains(manifest.skills[position - 1].id),
                entryLevel: entryLevel,
                courseSkillLevels: courseSkillLevels,
              );

              return _SkillRow(
                name: skill.name,
                isCompleted: completed.contains(skill.id),
                isCurrent: skill.id == currentSkillId,
                isUnlocked: unlocked,
                previousSkillName:
                    position > 0 ? manifest.skills[position - 1].name : null,
                onTap: unlocked ? () => _startLesson(skill.id) : null,
              );
            }),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // Bottom navigation
  // ---------------------------------------------------------------------

  /// Read and Words were previously buried in a row of icon buttons; the
  /// destinations that exist get a tab each.
}

/// Pill used across the top bar. Inert unless [onTap] is supplied.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    this.icon,
    this.trailing,
    this.onTap,
  });

  final String label;
  final IconData? icon;
  final IconData? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.xs + 2),
          ],
          Text(label, style: AppTypography.label),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.xs),
            Icon(trailing, size: 16, color: AppColors.textSecondary),
          ],
        ],
      ),
    );

    return Material(
      color: AppColors.surface,
      shape: const StadiumBorder(
        side: BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}

/// Selectable chip used by the exercise type filter row.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.accent : AppColors.surface,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? AppColors.accent : AppColors.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Center(
            child: Text(
              label,
              style: AppTypography.label.copyWith(
                color: selected ? AppColors.onAccent : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bordered card used for the hero slot.
class _Surface extends StatelessWidget {
  const _Surface({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final padded = Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: child,
    );

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.border),
      ),
      child: onTap == null ? padded : InkWell(onTap: onTap, child: padded),
    );
  }
}

/// One skill in the course list. State is carried by a leading glyph and a
/// short status word — never a percentage.
class _SkillRow extends StatelessWidget {
  const _SkillRow({
    required this.name,
    required this.isCompleted,
    required this.isCurrent,
    required this.isUnlocked,
    required this.previousSkillName,
    this.onTap,
  });

  final String name;
  final bool isCompleted;
  final bool isCurrent;
  final bool isUnlocked;
  final String? previousSkillName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final titleColor =
        isUnlocked ? AppColors.textPrimary : AppColors.textDisabled;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: isCurrent ? AppColors.surfaceRaised : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(
            color: isCurrent ? AppColors.borderStrong : AppColors.border,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                _buildGlyph(),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AppTypography.heading.copyWith(
                          color: titleColor,
                        ),
                      ),
                      if (_subtitle != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(_subtitle!, style: AppTypography.caption),
                      ],
                    ],
                  ),
                ),
                if (isUnlocked)
                  Icon(
                    isCompleted ? Icons.refresh : Icons.chevron_right,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? get _subtitle {
    if (!isUnlocked) {
      return previousSkillName == null
          ? 'Locked'
          : 'Unlocks after $previousSkillName';
    }
    if (isCurrent) return 'Continue where you left off';
    if (isCompleted) return 'Finished · tap to revisit';
    return null;
  }

  Widget _buildGlyph() {
    late final IconData icon;
    late final Color color;

    if (!isUnlocked) {
      icon = Icons.lock_outline;
      color = AppColors.textDisabled;
    } else if (isCompleted) {
      icon = Icons.check;
      color = AppColors.textPrimary;
    } else {
      icon = Icons.circle_outlined;
      color = AppColors.textSecondary;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isCompleted ? AppColors.textPrimary : AppColors.border,
        ),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}
