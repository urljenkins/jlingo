import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vocabulary_provider.dart';
import '../models/word_of_day.dart';

class WordOfDayScreen extends StatefulWidget {
  const WordOfDayScreen({super.key});

  @override
  State<WordOfDayScreen> createState() => _WordOfDayScreenState();
}

class _WordOfDayScreenState extends State<WordOfDayScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<VocabularyProvider>();
      if (provider.todaysWord == null) {
        provider.loadVocabularyData('default_course');
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Word of the Day'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF00D9FF),
          unselectedLabelColor: Colors.white54,
          indicatorColor: const Color(0xFF00D9FF),
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Saved'),
          ],
        ),
      ),
      body: Consumer<VocabularyProvider>(
        builder: (context, provider, _) {
          if (provider.todaysWord == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTodayTab(provider),
              _buildSavedTab(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTodayTab(VocabularyProvider provider) {
    final word = provider.todaysWord!;
    final isSaved = provider.wordHistory?.hasSavedWord(word.id) ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Main word card
          _buildMainWordCard(word, isSaved, provider),

          const SizedBox(height: 24),

          // Example sentence
          _buildExampleCard(word),

          const SizedBox(height: 16),

          // Additional info
          if (word.etymology != null || word.funFact != null)
            _buildInfoCard(word),

          const SizedBox(height: 24),

          // Action buttons
          _buildActionButtons(word, provider),
        ],
      ),
    );
  }

  Widget _buildMainWordCard(
    WordOfDay word,
    bool isSaved,
    VocabularyProvider provider,
  ) {
    return Card(
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Date badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF00D9FF).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Color(0xFF00D9FF),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(word.date),
                    style: const TextStyle(
                      color: Color(0xFF00D9FF),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Word
            Text(
              word.word,
              style: const TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Pronunciation
            Text(
              word.pronunciation,
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white54,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),

            // Part of speech
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                word.partOfSpeech,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Divider
            Container(
              height: 1,
              width: 60,
              color: Colors.white24,
            ),
            const SizedBox(height: 20),

            // Translation
            Text(
              word.translation,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w500,
                color: Color(0xFF00FF85),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Difficulty
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Difficulty: ',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
                Text(
                  word.difficultyStars,
                  style: const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Save button
            IconButton(
              icon: Icon(
                isSaved ? Icons.bookmark : Icons.bookmark_border,
                color: isSaved ? const Color(0xFFFFD700) : Colors.white54,
                size: 30,
              ),
              onPressed: () {
                provider.toggleSaveWord('default_course', word.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleCard(WordOfDay word) {
    return Card(
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.format_quote,
                  color: Color(0xFF00D9FF),
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Example',
                  style: TextStyle(
                    color: Color(0xFF00D9FF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              word.exampleSentence,
              style: const TextStyle(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              word.exampleTranslation,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white54,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(WordOfDay word) {
    return Card(
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (word.etymology != null) ...[
              const Row(
                children: [
                  Icon(
                    Icons.history_edu,
                    color: Color(0xFFFF9F43),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Etymology',
                    style: TextStyle(
                      color: Color(0xFFFF9F43),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                word.etymology!,
                style: const TextStyle(
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
            ],
            if (word.etymology != null && word.funFact != null)
              const SizedBox(height: 16),
            if (word.funFact != null) ...[
              const Row(
                children: [
                  Icon(
                    Icons.lightbulb,
                    color: Color(0xFFFFD700),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Fun Fact',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                word.funFact!,
                style: const TextStyle(
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(WordOfDay word, VocabularyProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Listen button (placeholder for TTS)
        _buildActionButton(
          icon: Icons.volume_up,
          label: 'Listen',
          color: const Color(0xFF00D9FF),
          onTap: () {
            // TODO: Implement TTS
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Text-to-Speech coming soon!')),
            );
          },
        ),
        const SizedBox(width: 16),
        // Add to flashcards
        _buildActionButton(
          icon: Icons.add_card,
          label: 'Flashcard',
          color: const Color(0xFF00FF85),
          onTap: () {
            // TODO: Add to flashcard deck
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Added to flashcards!')),
            );
          },
        ),
        const SizedBox(width: 16),
        // Share
        _buildActionButton(
          icon: Icons.share,
          label: 'Share',
          color: const Color(0xFFFF9F43),
          onTap: () {
            // TODO: Implement sharing
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Share feature coming soon!')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavedTab(VocabularyProvider provider) {
    final savedWords = provider.savedWords;

    if (savedWords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 80,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            const Text(
              'No saved words yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the bookmark icon to save words',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white38,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: savedWords.length,
      itemBuilder: (context, index) {
        final word = savedWords[index];
        return _buildSavedWordCard(word, provider);
      },
    );
  }

  Widget _buildSavedWordCard(WordOfDay word, VocabularyProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Text(
              word.word,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              word.pronunciation,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              word.translation,
              style: const TextStyle(
                color: Color(0xFF00FF85),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              word.partOfSpeech,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.bookmark, color: Color(0xFFFFD700)),
          onPressed: () {
            provider.toggleSaveWord('default_course', word.id);
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
