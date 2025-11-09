import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/course_provider.dart';
import '../providers/progress_provider.dart';
import 'home_screen.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final courseProvider = context.watch<CourseProvider>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                'Select Language',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Choose the language you want to learn',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 40),
              Expanded(
                child: ListView.builder(
                  itemCount: courseProvider.availableLanguages.length,
                  itemBuilder: (context, index) {
                    final language = courseProvider.availableLanguages[index];
                    return _buildLanguageItem(context, language);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageItem(BuildContext context, String language) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _selectLanguage(context, language),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _getLanguageFlag(language),
                const SizedBox(width: 16),
                Text(
                  _getLanguageName(language),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectLanguage(BuildContext context, String language) async {
    final courseProvider = context.read<CourseProvider>();
    final progressProvider = context.read<ProgressProvider>();

    await courseProvider.loadCourse(language);

    if (courseProvider.currentCourse != null) {
      await progressProvider.loadProgress(courseProvider.currentCourse!.id);

      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, _, __) => const HomeScreen(),
            transitionDuration: Duration.zero,
          ),
        );
      }
    }
  }

  String _getLanguageName(String code) {
    final names = {
      'spanish': 'Spanish',
      'french': 'French',
      'german': 'German',
      'dutch': 'Dutch',
      'portuguese': 'Portuguese',
      'japanese': 'Japanese',
      'chinese': 'Chinese',
    };
    return names[code] ?? code.toUpperCase();
  }

  Widget _getLanguageFlag(String code) {
    final flags = {
      'spanish': '🇪🇸',
      'french': '🇫🇷',
      'german': '🇩🇪',
      'dutch': '🇳🇱',
      'portuguese': '🇵🇹',
      'japanese': '🇯🇵',
      'chinese': '🇨🇳',
    };

    return Text(
      flags[code] ?? '🌍',
      style: const TextStyle(fontSize: 32),
    );
  }
}
