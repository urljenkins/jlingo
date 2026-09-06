import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/course_provider.dart';
import '../../services/course_bootstrap.dart';
import '../../models/user_profile.dart';
import '../../widgets/responsive/responsive_layout.dart';
import '../../widgets/responsive/desktop_scaffold.dart';
import '../../widgets/responsive/mobile_scaffold.dart';
import '../app_shell.dart';
import '../../theme/app_colors.dart';

class OnboardingCompleteScreen extends StatelessWidget {
  const OnboardingCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final onboardingProvider = context.watch<OnboardingProvider>();
    final level = onboardingProvider.calculateLevel();

    final bodyContent = SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            _buildSuccessIcon(context),
            const SizedBox(height: 32),
            Text(
              'You\'re all set!',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 32,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Based on your quiz, we\'ve personalized your learning path',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _buildResultsCard(context, onboardingProvider, level),
            const SizedBox(height: 24),
            _buildGoalsCard(context, onboardingProvider),
            const SizedBox(height: 24),
            _buildRecommendationsCard(context, level),
            const SizedBox(height: 40),
            _buildStartButton(context, onboardingProvider),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );

    return ResponsiveLayout(
      mobileScaffold: MobileScaffold(body: bodyContent),
      desktopScaffold: DesktopScaffold(
        sideNav: _buildSideNav(context, onboardingProvider, level),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: bodyContent,
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.celebration,
        size: 80,
        color: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  Widget _buildResultsCard(
    BuildContext context,
    OnboardingProvider provider,
    LanguageLevel level,
  ) {
    final score = provider.correctAnswers;
    final total = provider.quizQuestions.length;
    final percentage = total > 0 ? (score / total * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Your Level',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  Theme.of(context)
                      .colorScheme
                      .secondary
                      .withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              _getLevelDisplayName(level),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatBadge(context, '$score/$total', 'Questions'),
              const SizedBox(width: 24),
              _buildStatBadge(context, '$percentage%', 'Score'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.secondary,
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

  Widget _buildGoalsCard(BuildContext context, OnboardingProvider provider) {
    final goals = provider.profile.goals;
    final dailyMinutes = provider.profile.dailyGoalMinutes;
    final trackingEnabled =
        context.watch<SettingsProvider>().progressTrackingEnabled;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flag,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Your Goals',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: goals.map((goal) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      UserProfile.goalIcon(goal),
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      UserProfile.goalDisplayName(goal),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (trackingEnabled && dailyMinutes != null) ...[
            const SizedBox(height: 16),
            const Divider(color: AppColors.border),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Daily Goal: $dailyMinutes minutes',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard(BuildContext context, LanguageLevel level) {
    final recommendations = _getRecommendations(level);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Recommendations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...recommendations.map((rec) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 18,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rec,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStartButton(BuildContext context, OnboardingProvider provider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _startLearning(context, provider),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Start Learning',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSideNav(
    BuildContext context,
    OnboardingProvider provider,
    LanguageLevel level,
  ) {
    return ColoredBox(
      color: AppColors.surface,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Lingua Sprint',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgressStep(context, 1, 'Welcome', false, true),
                _buildProgressStep(context, 2, 'Level Quiz', false, true),
                _buildProgressStep(context, 3, 'Set Goals', false, true),
                _buildProgressStep(context, 4, 'Start Learning', true, false),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    Theme.of(context)
                        .colorScheme
                        .secondary
                        .withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    provider.selectedLanguage ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getLevelDisplayName(level),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStep(
    BuildContext context,
    int step,
    String label,
    bool isActive,
    bool isCompleted,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted
                  ? Theme.of(context).colorScheme.secondary
                  : isActive
                      ? Theme.of(context).colorScheme.primary
                      : AppColors.border,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, size: 18, color: Colors.black)
                  : Text(
                      '$step',
                      style: TextStyle(
                        color: isActive || isCompleted
                            ? Colors.black
                            : AppColors.textMuted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color:
                  isActive || isCompleted ? Colors.white : AppColors.textMuted,
              fontWeight:
                  isActive || isCompleted ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _getLevelDisplayName(LanguageLevel level) {
    switch (level) {
      case LanguageLevel.beginner:
        return 'Beginner (A1)';
      case LanguageLevel.elementary:
        return 'Elementary (A2)';
      case LanguageLevel.intermediate:
        return 'Intermediate (B1)';
      case LanguageLevel.upperIntermediate:
        return 'Upper Intermediate (B2)';
      case LanguageLevel.advanced:
        return 'Advanced (C1+)';
    }
  }

  List<String> _getRecommendations(LanguageLevel level) {
    switch (level) {
      case LanguageLevel.beginner:
        return [
          'Start with basic vocabulary and common phrases',
          'Focus on listening and pronunciation',
          'Practice daily with flashcards',
          'Don\'t worry about grammar rules yet',
        ];
      case LanguageLevel.elementary:
        return [
          'Build on basic vocabulary with themed lessons',
          'Learn essential grammar patterns',
          'Practice speaking with simple sentences',
          'Try the Picture Dictionary feature',
        ];
      case LanguageLevel.intermediate:
        return [
          'Focus on more complex grammar structures',
          'Read bilingual books to expand vocabulary',
          'Practice listening comprehension daily',
          'Start writing short paragraphs',
        ];
      case LanguageLevel.upperIntermediate:
        return [
          'Challenge yourself with idiomatic expressions',
          'Practice speaking at natural speed',
          'Read longer texts and articles',
          'Focus on nuances and cultural context',
        ];
      case LanguageLevel.advanced:
        return [
          'Master subtle grammar distinctions',
          'Focus on academic and professional vocabulary',
          'Practice with native-level content',
          'Work on accent reduction and fluency',
        ];
    }
  }

  Future<void> _startLearning(
    BuildContext context,
    OnboardingProvider provider,
  ) async {
    // Resolve providers before any async gap.
    final courseProvider = context.read<CourseProvider>();

    // Complete onboarding
    await provider.completeOnboarding();

    // Load the selected course's data so the home screen opens populated.
    final manifest = courseProvider.currentManifest;
    if (manifest != null) {
      if (!context.mounted) return;
      await CourseBootstrap.loadCourseData(context, manifest.id);
    }

    if (!context.mounted) return;

    // Into the shell, not the bare home screen: onboarding clears the stack,
    // so anything else would leave the learner without navigation.
    unawaited(Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (context) => const AppShell()),
      (route) => false,
    ));
  }
}
