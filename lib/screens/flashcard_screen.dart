import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/flashcard_provider.dart';
import '../models/flashcard.dart';

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<FlashcardProvider>();
      if (provider.decks.isEmpty) {
        // Load decks with a default course ID - this should come from CourseProvider
        provider.loadDecks('default_course');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
          color: const Color(0xFF1A1A1A),
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
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatChip(
                        Icons.schedule,
                        '${stats.dueCards} due',
                        const Color(0xFFFF4757),
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        Icons.add_circle_outline,
                        '${stats.newCards} new',
                        const Color(0xFF00D9FF),
                      ),
                      const SizedBox(width: 8),
                      _buildStatChip(
                        Icons.check_circle_outline,
                        '${stats.matureCards}/${stats.totalCards}',
                        const Color(0xFF00FF85),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: stats.retentionRate / 100,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF00FF85)),
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
          color: const Color(0xFF00FF85).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'Complete!',
          style: TextStyle(
            color: Color(0xFF00FF85),
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF00D9FF).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$total cards',
        style: const TextStyle(
          color: Color(0xFF00D9FF),
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
        side: const BorderSide(color: Colors.white24, width: 2),
      ),
      child: InkWell(
        onTap: () => _showCreateDeckDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: Colors.white54),
              SizedBox(width: 8),
              Text(
                'Create New Deck',
                style: TextStyle(
                  color: Colors.white54,
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
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (provider.currentCardIndex + 1) /
                        provider.sessionCards.length,
                    backgroundColor: Colors.white12,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFF00D9FF)),
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
        color: const Color(0xFF1A1A1A),
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
                    color: Colors.white54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              if (showingAnswer) ...[
                const SizedBox(height: 24),
                Container(
                  height: 1,
                  width: 100,
                  color: Colors.white24,
                ),
                const SizedBox(height: 24),

                // Back of card
                Text(
                  card.back,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF00FF85),
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
                              color: Colors.white54,
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
                const Color(0xFFFF4757),
                Icons.refresh,
                () => provider.answerCard(SRSQuality.again, 'default_course'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildAnswerButton(
                'Hard',
                const Color(0xFFFF9F43),
                Icons.trending_down,
                () => provider.answerCard(SRSQuality.hard, 'default_course'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildAnswerButton(
                'Good',
                const Color(0xFF00D9FF),
                Icons.check,
                () => provider.answerCard(SRSQuality.good, 'default_course'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildAnswerButton(
                'Easy',
                const Color(0xFF00FF85),
                Icons.check_circle,
                () => provider.answerCard(SRSQuality.easy, 'default_course'),
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
              color: Color(0xFF00FF85),
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
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Accuracy: $accuracy%',
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF00D9FF),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Time: ${_formatDuration(provider.sessionDuration)}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                provider.startStudySession(newCardLimit: 0, reviewLimit: 0);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D9FF),
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
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
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
    );
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
                color: Color(0xFF00D9FF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: const Color(0xFF00D9FF),
          onChanged: onChanged,
        ),
      ],
    );
  }

  void _showCreateDeckDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
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
                if (nameController.text.isNotEmpty) {
                  context.read<FlashcardProvider>().createDeck(
                        courseId: 'default_course',
                        name: nameController.text,
                        description: descController.text,
                        targetLanguage: 'target',
                        nativeLanguage: 'native',
                      );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D9FF),
                foregroundColor: Colors.black,
              ),
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}
