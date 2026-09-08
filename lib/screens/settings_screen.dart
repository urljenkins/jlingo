import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/cefr_level.dart';
import '../models/exercise.dart';
import '../models/user_profile.dart';
import '../providers/course_provider.dart';
import '../providers/onboarding_provider.dart';
import '../providers/settings_provider.dart';
import 'exercise_types_screen.dart';
import 'onboarding/level_quiz_screen.dart';
import '../utils/build_info.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../services/audio_service.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return ListView(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            children: [
              _buildSectionHeader('Learning & Habits'),
              _buildLevelCard(context),
              const SizedBox(height: 12),
              _buildExerciseTypesCard(context, settings),
              const SizedBox(height: 12),
              Card(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Progress Tracking',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Show streaks, XP, levels and daily targets. Off by '
                    'default — lessons and your place in the course work '
                    'either way.',
                    style: AppTypography.caption,
                  ),
                  secondary: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(
                      Icons.trending_up,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  value: settings.progressTrackingEnabled,
                  onChanged: (value) {
                    unawaited(settings.setProgressTrackingEnabled(value));
                  },
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('Audio & Pronunciation'),
              Card(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceRaised,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: const Icon(
                              Icons.speed,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'TTS Speech Speed',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Adjust how fast spoken exercises and words are pronounced.',
                                  style: AppTypography.caption,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Slow', style: AppTypography.caption),
                          Expanded(
                            child: Slider(
                              value: settings.speechRate,
                              min: 0.2,
                              divisions: 8,
                              label:
                                  '${(settings.speechRate * 2).toStringAsFixed(1)}x',
                              onChanged: (value) {
                                unawaited(settings.setSpeechRate(value));
                                unawaited(AudioService().setSpeechRate(value));
                              },
                            ),
                          ),
                          const Text('Fast', style: AppTypography.caption),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('Notifications'),
              Card(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: SwitchListTile(
                  title: const Text(
                    'Daily Reminders',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    NotificationService().isDeliverySupported
                        ? 'Receive Word of the Day and daily practice '
                            'reminders.'
                        : 'Word of the Day and practice reminders are coming '
                            'soon; your preference is saved for then.',
                    style: AppTypography.caption,
                  ),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceRaised,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  value: settings.notificationsEnabled,
                  onChanged: (value) {
                    unawaited(settings.setNotificationsEnabled(value));
                    unawaited(
                        NotificationService().setNotificationsEnabled(value));
                  },
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('About'),
              Card(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: ListTile(
                  leading: const Icon(Icons.info_outline,
                      color: AppColors.textSecondary),
                  title: const Text('Lingua Sprint',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    BuildInfo.isTracked
                        ? '${BuildInfo.summary}\nBuilt ${BuildInfo.builtAt}'
                        : BuildInfo.summary,
                    style: AppTypography.caption,
                  ),
                  isThreeLine: BuildInfo.isTracked,
                  trailing: BuildInfo.isTracked
                      ? IconButton(
                          icon: const Icon(Icons.copy,
                              size: 18, color: AppColors.textMuted),
                          tooltip: 'Copy build details',
                          onPressed: () => _copyBuildInfo(context),
                        )
                      : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Way in to the exercise catalogue: what each type does, and whether it
  /// appears. Summarised here so the count is visible without opening it.
  Widget _buildExerciseTypesCard(
      BuildContext context, SettingsProvider settings) {
    final language = context.watch<CourseProvider>().currentLanguageCode;
    final enabled =
        ExerciseType.values.length - settings.disabledTypesFor(language).length;
    final total = ExerciseType.values.length;
    final perCourse = settings.hasLanguageOverride(language);

    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: const Icon(Icons.tune, color: AppColors.textSecondary),
        ),
        title: const Text(
          'Exercise types',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          enabled == total
              ? 'All $total kinds are on. See how each one works, or switch '
                  'off the ones that do not suit how you study.'
              : '$enabled of $total on'
                  '${perCourse ? ' for this course' : ''}. Switched-off types '
                  'stay out of lessons; nothing is lost.',
          style: AppTypography.caption,
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
        onTap: () => unawaited(Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const ExerciseTypesScreen(),
          ),
        )),
      ),
    );
  }

  /// Lets the learner say where they are, at any time.
  ///
  /// Deliberately framed as a starting point rather than a verdict: changing
  /// it opens material, never removes it, and nothing already done is lost.
  Widget _buildLevelCard(BuildContext context) {
    final language = context.watch<CourseProvider>().currentLanguageCode;
    final profile = context.watch<OnboardingProvider>().profile;
    final level = profile.levelFor(language);

    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child:
              const Icon(Icons.school_outlined, color: AppColors.textSecondary),
        ),
        title: const Text(
          'Your level',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          language == null
              ? 'Pick a course first — each language keeps its own level.'
              : level == null
                  ? 'Not set — this course starts from the beginning. Change '
                      'it any time; nothing is locked away.'
                  : '${CefrLevel.nameFor(level)} '
                      '(${CefrLevel.codeFor(level)}) — where this course '
                      'opens. Earlier lessons stay available.',
          style: AppTypography.caption,
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
        onTap: language == null
            ? null
            : () => _showLevelPicker(context, level, language),
      ),
    );
  }

  void _showLevelPicker(
      BuildContext context, LanguageLevel? current, String language) {
    final provider = context.read<OnboardingProvider>();
    final skillLevels = context
            .read<CourseProvider>()
            .currentManifest
            ?.skills
            .map((s) => s.level)
            .toList() ??
        const <int>[];

    unawaited(showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
                child: Text(
                  'Where would you like to start? You can change this whenever '
                  'you like, and nothing you have already done goes away.',
                  style: AppTypography.caption,
                ),
              ),
              RadioGroup<LanguageLevel>(
                groupValue: current,
                onChanged: (selected) {
                  Navigator.of(sheetContext).pop();
                  if (selected == null) return;
                  unawaited(provider.setAssessedLevel(selected, language));
                  // Say what changed, and that nothing was taken away — the
                  // reassurance matters most at the moment of choosing.
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Now opening at ${CefrLevel.nameFor(selected)} '
                        '(${CefrLevel.codeFor(selected)}). Earlier lessons are '
                        'still there.',
                      ),
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: CefrLevel.ordered.map((level) {
                    return RadioListTile<LanguageLevel>(
                      value: level,
                      title: Text(
                        '${CefrLevel.nameFor(level)} '
                        '(${CefrLevel.codeFor(level)})',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        CefrLevel.hasContentFor(level, skillLevels)
                            ? CefrLevel.descriptionFor(level)
                            : '${CefrLevel.descriptionFor(level)} — no lessons '
                                'at this level yet for this course',
                        style: AppTypography.caption,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              ListTile(
                leading: const Icon(Icons.quiz_outlined,
                    color: AppColors.textSecondary),
                title: const Text('Not sure? Take a quick check'),
                subtitle: const Text(
                  'A few questions to suggest a level. Optional, and you can '
                  'override the result.',
                  style: AppTypography.caption,
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _startLevelCheck(context);
                },
              ),
            ],
          ),
        );
      },
    ));
  }

  /// Reopens the placement quiz from settings as a retake.
  ///
  /// The questions are keyed off the course being studied, which after a
  /// restart is the only record of which language the quiz should cover.
  void _startLevelCheck(BuildContext context) {
    final provider = context.read<OnboardingProvider>();
    final language = context.read<CourseProvider>().currentLanguageCode;

    provider.restartQuiz(language: language);

    if (provider.quizQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No check available for this course yet — '
              'pick a level directly instead.'),
        ),
      );
      return;
    }

    unawaited(Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const LevelQuizScreen(isRetake: true),
      ),
    ));
  }

  /// Puts the exact build on the clipboard, so a device can be matched to a
  /// branch without reading it off the screen.
  void _copyBuildInfo(BuildContext context) {
    unawaited(Clipboard.setData(
      ClipboardData(
        text: '${BuildInfo.summary} · built ${BuildInfo.builtAt}',
      ),
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Build details copied')),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: AppTypography.sectionLabel,
      ),
    );
  }
}
