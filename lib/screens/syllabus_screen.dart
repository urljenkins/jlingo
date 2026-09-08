import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cefr_level.dart';
import '../models/course_manifest.dart';
import '../models/skill.dart';
import '../models/user_profile.dart';
import '../providers/course_provider.dart';
import '../providers/progress_provider.dart';
import '../services/alphabet_data.dart';
import '../services/skill_coverage.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'alphabet_screen.dart';
import 'lesson_screen.dart';

/// The course table of contents: every topic, grouped by level, expandable to
/// show what it covers.
///
/// The home screen is a path — it shows where you are and what is next. This
/// is the other view a course needs: the whole thing at once, so a learner
/// can see what they are working towards and jump to the topic they actually
/// want rather than the one that happens to be next.
class SyllabusScreen extends StatefulWidget {
  const SyllabusScreen({super.key});

  @override
  State<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends State<SyllabusScreen> {
  /// Skills loaded so far, by id. A skill file is only read when its row is
  /// expanded: loading all 69 up front to build a contents page would read
  /// the entire course off disk to show a list of names.
  final Map<String, Skill> _loaded = {};

  /// Ids currently being read, so a second tap while the first read is in
  /// flight does not start another.
  final Set<String> _loading = {};

  String? _expanded;

  Future<void> _toggle(String skillId) async {
    if (_expanded == skillId) {
      setState(() => _expanded = null);
      return;
    }

    setState(() => _expanded = skillId);
    if (_loaded.containsKey(skillId) || _loading.contains(skillId)) return;

    setState(() => _loading.add(skillId));
    final skill = await context.read<CourseProvider>().loadSkill(skillId);
    if (!mounted) return;

    setState(() {
      _loading.remove(skillId);
      if (skill != null) _loaded[skillId] = skill;
    });
  }

  /// Starts the lesson directly. The expanded row already shows what the
  /// topic covers, so putting the summary sheet in front of it would be
  /// asking the learner to read the same thing twice.
  Future<void> _start(Skill skill) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => LessonScreen(skill: skill)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = context.watch<CourseProvider>();
    final manifest = courseProvider.currentManifest;
    final completed =
        context.watch<ProgressProvider>().progress?.completedSkills ??
            const <String>{};

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Course contents'),
      ),
      body: manifest == null
          ? const Center(
              child: Text(
                'No course loaded.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : _buildContents(manifest, completed),
    );
  }

  Widget _buildContents(CourseManifest manifest, Set<String> completed) {
    // Same grouping the home screen uses, so the two views agree on where a
    // topic sits in the course.
    final grouped = <LanguageLevel, List<SkillHeader>>{};
    for (final skill in manifest.skills) {
      grouped
          .putIfAbsent(CefrLevel.tierForSkillLevel(skill.level), () => [])
          .add(skill);
    }
    final tiers = CefrLevel.ordered.where(grouped.containsKey).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenInset,
        AppSpacing.lg,
        AppSpacing.screenInset,
        AppSpacing.xxl,
      ),
      children: [
        _buildSummary(manifest, completed),
        if (AlphabetData.hasChart(manifest.id)) ...[
          const SizedBox(height: AppSpacing.lg),
          _buildAlphabetLink(),
        ],
        const SizedBox(height: AppSpacing.xl),
        for (final tier in tiers) ...[
          _buildTierHeading(tier, grouped[tier]!.length),
          const SizedBox(height: AppSpacing.md),
          for (final header in grouped[tier]!)
            _buildSkillRow(header, completed.contains(header.id)),
          const SizedBox(height: AppSpacing.xl),
        ],
      ],
    );
  }

  Widget _buildSummary(CourseManifest manifest, Set<String> completed) {
    final done = manifest.skills.where((s) => completed.contains(s.id)).length;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            manifest.name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$done of ${manifest.skills.length} topics completed',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// The alphabet is reference, not a topic, so it gets its own way in rather
  /// than sitting in the numbered list pretending to be a lesson.
  Widget _buildAlphabetLink() {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AlphabetScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            children: [
              Icon(Icons.abc, color: AppColors.textPrimary),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alphabet & Sounds',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Every letter, with its sound. Tap to hear it.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTierHeading(LanguageLevel tier, int count) {
    return Row(
      children: [
        Text(
          '${CefrLevel.nameFor(tier).toUpperCase()} · '
          '${CefrLevel.codeFor(tier)}',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$count',
          style: const TextStyle(color: AppColors.textDisabled, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSkillRow(SkillHeader header, bool isCompleted) {
    final isExpanded = _expanded == header.id;
    final skill = _loaded[header.id];

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: isExpanded ? AppColors.borderStrong : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.card),
              onTap: () => _toggle(header.id),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Icon(
                      isCompleted ? Icons.check_circle : Icons.circle_outlined,
                      size: 18,
                      color: isCompleted
                          ? AppColors.correct
                          : AppColors.textDisabled,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        header.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: skill == null
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : _buildDetail(skill),
            ),
        ],
      ),
    );
  }

  Widget _buildDetail(Skill skill) {
    final coverage = SkillCoverage.of(skill);
    // Enough to decide whether to open it, not the full contents — that is
    // what the preview sheet is for.
    final preview = coverage.vocabulary.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          skill.description,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        if (preview.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final pair in preview)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    pair.target,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              if (coverage.vocabulary.length > preview.length)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  child: Text(
                    '+${coverage.vocabulary.length - preview.length} more',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Text(
              '${coverage.exerciseCount} '
              '${coverage.exerciseCount == 1 ? 'exercise' : 'exercises'}',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _start(skill),
              child: const Text('Start'),
            ),
          ],
        ),
      ],
    );
  }
}
