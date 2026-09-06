import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/user_profile.dart';
import '../../widgets/responsive/responsive_layout.dart';
import '../../widgets/responsive/desktop_scaffold.dart';
import '../../widgets/responsive/mobile_scaffold.dart';
import '../../widgets/hover_card.dart';
import 'onboarding_complete_screen.dart';
import '../../theme/app_colors.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final Set<LearningGoal> _selectedGoals = {};
  int _dailyGoalMinutes = 10;

  @override
  Widget build(BuildContext context) {
    final onboardingProvider = context.watch<OnboardingProvider>();
    final trackingEnabled =
        context.watch<SettingsProvider>().progressTrackingEnabled;

    final bodyContent = SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            const SizedBox(height: 32),
            Text(
              'Why are you learning?',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 28,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Select all that apply',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildGoalsList(context),
            // A daily target is only meaningful when progress tracking is on;
            // with it off the commitment is asked for and never shown again.
            if (trackingEnabled) ...[
              const SizedBox(height: 40),
              Text(
                'Daily Learning Goal',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 24,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'How much time can you dedicate each day?',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildDailyGoalSelector(context),
            ],
            const SizedBox(height: 40),
            _buildContinueButton(context, onboardingProvider),
          ],
        ),
      ),
    );

    return ResponsiveLayout(
      mobileScaffold: MobileScaffold(body: bodyContent),
      desktopScaffold: DesktopScaffold(
        sideNav: _buildSideNav(context, onboardingProvider),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: bodyContent,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        const Spacer(),
        Text(
          'Step 3 of 4',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const Spacer(),
        const SizedBox(width: 48), // Balance the back button
      ],
    );
  }

  Widget _buildGoalsList(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: LearningGoal.values.map((goal) {
        final isSelected = _selectedGoals.contains(goal);
        return _buildGoalCard(context, goal, isSelected);
      }).toList(),
    );
  }

  Widget _buildGoalCard(
      BuildContext context, LearningGoal goal, bool isSelected) {
    return HoverCard(
      onTap: () => _toggleGoal(goal),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
              : null,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : null,
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.3)
                        : AppColors.border,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    UserProfile.goalIcon(goal),
                    size: 28,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : AppColors.textSecondary,
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.black,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              UserProfile.goalDisplayName(goal),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              UserProfile.goalDescription(goal),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyGoalSelector(BuildContext context) {
    final goals = [
      (5, '5 min', 'Casual'),
      (10, '10 min', 'Regular'),
      (15, '15 min', 'Serious'),
      (20, '20 min', 'Intense'),
      (30, '30 min', 'Insane'),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: goals.map((goal) {
        final isSelected = _dailyGoalMinutes == goal.$1;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: HoverCard(
            onTap: () => setState(() => _dailyGoalMinutes = goal.$1),
            child: Container(
              width: 64,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.2)
                    : null,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      )
                    : null,
              ),
              child: Column(
                children: [
                  Text(
                    goal.$2,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    goal.$3,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected
                          ? AppColors.textSecondary
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContinueButton(
      BuildContext context, OnboardingProvider provider) {
    final isValid = _selectedGoals.isNotEmpty;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isValid ? () => _continue(context, provider) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: AppColors.border,
              disabledForegroundColor: AppColors.textDisabled,
            ),
            child: const Text(
              'Continue',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        if (!isValid)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Please select at least one goal',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSideNav(BuildContext context, OnboardingProvider provider) {
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
                _buildProgressStep(context, 3, 'Set Goals', true, false),
                _buildProgressStep(context, 4, 'Start Learning', false, false),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Divider(color: AppColors.border),
                const SizedBox(height: 16),
                Text(
                  'Language: ${provider.selectedLanguage ?? "Not selected"}',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 8),
                Text(
                  'Quiz Score: ${provider.correctAnswers}/${provider.quizQuestions.length}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
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

  void _toggleGoal(LearningGoal goal) {
    setState(() {
      if (_selectedGoals.contains(goal)) {
        _selectedGoals.remove(goal);
      } else {
        _selectedGoals.add(goal);
      }
    });
  }

  Future<void> _continue(
      BuildContext context, OnboardingProvider provider) async {
    await provider.setGoals(_selectedGoals.toList());
    if (context.mounted &&
        context.read<SettingsProvider>().progressTrackingEnabled) {
      await provider.setDailyGoal(_dailyGoalMinutes);
    }

    if (!context.mounted) return;

    unawaited(Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, _, __) => const OnboardingCompleteScreen(),
        transitionDuration: Duration.zero,
      ),
    ));
  }
}
