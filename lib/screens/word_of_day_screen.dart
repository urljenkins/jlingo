import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/course_provider.dart';
import '../providers/vocabulary_provider.dart';
import '../models/word_of_day.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class WordOfDayScreen extends StatefulWidget {
  const WordOfDayScreen({super.key});

  @override
  State<WordOfDayScreen> createState() => _WordOfDayScreenState();
}

class _WordOfDayScreenState extends State<WordOfDayScreen>
    with SingleTickerProviderStateMixin {
  /// The active course id. Per-course state (reviews, saved words) must be
  /// keyed to it, never to a placeholder, or writes land under a different
  /// key than reads.
  String? get _courseId => context.read<CourseProvider>().currentManifest?.id;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<VocabularyProvider>();
      final courseId = context.read<CourseProvider>().currentManifest?.id;
      if (courseId == null) return;
      if (provider.todaysWord == null) {
        provider.loadVocabularyData(courseId);
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.textPrimary,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Saved'),
          ],
        ),
      ),
      body: Consumer<VocabularyProvider>(
        builder: (context, provider, _) {
          if (provider.todaysWord == null) {
            if (!provider.isLoaded) {
              return const Center(child: CircularProgressIndicator());
            }
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.menu_book_outlined,
                        size: 48, color: AppColors.textDisabled),
                    SizedBox(height: 16),
                    Text(
                      'No word of the day for this language yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            );
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
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Date badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(word.date),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
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
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),

            // Part of speech
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                word.partOfSpeech,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Divider
            Container(
              height: 1,
              width: 60,
              color: AppColors.border,
            ),
            const SizedBox(height: 20),

            // Translation
            Text(
              word.translation,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
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
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
                Text(
                  word.difficultyStars,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
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
                color: isSaved ? AppColors.textPrimary : AppColors.textMuted,
                size: 30,
              ),
              onPressed: () {
                final id = _courseId;
                if (id != null) provider.toggleSaveWord(id, word.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleCard(WordOfDay word) {
    return Card(
      color: AppColors.surface,
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
                  color: AppColors.textPrimary,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Example',
                  style: TextStyle(
                    color: AppColors.textPrimary,
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
                color: AppColors.textMuted,
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
      color: AppColors.surface,
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
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Etymology',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                word.etymology!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
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
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Fun Fact',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                word.funFact!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
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
          color: AppColors.textPrimary,
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
          color: AppColors.textSecondary,
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
          color: AppColors.textSecondary,
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
      color: AppColors.surfaceRaised,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
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
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 80,
              color: AppColors.textDisabled,
            ),
            SizedBox(height: 16),
            Text(
              'No saved words yet',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textMuted,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the bookmark icon to save words',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textDisabled,
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
      color: AppColors.surface,
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
                color: AppColors.textMuted,
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
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              word.partOfSpeech,
              style: const TextStyle(
                color: AppColors.textDisabled,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.bookmark, color: AppColors.textPrimary),
          onPressed: () {
            final id = _courseId;
            if (id != null) provider.toggleSaveWord(id, word.id);
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
