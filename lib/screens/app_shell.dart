import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/course_provider.dart';
import '../providers/onboarding_provider.dart';
import '../providers/settings_provider.dart';
import '../services/course_bootstrap.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/responsive/responsive_layout.dart';
import 'book_library_screen.dart';
import 'flashcard_screen.dart';
import 'home_screen.dart';
import 'language_selection_screen.dart';
import 'onboarding/welcome_screen.dart';
import 'settings_screen.dart';
import 'vocabulary_screen.dart';

/// Top-level destinations. Each is a tab rather than a pushed route, so the
/// navigation stays on screen and every tab keeps its own scroll position.
enum AppTab {
  learn(Icons.school_outlined, 'Learn'),
  practice(Icons.style_outlined, 'Practice'),
  read(Icons.menu_book_outlined, 'Read'),
  words(Icons.translate_outlined, 'Words'),
  settings(Icons.settings_outlined, 'Settings');

  const AppTab(this.icon, this.label);

  final IconData icon;
  final String label;
}

/// Owns the persistent navigation and hosts the tab bodies. Lessons and other
/// detail screens are pushed above this shell and legitimately cover it.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppTab _current = AppTab.learn;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // ignore: discarded_futures
    _bootstrap();
  }

  /// Runs above the tabs: a learner without a course is sent to onboarding or
  /// language selection before any navigation is drawn.
  Future<void> _bootstrap() async {
    final courseProvider = context.read<CourseProvider>();
    final onboardingProvider = context.read<OnboardingProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    await Future.wait([
      courseProvider.loadAvailableLanguages(),
      settingsProvider.loadSettings(),
    ]);

    if (!mounted) return;
    await CourseBootstrap.restoreSavedCourse(context);
    if (!mounted) return;

    if (courseProvider.currentManifest != null) {
      setState(() => _isLoading = false);
      return;
    }

    // First-time learners go through onboarding, which picks a language
    // itself; returning ones go straight back to language selection.
    await onboardingProvider.loadProfile();
    if (!mounted) return;

    final Widget next = onboardingProvider.isOnboardingComplete
        ? const LanguageSelectionScreen()
        : const WelcomeScreen();

    // ignore: unawaited_futures
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (context) => next),
    );
  }

  void _select(AppTab tab) {
    if (tab == _current) return;
    setState(() => _current = tab);
  }

  Future<bool> _confirmExit() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text('Leave the app?', style: AppTypography.heading),
        content: const Text(
          'Your progress in this course is saved.',
          style: AppTypography.subtitle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay', style: AppTypography.label),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Leave',
              style: AppTypography.label.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );

    return shouldExit ?? false;
  }

  Future<void> _onPopInvoked(bool didPop, Object? result) async {
    if (didPop) return;

    // Back from a inner tab returns to Learn rather than leaving; only Learn
    // itself asks about closing the app.
    if (_current != AppTab.learn) {
      _select(AppTab.learn);
      return;
    }

    if (await _confirmExit()) {
      await SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final body = IndexedStack(
      index: _current.index,
      children: const [
        HomeScreen(),
        FlashcardScreen(),
        BookLibraryScreen(),
        VocabularyScreen(),
        SettingsScreen(),
      ],
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onPopInvoked,
      child: ResponsiveLayout(
        mobileScaffold: Scaffold(
          body: body,
          bottomNavigationBar: _BottomNav(
            current: _current,
            onSelect: _select,
          ),
        ),
        desktopScaffold: Scaffold(
          body: Row(
            children: [
              _SideNav(current: _current, onSelect: _select),
              const VerticalDivider(width: 1),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.current, required this.onSelect});

  final AppTab current;
  final ValueChanged<AppTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfaceSunken,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              for (final tab in AppTab.values)
                Expanded(
                  child: _NavItem(
                    tab: tab,
                    isActive: tab == current,
                    onTap: () => onSelect(tab),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  final AppTab tab;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.textPrimary : AppColors.textMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tab.icon, size: 22, color: color),
            const SizedBox(height: AppSpacing.xs),
            Text(
              tab.label,
              style: AppTypography.caption.copyWith(
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideNav extends StatelessWidget {
  const _SideNav({required this.current, required this.onSelect});

  final AppTab current;
  final ValueChanged<AppTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: ColoredBox(
        color: AppColors.surfaceSunken,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Text('Lingua Sprint', style: AppTypography.heading),
              ),
              for (final tab in AppTab.values)
                _SideNavTile(
                  tab: tab,
                  isActive: tab == current,
                  onTap: () => onSelect(tab),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideNavTile extends StatelessWidget {
  const _SideNavTile({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  final AppTab tab;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.textPrimary : AppColors.textMuted;

    return ListTile(
      leading: Icon(tab.icon, color: color, size: 20),
      title: Text(
        tab.label,
        style: AppTypography.body.copyWith(
          color: color,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      selected: isActive,
      selectedTileColor: AppColors.surface,
      onTap: onTap,
    );
  }
}
