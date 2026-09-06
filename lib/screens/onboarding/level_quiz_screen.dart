import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/responsive/responsive_layout.dart';
import '../../widgets/responsive/desktop_scaffold.dart';
import '../../widgets/responsive/mobile_scaffold.dart';
import '../../widgets/hover_card.dart';
import 'goals_screen.dart';
import '../../theme/app_colors.dart';

class LevelQuizScreen extends StatefulWidget {
  const LevelQuizScreen({super.key, this.isRetake = false});

  /// When true the quiz was opened from settings rather than onboarding: it
  /// saves the level and pops back instead of continuing into goal selection.
  final bool isRetake;

  @override
  State<LevelQuizScreen> createState() => _LevelQuizScreenState();
}

class _LevelQuizScreenState extends State<LevelQuizScreen> {
  int? _selectedAnswer;
  bool _showFeedback = false;
  bool _isCorrect = false;

  @override
  Widget build(BuildContext context) {
    final onboardingProvider = context.watch<OnboardingProvider>();
    final currentQuestion = onboardingProvider.currentQuestion;

    // Quiz is complete: a retake saves the result and returns to settings,
    // otherwise onboarding continues into goal selection.
    if (onboardingProvider.isQuizComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.isRetake) {
          final language = onboardingProvider.selectedLanguage;
          if (language != null) {
            unawaited(onboardingProvider.setAssessedLevel(
                onboardingProvider.calculateLevel(), language));
          }
          Navigator.of(context).pop();
          return;
        }
        unawaited(Navigator.of(context).pushReplacement(
          PageRouteBuilder<void>(
            pageBuilder: (context, _, __) => const GoalsScreen(),
            transitionDuration: Duration.zero,
          ),
        ));
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final progress = (onboardingProvider.currentQuestionIndex + 1) /
        onboardingProvider.quizQuestions.length;

    final bodyContent = SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, onboardingProvider),
            const SizedBox(height: 16),
            _buildProgressBar(context, progress),
            const SizedBox(height: 32),
            if (currentQuestion != null) ...[
              _buildDifficultyBadge(context, currentQuestion.difficulty),
              const SizedBox(height: 16),
              Text(
                currentQuestion.question,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 24,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: _buildOptions(context, currentQuestion),
              ),
            ],
            if (_showFeedback) _buildFeedback(context),
            const SizedBox(height: 16),
            _buildSkipButton(context, onboardingProvider),
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

  Widget _buildHeader(BuildContext context, OnboardingProvider provider) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        const Spacer(),
        Text(
          'Question ${provider.currentQuestionIndex + 1} of ${provider.quizQuestions.length}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const Spacer(),
        Text(
          '${provider.correctAnswers} ✓',
          style: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(BuildContext context, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyBadge(
      BuildContext context, QuizDifficulty difficulty) {
    final (color, label) = switch (difficulty) {
      QuizDifficulty.beginner => (Colors.green, 'Beginner (A1)'),
      QuizDifficulty.elementary => (Colors.lightGreen, 'Elementary (A2)'),
      QuizDifficulty.intermediate => (Colors.orange, 'Intermediate (B1)'),
      QuizDifficulty.upperIntermediate => (
          Colors.deepOrange,
          'Upper Int. (B2)'
        ),
      QuizDifficulty.advanced => (Colors.red, 'Advanced (C1)'),
    };

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildOptions(BuildContext context, QuizQuestion question) {
    return ListView.separated(
      itemCount: question.options.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final isSelected = _selectedAnswer == index;
        final isCorrect = index == question.correctIndex;

        Color? backgroundColor;
        Color? borderColor;

        if (_showFeedback) {
          if (isCorrect) {
            backgroundColor =
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2);
            borderColor = Theme.of(context).colorScheme.secondary;
          } else if (isSelected && !isCorrect) {
            backgroundColor =
                Theme.of(context).colorScheme.error.withValues(alpha: 0.2);
            borderColor = Theme.of(context).colorScheme.error;
          }
        } else if (isSelected) {
          backgroundColor =
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.2);
          borderColor = Theme.of(context).colorScheme.primary;
        }

        return HoverCard(
          onTap: _showFeedback ? null : () => _selectAnswer(context, index),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: borderColor != null
                  ? Border.all(color: borderColor, width: 2)
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : AppColors.border,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + index), // A, B, C, D
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    question.options[index],
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
                if (_showFeedback && isCorrect)
                  Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                if (_showFeedback && isSelected && !isCorrect)
                  Icon(
                    Icons.cancel,
                    color: Theme.of(context).colorScheme.error,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeedback(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isCorrect
            ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            _isCorrect ? Icons.check_circle : Icons.info,
            color: _isCorrect
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isCorrect ? 'Correct! Great job!' : 'Not quite. Keep learning!',
              style: TextStyle(
                color: _isCorrect
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkipButton(BuildContext context, OnboardingProvider provider) {
    return TextButton(
      onPressed: () {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder<void>(
            pageBuilder: (context, _, __) => const GoalsScreen(),
            transitionDuration: Duration.zero,
          ),
        );
      },
      child: Text(
        'Skip quiz & start as beginner',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
        ),
      ),
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
                _buildProgressStep(context, 2, 'Level Quiz', true, false),
                _buildProgressStep(context, 3, 'Set Goals', false, false),
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
                  'Score: ${provider.correctAnswers}/${provider.currentQuestionIndex}',
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

  void _selectAnswer(BuildContext context, int index) {
    final provider = context.read<OnboardingProvider>();
    final currentQuestion = provider.currentQuestion;

    if (currentQuestion == null) return;

    setState(() {
      _selectedAnswer = index;
      _showFeedback = true;
      _isCorrect = index == currentQuestion.correctIndex;
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;

      provider.answerQuestion(index);

      setState(() {
        _selectedAnswer = null;
        _showFeedback = false;
        _isCorrect = false;
      });
    });
  }
}
