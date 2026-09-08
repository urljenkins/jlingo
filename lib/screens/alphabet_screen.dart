import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/alphabet.dart';
import '../providers/course_provider.dart';
import '../services/alphabet_data.dart';
import '../services/audio_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// The alphabet chart: every letter, tappable to hear it, with its phonetic
/// spelling on the tile.
///
/// This is reference rather than exercise. The alphabet skill tested letters
/// through multiple choice without ever showing the alphabet, which is the
/// wrong way round — you cannot be quizzed on a chart you have never seen.
class AlphabetScreen extends StatefulWidget {
  const AlphabetScreen({super.key});

  @override
  State<AlphabetScreen> createState() => _AlphabetScreenState();
}

class _AlphabetScreenState extends State<AlphabetScreen> {
  final AudioService _audio = AudioService();

  /// The letter currently expanded. Only one at a time: the detail panel is
  /// tall enough that several open at once would bury the chart.
  String? _selected;

  @override
  void dispose() {
    // The screen is leaving; a letter still being spoken should not outlive
    // it and talk over whatever the learner opens next.
    unawaited(_audio.stop());
    super.dispose();
  }

  Future<void> _speak(LetterSound letter, String languageCode) async {
    setState(() => _selected = letter.letter);
    // Stop first: tapping along a row faster than the voice can finish would
    // otherwise queue every letter and play them all after the fact.
    await _audio.stop();
    await _audio.speak(letter.name, language: languageCode);
  }

  @override
  Widget build(BuildContext context) {
    final courseId = context.watch<CourseProvider>().currentManifest?.id;
    final alphabet = courseId == null ? null : AlphabetData.forCourse(courseId);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Alphabet & Sounds'),
      ),
      body: alphabet == null ? _buildUnavailable() : _buildChart(alphabet),
    );
  }

  Widget _buildUnavailable() => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'No alphabet chart for this course yet.',
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );

  Widget _buildChart(Alphabet alphabet) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenInset),
      children: [
        if (alphabet.note != null) ...[
          _buildIntro(alphabet.note!),
          const SizedBox(height: AppSpacing.xl),
        ],
        for (final section in alphabet.sections) ...[
          _buildSection(section, alphabet.languageCode),
          const SizedBox(height: AppSpacing.xl),
        ],
      ],
    );
  }

  Widget _buildIntro(String note) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          note,
          style: const TextStyle(
            color: AppColors.textSecondary,
            height: 1.5,
            fontSize: 14,
          ),
        ),
      );

  Widget _buildSection(AlphabetSection section, String languageCode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (section.subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            section.subtitle!,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        _buildGrid(section, languageCode),
        // The detail for a letter in this section sits directly beneath its
        // own grid, so the explanation is next to the tile that opened it.
        ..._buildDetailFor(section, languageCode),
      ],
    );
  }

  Widget _buildGrid(AlphabetSection section, String languageCode) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Tiles are sized rather than counted, so the grid stays legible from
        // a narrow phone to a desktop window instead of stretching four
        // columns across a wide screen.
        const target = 92.0;
        final columns = (constraints.maxWidth / target).floor().clamp(3, 8);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: section.letters.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, index) {
            final letter = section.letters[index];
            return _LetterTile(
              letter: letter,
              isSelected: _selected == letter.letter,
              onTap: () => _speak(letter, languageCode),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildDetailFor(AlphabetSection section, String languageCode) {
    final letter =
        section.letters.where((l) => l.letter == _selected).firstOrNull;
    if (letter == null) return const [];

    return [
      const SizedBox(height: AppSpacing.md),
      _LetterDetail(
        letter: letter,
        onReplay: () => _speak(letter, languageCode),
        onSpeakExample: letter.example == null
            ? null
            : () async {
                await _audio.stop();
                await _audio.speak(letter.example!, language: languageCode);
              },
      ),
    ];
  }
}

/// One tappable letter: the glyph, and its phonetic spelling beneath.
class _LetterTile extends StatelessWidget {
  const _LetterTile({
    required this.letter,
    required this.isSelected,
    required this.onTap,
  });

  final LetterSound letter;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      // Without this the screen reader announces a bare glyph and an IPA
      // string, which is unreadable aloud.
      label: '${letter.letter}, pronounced ${letter.name}. '
          '${letter.soundHint}',
      excludeSemantics: true,
      child: Material(
        color: isSelected ? AppColors.accent : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(
                color: isSelected ? AppColors.accent : AppColors.border,
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: FittedBox(
                    child: Text(
                      letter.letter,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.onAccent
                            : AppColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  letter.ipa,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.onAccent.withValues(alpha: 0.7)
                        : AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The expanded panel for the selected letter.
class _LetterDetail extends StatelessWidget {
  const _LetterDetail({
    required this.letter,
    required this.onReplay,
    this.onSpeakExample,
  });

  final LetterSound letter;
  final VoidCallback onReplay;
  final VoidCallback? onSpeakExample;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                letter.letter,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      letter.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      letter.ipa,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onReplay,
                icon: const Icon(Icons.volume_up, color: AppColors.textPrimary),
                tooltip: 'Hear the letter',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            letter.soundHint,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          if (letter.example != null) ...[
            const SizedBox(height: AppSpacing.md),
            InkWell(
              onTap: onSpeakExample,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    const Icon(
                      Icons.play_circle_outline,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        letter.exampleMeaning == null
                            ? letter.example!
                            : '${letter.example!} — ${letter.exampleMeaning}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (letter.note != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceSunken,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                letter.note!,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
