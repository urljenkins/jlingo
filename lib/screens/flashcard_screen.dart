import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/course_provider.dart';
import '../providers/flashcard_provider.dart';
import '../models/flashcard.dart';
import '../theme/app_colors.dart';

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  /// The active course id. Per-course state (reviews, saved words) must be
  /// keyed to it, never to a placeholder, or writes land under a different
  /// key than reads.
  String? get _courseId => context.read<CourseProvider>().currentManifest?.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<FlashcardProvider>();
      final courseId = context.read<CourseProvider>().currentManifest?.id;
      if (provider.decks.isEmpty && courseId != null) {
        unawaited(provider.loadDecks(courseId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(context),
          ),
        ],
      ),
      body: Consumer<FlashcardProvider>(
        builder: (context, provider, _) {
          if (provider.decks.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // If we're in a study session, show the study view
          if (provider.currentDeck != null &&
              provider.sessionCards.isNotEmpty) {
            return _buildStudyView(provider);
          }

          // Otherwise show deck selection
          return _buildDeckList(provider);
        },
      ),
    );
  }

  Widget _buildDeckList(FlashcardProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.decks.length + 1, // +1 for the create button
      itemBuilder: (context, index) {
        if (index == provider.decks.length) {
          return _buildCreateDeckButton();
        }

        final deck = provider.decks[index];
        final stats = deck.stats;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          color: AppColors.surface,
          child: InkWell(
            onTap: () {
              provider.selectDeck(deck.id);
              provider.startStudySession();
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          deck.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildDeckBadge(stats.dueCards, stats.newCards),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    deck.description,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatChip(
                        Icons.schedule,
                        '${stats.dueCards} due',
                        AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        Icons.add_circle_outline,
                        '${stats.newCards} new',
                        AppColors.textPrimary,
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        Icons.check_circle_outline,
                        '${stats.matureCards}/${stats.totalCards}',
                        AppColors.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: stats.retentionRate / 100,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeckBadge(int dueCards, int newCards) {
    final total = dueCards + newCards;
    if (total == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.textSecondary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'Complete!',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$total cards',
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateDeckButton() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border, width: 2),
      ),
      child: InkWell(
        onTap: () => _showCreateDeckDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: AppColors.textMuted),
              SizedBox(width: 8),
              Text(
                'Create New Deck',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudyView(FlashcardProvider provider) {
    final card = provider.currentCard;

    if (card == null || !provider.hasMoreCards) {
      return _buildSessionComplete(provider);
    }

    return Column(
      children: [
        // Progress indicator
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                '${provider.currentCardIndex + 1}/${provider.sessionCards.length}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (provider.currentCardIndex + 1) /
                        provider.sessionCards.length,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.textPrimary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  provider.startStudySession(newCardLimit: 0, reviewLimit: 0);
                },
              ),
            ],
          ),
        ),

        // Flashcard
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (!provider.isShowingAnswer) {
                provider.showAnswer();
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildFlashcard(card, provider.isShowingAnswer),
            ),
          ),
        ),

        // Answer buttons
        if (provider.isShowingAnswer) _buildAnswerButtons(provider, card),
      ],
    );
  }

  Widget _buildFlashcard(Flashcard card, bool showingAnswer) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Card(
        key: ValueKey('${card.id}_$showingAnswer'),
        color: AppColors.surface,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Front of card
              Text(
                card.front,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (card.pronunciation != null) ...[
                const SizedBox(height: 8),
                Text(
                  card.pronunciation!,
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              if (showingAnswer) ...[
                const SizedBox(height: 24),
                Container(
                  height: 1,
                  width: 100,
                  color: AppColors.border,
                ),
                const SizedBox(height: 24),

                // Back of card
                Text(
                  card.back,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                if (card.exampleSentence != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          card.exampleSentence!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (card.exampleTranslation != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            card.exampleTranslation!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ] else ...[
                const SizedBox(height: 48),
                Text(
                  'Tap to reveal',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerButtons(FlashcardProvider provider, Flashcard card) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildAnswerButton(
                'Again',
                AppColors.textSecondary,
                Icons.refresh,
                () {
                  final id = _courseId;
                  if (id != null) provider.answerCard(SRSQuality.again, id);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildAnswerButton(
                'Hard',
                AppColors.textSecondary,
                Icons.trending_down,
                () {
                  final id = _courseId;
                  if (id != null) provider.answerCard(SRSQuality.hard, id);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildAnswerButton(
                'Good',
                AppColors.textPrimary,
                Icons.check,
                () {
                  final id = _courseId;
                  if (id != null) provider.answerCard(SRSQuality.good, id);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildAnswerButton(
                'Easy',
                AppColors.textSecondary,
                Icons.check_circle,
                () {
                  final id = _courseId;
                  if (id != null) provider.answerCard(SRSQuality.easy, id);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerButton(
    String label,
    Color color,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.2),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSessionComplete(FlashcardProvider provider) {
    final accuracy = provider.cardsReviewedToday > 0
        ? (provider.correctAnswersToday / provider.cardsReviewedToday * 100)
            .toStringAsFixed(0)
        : '0';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.celebration,
              size: 80,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 24),
            const Text(
              'Session Complete!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You reviewed ${provider.cardsReviewedToday} cards',
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Accuracy: $accuracy%',
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Time: ${_formatDuration(provider.sessionDuration)}',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                provider.startStudySession(newCardLimit: 0, reviewLimit: 0);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textPrimary,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text('Back to Decks'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showSettings(BuildContext context) {
    unawaited(showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer<FlashcardProvider>(
          builder: (context, provider, _) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SRS Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSettingSlider(
                    'New cards per day',
                    provider.newCardsPerDay.toDouble(),
                    5,
                    50,
                    (value) {
                      provider.updateSettings(newCardsPerDay: value.toInt());
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildSettingSlider(
                    'Review cards per day',
                    provider.reviewCardsPerDay.toDouble(),
                    20,
                    200,
                    (value) {
                      provider.updateSettings(reviewCardsPerDay: value.toInt());
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    ));
  }

  Widget _buildSettingSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(
              value.toInt().toString(),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: AppColors.textPrimary,
          onChanged: onChanged,
        ),
      ],
    );
  }

  void _showCreateDeckDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    unawaited(showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Create New Deck'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Deck Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final manifest = context.read<CourseProvider>().currentManifest;
                if (nameController.text.isNotEmpty && manifest != null) {
                  unawaited(context.read<FlashcardProvider>().createDeck(
                        courseId: manifest.id,
                        name: nameController.text,
                        description: descController.text,
                        targetLanguage: manifest.targetLanguage,
                        nativeLanguage: manifest.nativeLanguage,
                      ));
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textPrimary,
                foregroundColor: Colors.black,
              ),
              child: const Text('Create'),
            ),
          ],
        );
      },
    ));
  }
}
