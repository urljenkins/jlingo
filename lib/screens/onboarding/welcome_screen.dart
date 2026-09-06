import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/course_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../widgets/responsive/responsive_layout.dart';
import '../../widgets/responsive/desktop_scaffold.dart';
import '../../widgets/responsive/mobile_scaffold.dart';
import '../../widgets/hover_card.dart';
import 'level_quiz_screen.dart';
import '../../theme/app_colors.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bodyContent = SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Spacer(),
            _buildLogo(context),
            const SizedBox(height: 32),
            Text(
              'Welcome to\nLingua Sprint',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 36,
                    height: 1.2,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Learn languages faster with personalized lessons',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            _buildFeatureList(context),
            const Spacer(),
            _buildLanguageSelection(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );

    return ResponsiveLayout(
      mobileScaffold: MobileScaffold(body: bodyContent),
      desktopScaffold: DesktopScaffold(
        sideNav: _buildSideNav(context),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: bodyContent,
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
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
        Icons.language,
        size: 80,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildFeatureList(BuildContext context) {
    final features = [
      ('🎯', 'Personalized to your level'),
      ('⚡', 'Quick 5-minute lessons'),
      ('🏆', 'Track your progress'),
      ('🗣️', 'Speaking & listening practice'),
    ];

    return Column(
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                feature.$1,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Text(
                feature.$2,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLanguageSelection(BuildContext context) {
    final courseProvider = context.watch<CourseProvider>();

    return Column(
      children: [
        Text(
          'What language do you want to learn?',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: courseProvider.availableLanguages.map((language) {
            return _buildLanguageChip(context, language);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLanguageChip(BuildContext context, String language) {
    return HoverCard(
      onTap: () => _selectLanguage(context, language),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getLanguageFlag(language),
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 8),
            Text(
              _getLanguageName(language),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideNav(BuildContext context) {
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
                _buildProgressStep(context, 1, 'Welcome', true),
                _buildProgressStep(context, 2, 'Level Quiz', false),
                _buildProgressStep(context, 3, 'Set Goals', false),
                _buildProgressStep(context, 4, 'Start Learning', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStep(
      BuildContext context, int step, String label, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : AppColors.border,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: TextStyle(
                  color: isActive ? Colors.black : AppColors.textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : AppColors.textMuted,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _selectLanguage(BuildContext context, String language) {
    final onboardingProvider = context.read<OnboardingProvider>();
    final courseProvider = context.read<CourseProvider>();

    onboardingProvider.setSelectedLanguage(language);
    courseProvider.loadCourse(language);

    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (context, _, __) => const LevelQuizScreen(),
        transitionDuration: Duration.zero,
      ),
    );
  }

  String _getLanguageFlag(String language) {
    switch (language.toLowerCase()) {
      case 'spanish':
        return '🇪🇸';
      case 'french':
        return '🇫🇷';
      case 'portuguese':
        return '🇵🇹';
      case 'portuguese_br':
        return '🇧🇷';
      case 'dutch':
        return '🇳🇱';
      case 'japanese':
        return '🇯🇵';
      case 'chinese':
        return '🇨🇳';
      default:
        return '🌍';
    }
  }

  String _getLanguageName(String language) {
    switch (language.toLowerCase()) {
      case 'spanish':
        return 'Spanish';
      case 'french':
        return 'French';
      case 'portuguese':
        return 'Portuguese';
      case 'portuguese_br':
        return 'Brazilian Portuguese';
      case 'dutch':
        return 'Dutch';
      case 'japanese':
        return 'Japanese';
      case 'chinese':
        return 'Chinese';
      default:
        return language;
    }
  }
}
