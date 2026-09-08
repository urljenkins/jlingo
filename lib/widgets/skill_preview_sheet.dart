import 'package:flutter/material.dart';

import '../models/exercise_type_info.dart';
import '../models/skill.dart';
import '../services/skill_coverage.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// What a topic covers, shown before the learner commits to it.
///
/// Starting a lesson used to be a blind jump: the home row gives a name and
/// nothing else, so there was no way to tell whether a skill was worth the
/// next five minutes or whether it covered words already known. This is the
/// answer to "what is actually in here?".
class SkillPreviewSheet extends StatelessWidget {
  const SkillPreviewSheet({
    super.key,
    required this.skill,
    required this.onStart,
  });

  final Skill skill;
  final VoidCallback onStart;

  /// Opens the sheet, resolving to true when the learner chose to start.
  static Future<bool> show(BuildContext context, Skill skill) async {
    final started = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => SkillPreviewSheet(
        skill: skill,
        onStart: () => Navigator.of(sheetContext).pop(true),
      ),
    );
    return started ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final coverage = SkillCoverage.of(skill);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _buildGrabber(),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenInset,
                  0,
                  AppSpacing.screenInset,
                  AppSpacing.lg,
                ),
                children: [
                  Text(
                    skill.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    skill.description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildFacts(coverage),
                  if (coverage.vocabulary.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    _buildVocabulary(coverage),
                  ],
                  if (coverage.types.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    _buildTypes(coverage),
                  ],
                ],
              ),
            ),
            _buildStartBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildGrabber() => Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      );

  /// The practical facts: how long, and what the lesson will demand of you.
  Widget _buildFacts(SkillCoverage coverage) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _Chip(
          icon: Icons.format_list_numbered,
          label: '${coverage.exerciseCount} '
              '${coverage.exerciseCount == 1 ? 'exercise' : 'exercises'}',
        ),
        if (coverage.vocabulary.isNotEmpty)
          _Chip(
            icon: Icons.style_outlined,
            label: '${coverage.vocabulary.length} words',
          ),
        if (coverage.hasAudio)
          const _Chip(icon: Icons.volume_up_outlined, label: 'Audio'),
        if (coverage.needsMicrophone)
          const _Chip(icon: Icons.mic_none_outlined, label: 'Microphone'),
      ],
    );
  }

  Widget _buildVocabulary(SkillCoverage coverage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Words you will meet'),
        const SizedBox(height: AppSpacing.md),
        for (final pair in coverage.vocabulary)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    pair.target,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    pair.native,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTypes(SkillCoverage coverage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('How you will practise'),
        const SizedBox(height: AppSpacing.md),
        for (final type in coverage.types)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  ExerciseTypeInfo.of(type).icon,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ExerciseTypeInfo.of(type).label,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        ExerciseTypeInfo.of(type).summary,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStartBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenInset,
        AppSpacing.md,
        AppSpacing.screenInset,
        AppSpacing.md + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onStart,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.onAccent,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          ),
          child: const Text('Start lesson'),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.textMuted),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
}
