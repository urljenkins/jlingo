import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exercise.dart';
import '../models/exercise_type_info.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Per-topic exercise conditions, reached by long-pressing a topic on the
/// Learn tab. Tapping the topic starts it on the course default; this is the
/// way to say "for this one topic, only listening" without touching the
/// course-wide list.
///
/// The sheet edits an override that exists only once the learner asks for
/// one. "Reset to default" removes it again.
class SkillExerciseTypesSheet extends StatelessWidget {
  const SkillExerciseTypesSheet({
    super.key,
    required this.skillId,
    required this.skillName,
    this.language,
  });

  final String skillId;
  final String skillName;
  final String? language;

  static Future<void> show(
    BuildContext context, {
    required String skillId,
    required String skillName,
    String? language,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SkillExerciseTypesSheet(
        skillId: skillId,
        skillName: skillName,
        language: language,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final disabled =
        settings.disabledTypesForSkill(skillId, language: language);
    final isConfigured = settings.hasSkillOverride(skillId);
    final enabledCount = ExerciseType.values.length - disabled.length;

    final currentDrillLength = settings.drillLengthForSkill(skillId);

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
            _grabber(),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenInset,
                  0,
                  AppSpacing.screenInset,
                  AppSpacing.xxl,
                ),
                children: [
                  Text(skillName, style: AppTypography.heading),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    isConfigured
                        ? '$enabledCount of ${ExerciseType.values.length} '
                            'exercise types · $currentDrillLength exercises per drill. Reset to '
                            'default to follow your course settings again.'
                        : 'This topic follows your course settings ($currentDrillLength exercises per drill). Customize '
                            'types and drill size up to 100 exercises.',
                    style: AppTypography.caption,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _sectionLabel('DRILL SIZE', Icons.tune),
                  _panel(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Exercises per session',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceRaised,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              '$currentDrillLength exercises',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Slider(
                        value: currentDrillLength.toDouble(),
                        min: 5,
                        max: 100,
                        divisions: 19, // 5, 10, 15, ... 100 (steps of 5)
                        label: '$currentDrillLength',
                        activeColor: AppColors.textPrimary,
                        inactiveColor: AppColors.surfaceRaised,
                        onChanged: (val) {
                          context
                              .read<SettingsProvider>()
                              .setDrillLengthForSkill(skillId, val.round());
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          for (final count in const [5, 12, 25, 50, 100])
                            ChoiceChip(
                              label: Text('$count'),
                              selected: currentDrillLength == count,
                              onSelected: (_) {
                                context
                                    .read<SettingsProvider>()
                                    .setDrillLengthForSkill(skillId, count);
                              },
                              selectedColor: AppColors.textPrimary,
                              labelStyle: TextStyle(
                                fontSize: 11,
                                color: currentDrillLength == count
                                    ? AppColors.surface
                                    : AppColors.textMuted,
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  for (final category in ExerciseCategory.values) ...[
                    _categoryLabel(category),
                    _panel(
                      children: [
                        for (var i = 0;
                            i < ExerciseTypeInfo.inCategory(category).length;
                            i++) ...[
                          if (i > 0)
                            const Divider(
                                height: 1, color: AppColors.border, indent: 56),
                          _tile(
                            context,
                            info: ExerciseTypeInfo.inCategory(category)[i],
                            enabled: !disabled.contains(
                              ExerciseTypeInfo.inCategory(category)[i].type,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (isConfigured)
                    _panel(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.settings_backup_restore,
                            color: AppColors.textSecondary,
                          ),
                          title: const Text(
                            'Reset to default',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text(
                            'Follow your course settings for this topic again.',
                            style: AppTypography.caption,
                          ),
                          onTap: () {
                            unawaited(context
                                .read<SettingsProvider>()
                                .clearSkillOverride(skillId));
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    BuildContext context, {
    required ExerciseTypeInfo info,
    required bool enabled,
  }) {
    return SwitchListTile(
      value: enabled,
      onChanged: (value) async {
        final ok = await context
            .read<SettingsProvider>()
            .setTypeEnabledForSkill(skillId, info.type, value,
                language: language);
        if (!ok && context.mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(const SnackBar(
              content: Text('Keep at least one exercise type on for this '
                  'topic — the lesson needs something to draw from.'),
            ));
        }
      },
      secondary: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(
          info.icon,
          size: 20,
          color: enabled ? AppColors.textSecondary : AppColors.textDisabled,
        ),
      ),
      title: Text(
        info.label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: enabled ? AppColors.textPrimary : AppColors.textDisabled,
        ),
      ),
      subtitle: Text(info.summary, style: AppTypography.caption),
    );
  }

  Widget _sectionLabel(String label, IconData icon) => Padding(
        padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textMuted),
            const SizedBox(width: AppSpacing.sm),
            Text(label.toUpperCase(), style: AppTypography.sectionLabel),
          ],
        ),
      );

  Widget _categoryLabel(ExerciseCategory category) =>
      _sectionLabel(category.label, category.icon);

  Widget _panel({
    required List<Widget> children,
    EdgeInsets padding = EdgeInsets.zero,
  }) =>
      Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: children),
      );

  Widget _grabber() => Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      );
}
