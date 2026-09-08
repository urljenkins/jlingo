import 'dart:async';

import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Opens the walkthrough of how exercises work. Shown once automatically on
/// the first visit to the exercise catalogue, and available from the help
/// icon after that.
Future<void> showExerciseTour(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
    ),
    builder: (_) => const _ExerciseTourSheet(),
  );
}

/// One page of the walkthrough.
class _TourPage {
  const _TourPage({
    required this.icon,
    required this.title,
    required this.body,
    this.footnote,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? footnote;
}

class _ExerciseTourSheet extends StatefulWidget {
  const _ExerciseTourSheet();

  @override
  State<_ExerciseTourSheet> createState() => _ExerciseTourSheetState();
}

class _ExerciseTourSheetState extends State<_ExerciseTourSheet> {
  final PageController _controller = PageController();
  int _page = 0;

  /// Deliberately short. Four pages covering what an exercise is, the four
  /// families they fall into, how switching one off behaves, and where the
  /// per-type detail lives — anything more and it stops being read.
  static final List<_TourPage> _pages = [
    const _TourPage(
      icon: Icons.school_outlined,
      title: 'A lesson is a stack of exercises',
      body: 'Each skill in the course holds a set of exercises, shuffled '
          'fresh every time you open it. You answer one, it tells you '
          'straight away whether you were right, and the next appears. '
          'Reaching the end completes the skill and opens the one after it.',
      footnote: 'Completing a skill does not need a perfect score.',
    ),
    _TourPage(
      icon: Icons.category_outlined,
      title: 'There are ${ExerciseType.values.length} kinds, in four families',
      body: 'Vocabulary and recall types drill individual words. Reading and '
          'writing types work on whole sentences, passages and '
          'conversations. Listening types play speech and ask what you '
          'heard. Speaking types have you say a phrase aloud and check it '
          'with the microphone.',
      footnote: 'Every skill mixes families, so a lesson varies as you go.',
    ),
    const _TourPage(
      icon: Icons.tune_outlined,
      title: 'Switch off what does not suit you',
      body: 'Turning a type off stops it appearing in lessons and removes it '
          'from the filter row on the Learn tab. Nothing is deleted and your '
          'progress is untouched — switch it back on and it returns. Useful '
          'when you study somewhere you cannot speak or listen.',
      footnote: 'At least one type always stays on.',
    ),
    const _TourPage(
      icon: Icons.language_outlined,
      title: 'Globally, or one course at a time',
      body: 'The first tab sets your choices for every course. The second '
          'tab gives the course you are studying its own list, for when a '
          'language you are learning to speak needs different practice from '
          'one you are learning to read.',
      footnote: 'Tap "How it works" on any type for what it actually asks.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _page == _pages.length - 1;

  void _next() {
    if (_isLast) {
      Navigator.of(context).pop();
      return;
    }
    unawaited(_controller.nextPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 260,
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (context, index) => _buildPage(_pages[index]),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                for (var i = 0; i < _pages.length; i++)
                  Container(
                    width: i == _page ? 18 : 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color:
                          i == _page ? AppColors.textPrimary : AppColors.border,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                const Spacer(),
                // Skipping is a first-class choice, not a hidden one — the
                // sheet appears uninvited on the first visit.
                if (!_isLast)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Skip'),
                  ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton(
                  onPressed: _next,
                  child: Text(_isLast ? 'Got it' : 'Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_TourPage page) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(page.icon, color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(page.title, style: AppTypography.title),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(page.body, style: AppTypography.subtitle),
                if (page.footnote != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(page.footnote!, style: AppTypography.caption),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
