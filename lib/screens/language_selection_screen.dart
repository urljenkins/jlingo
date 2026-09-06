import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/course_provider.dart';
import '../services/course_bootstrap.dart';
import 'app_shell.dart';
import '../widgets/responsive/responsive_layout.dart';
import '../widgets/responsive/desktop_scaffold.dart';
import '../widgets/responsive/mobile_scaffold.dart';
import '../widgets/hover_card.dart';
import '../theme/app_colors.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final courseProvider = context.watch<CourseProvider>();

    final bodyContent = Padding(
      padding: const EdgeInsets.all(12.0),
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
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: courseProvider.availableLanguages.length,
              itemBuilder: (context, index) {
                final language = courseProvider.availableLanguages[index];
                return _buildLanguageItem(context, language);
              },
            ),
          ),
        ],
      ),
    );

    return ResponsiveLayout(
      mobileScaffold: MobileScaffold(
        body: bodyContent,
      ),
      desktopScaffold: DesktopScaffold(
        sideNav: ColoredBox(
          color: AppColors.surface,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  'Lingua Sprint',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Home'),
                onTap: () => Navigator.of(context).pop(),
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Languages'),
                onTap: () {},
                selected: true,
                selectedColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
        body: bodyContent,
      ),
    );
  }

  Widget _buildLanguageItem(BuildContext context, String language) {
    return HoverCard(
      onTap: () => _selectLanguage(context, language),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getLanguageIcon(language),
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  _getLanguageFlag(language),
                  style: const TextStyle(fontSize: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _getLanguageName(language),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectLanguage(BuildContext context, String language) async {
    // Loads every per-course provider, not just progress, so switching
    // language does not leave gamification or vocabulary on the old course.
    final loaded = await CourseBootstrap.selectLanguage(context, language);

    if (loaded && context.mounted) {
      // This screen sits above the shell, which rebuilds on the new course.
      // Popping keeps the persistent navigation intact; replacing would
      // discard it.
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        unawaited(Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (context) => const AppShell()),
        ));
      }
    }
  }

  String _getLanguageName(String code) {
    final names = {
      'spanish': 'Spanish (Spain)',
      'spanish_latam': 'Spanish (Latin America)',
      'french': 'French',
      'german': 'German',
      'dutch': 'Dutch',
      'portuguese': 'Portuguese',
      'japanese': 'Japanese',
      'chinese': 'Chinese',
    };
    return names[code] ?? code.toUpperCase();
  }

  IconData _getLanguageIcon(String code) {
    final icons = {
      'spanish': Icons.castle, // Historical heritage / Spain
      'spanish_latam': Icons.public, // Americas / Global Latin America
      'french': Icons.palette, // Art/Eiffel (Palette for art)
      'german': Icons.directions_car, // Engineering/Cars
      'dutch': Icons.wb_sunny, // Windmills (Sun for fields)
      'portuguese': Icons.beach_access, // Beaches
      'japanese': Icons.architecture, // Temples
      'chinese': Icons.translate, // Calligraphy
    };
    return icons[code] ?? Icons.language;
  }

  String _getLanguageFlag(String code) {
    final flags = {
      'spanish': '🇪🇸',
      'spanish_latam': '🇲🇽',
      'french': '🇫🇷',
      'german': '🇩🇪',
      'dutch': '🇳🇱',
      'portuguese': '🇵🇹',
      'japanese': '🇯🇵',
      'chinese': '🇨🇳',
    };

    return flags[code] ?? '🌍';
  }
}
