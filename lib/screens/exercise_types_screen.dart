import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exercise.dart';
import '../models/exercise_type_info.dart';
import '../providers/course_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/language_display.dart';
import '../widgets/exercise_preview.dart';
import '../widgets/exercise_tour_sheet.dart';

/// The exercise catalogue: what each type asks of you, and a switch to stop
/// it appearing.
///
/// Two scopes share one list. "All courses" edits the global set; the course
/// tab edits an override that only exists once the learner asks for one, so
/// the common case stays a single list rather than nine copies of it.
class ExerciseTypesScreen extends StatefulWidget {
  const ExerciseTypesScreen({super.key});

  @override
  State<ExerciseTypesScreen> createState() => _ExerciseTypesScreenState();
}

class _ExerciseTypesScreenState extends State<ExerciseTypesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  /// Types whose explanation is expanded. Collapsed by default so the list
  /// stays scannable; the tutorial points at the first one.
  final Set<ExerciseType> _expanded = {};

  @override
  void initState() {
    super.initState();
    // First visit gets the walkthrough unprompted — the whole point of the
    // screen is the explanations, and they are behind a tap otherwise.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowTour());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _maybeShowTour() async {
    final settings = context.read<SettingsProvider>();
    if (settings.exerciseTourSeen) return;
    await _showTour();
    if (!mounted) return;
    await settings.setExerciseTourSeen(true);
  }

  Future<void> _showTour() => showExerciseTour(context);

  @override
  Widget build(BuildContext context) {
    final language = context.watch<CourseProvider>().currentLanguageCode;
    final manifest = context.watch<CourseProvider>().currentManifest;
    final courseName = manifest == null
        ? 'This course'
        : LanguageDisplay.name(manifest.targetLanguage);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise types'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'How exercises work',
            onPressed: () => unawaited(_showTour()),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            const Tab(text: 'All courses'),
            Tab(text: courseName),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildScope(language: null),
          language == null
              ? const _NoCourseMessage()
              : _buildScope(language: language, courseName: courseName),
        ],
      ),
    );
  }

  Widget _buildScope({required String? language, String? courseName}) {
    final settings = context.watch<SettingsProvider>();
    final isOverridden = settings.hasLanguageOverride(language);
    final followsGlobal = language != null && !isOverridden;
    final disabled = settings.disabledTypesFor(language);
    final enabledCount = ExerciseType.values.length - disabled.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        _buildScopeHeader(
          language: language,
          courseName: courseName,
          followsGlobal: followsGlobal,
          enabledCount: enabledCount,
        ),
        const SizedBox(height: AppSpacing.lg),
        for (final category in ExerciseCategory.values) ...[
          _buildCategory(
            category: category,
            language: language,
            disabled: disabled,
            readOnly: followsGlobal,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (language == null) _buildResetTile(),
      ],
    );
  }

  /// Explains which list is being edited, and — on the course tab — offers to
  /// break away from the global one.
  Widget _buildScopeHeader({
    required String? language,
    required String? courseName,
    required bool followsGlobal,
    required int enabledCount,
  }) {
    final settings = context.read<SettingsProvider>();

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            language == null
                ? 'These apply to every course.'
                : followsGlobal
                    ? '$courseName follows your global choices.'
                    : '$courseName has its own choices.',
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            language == null
                ? 'Switched-off types stop appearing in lessons and drop out '
                    'of the filter row on the Learn tab. $enabledCount of '
                    '${ExerciseType.values.length} are on.'
                : followsGlobal
                    ? 'Give this course its own list if it should differ — '
                        'speaking drills for a language you are learning to '
                        'talk in, reading only for one you are learning to '
                        'read.'
                    : '$enabledCount of ${ExerciseType.values.length} are on '
                        'for this course. Your global choices are untouched.',
            style: AppTypography.caption,
          ),
          if (language != null) ...[
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: followsGlobal
                  ? OutlinedButton.icon(
                      icon: const Icon(Icons.call_split, size: 18),
                      label: const Text('Customise for this course'),
                      onPressed: () =>
                          unawaited(settings.createLanguageOverride(language)),
                    )
                  : TextButton.icon(
                      icon: const Icon(Icons.settings_backup_restore, size: 18),
                      label: const Text('Follow global settings again'),
                      onPressed: () =>
                          unawaited(settings.clearLanguageOverride(language)),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategory({
    required ExerciseCategory category,
    required String? language,
    required Set<ExerciseType> disabled,
    required bool readOnly,
  }) {
    final infos = ExerciseTypeInfo.inCategory(category);
    final types = infos.map((i) => i.type).toList();
    final allOn = types.every((t) => !disabled.contains(t));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: 6),
          child: Row(
            children: [
              Icon(category.icon, size: 16, color: AppColors.textMuted),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  category.label.toUpperCase(),
                  style: AppTypography.sectionLabel,
                ),
              ),
              // One tap to clear or restore a whole skill area — the common
              // case is "no speaking today", not one type at a time.
              TextButton(
                onPressed: readOnly
                    ? null
                    : () => unawaited(_setCategory(types, !allOn, language)),
                child: Text(allOn ? 'Turn all off' : 'Turn all on'),
              ),
            ],
          ),
        ),
        _Panel(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < infos.length; i++) ...[
                if (i > 0)
                  const Divider(height: 1, color: AppColors.border, indent: 56),
                _buildTypeTile(
                  info: infos[i],
                  language: language,
                  enabled: !disabled.contains(infos[i].type),
                  readOnly: readOnly,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeTile({
    required ExerciseTypeInfo info,
    required String? language,
    required bool enabled,
    required bool readOnly,
  }) {
    final isExpanded = _expanded.contains(info.type);

    return Column(
      children: [
        SwitchListTile(
          value: enabled,
          onChanged:
              readOnly ? null : (value) => _toggle(info, value, language),
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
          title: Row(
            children: [
              Flexible(
                child: Text(
                  info.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: enabled
                        ? AppColors.textPrimary
                        : AppColors.textDisabled,
                  ),
                ),
              ),
              if (info.requiresMicrophone) const _Requirement(label: 'Mic'),
              if (info.requiresAudio) const _Requirement(label: 'Audio'),
            ],
          ),
          subtitle: Text(info.summary, style: AppTypography.caption),
        ),
        // The explanation lives one tap below the switch: available when
        // deciding, out of the way when scanning.
        InkWell(
          onTap: () => setState(() {
            isExpanded ? _expanded.remove(info.type) : _expanded.add(info.type);
          }),
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(56, 0, AppSpacing.lg, AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isExpanded ? 'Hide details' : 'How it works',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  Padding(
                    padding: const EdgeInsets.only(
                        top: AppSpacing.sm, bottom: AppSpacing.xs),
                    child: Text(info.howItWorks, style: AppTypography.subtitle),
                  ),
                  // The description says what it is; this lets you find out
                  // whether you want it. Answering here changes no progress.
                  ExercisePreview(
                    type: info.type,
                    onDisable: readOnly || !enabled
                        ? null
                        : () => _toggle(info, false, language),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResetTile() {
    return _Panel(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.restart_alt, color: AppColors.textSecondary),
        title: const Text(
          'Turn everything back on',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: const Text(
          'Clears your choices here and for every course.',
          style: AppTypography.caption,
        ),
        onTap: () => unawaited(_confirmReset()),
      ),
    );
  }

  Future<void> _toggle(
      ExerciseTypeInfo info, bool enabled, String? language) async {
    final settings = context.read<SettingsProvider>();
    final ok = language == null
        ? await settings.setTypeEnabled(info.type, enabled)
        : await settings.setTypeEnabledForLanguage(
            language, info.type, enabled);

    // The provider refuses to empty the list; say why rather than letting the
    // switch flick back with no explanation.
    if (!ok && mounted) {
      _notify('Keep at least one exercise type on — lessons need something '
          'to draw from.');
    }
  }

  Future<void> _setCategory(
      List<ExerciseType> types, bool enabled, String? language) async {
    final settings = context.read<SettingsProvider>();
    final complete =
        await settings.setTypesEnabled(types, enabled, language: language);
    if (!complete && mounted) {
      _notify('Kept one type on — lessons need something to draw from.');
    }
  }

  Future<void> _confirmReset() async {
    final settings = context.read<SettingsProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Turn everything back on?',
            style: AppTypography.heading),
        content: const Text(
          'Every exercise type returns, and any per-course lists are removed.',
          style: AppTypography.subtitle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Turn all on'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await settings.resetExerciseTypes();
    if (mounted) _notify('All exercise types are back on.');
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Card surface shared by every block on this screen.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

/// Marks a type that needs hardware — a microphone, or sound you can hear.
class _Requirement extends StatelessWidget {
  const _Requirement({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(fontSize: 11),
      ),
    );
  }
}

class _NoCourseMessage extends StatelessWidget {
  const _NoCourseMessage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Text(
          'Pick a course first — per-course choices attach to a language.',
          textAlign: TextAlign.center,
          style: AppTypography.subtitle,
        ),
      ),
    );
  }
}
