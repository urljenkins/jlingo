import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/course_provider.dart';
import '../providers/vocabulary_provider.dart';
import '../models/picture_dictionary.dart';
import '../theme/app_colors.dart';

class PictureDictionaryScreen extends StatefulWidget {
  const PictureDictionaryScreen({super.key});

  @override
  State<PictureDictionaryScreen> createState() =>
      _PictureDictionaryScreenState();
}

class _PictureDictionaryScreenState extends State<PictureDictionaryScreen> {
  /// The active course id. Per-course state (reviews, saved words) must be
  /// keyed to it, never to a placeholder, or writes land under a different
  /// key than reads.
  String? get _courseId => context.read<CourseProvider>().currentManifest?.id;

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<VocabularyProvider>();
      final courseId = context.read<CourseProvider>().currentManifest?.id;
      if (courseId == null) return;
      if (provider.pictureDictionary == null) {
        provider.loadVocabularyData(courseId);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Consumer<VocabularyProvider>(
        builder: (context, provider, _) {
          if (provider.pictureDictionary == null) {
            if (!provider.isLoaded) {
              return const Center(child: CircularProgressIndicator());
            }
            return const _VocabularyEmptyState(
              icon: Icons.photo_library_outlined,
              message: 'No picture dictionary for this language yet.',
            );
          }

          // If searching, show search results
          if (_isSearching && _searchController.text.isNotEmpty) {
            return _buildSearchResults(provider);
          }

          // If viewing a topic, show topic entries
          if (provider.currentTopic != null) {
            return _buildTopicView(provider);
          }

          // Otherwise show topic grid
          return _buildTopicGrid(provider);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search words...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: AppColors.textMuted),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (value) {
                context.read<VocabularyProvider>().setSearchQuery(value);
              },
            )
          : const Text('Picture Dictionary'),
      leading: Consumer<VocabularyProvider>(
        builder: (context, provider, _) {
          if (_isSearching || provider.currentTopic != null) {
            return IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (_isSearching) {
                  setState(() {
                    _isSearching = false;
                    _searchController.clear();
                  });
                  provider.setSearchQuery('');
                } else {
                  provider.selectTopic('');
                  // Reset currentTopic by reloading
                  if (_courseId != null) {
                    provider.loadVocabularyData(_courseId!);
                  }
                }
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
      actions: [
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchController.clear();
                context.read<VocabularyProvider>().setSearchQuery('');
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildTopicGrid(VocabularyProvider provider) {
    final dictionary = provider.pictureDictionary!;

    return Column(
      children: [
        // Header stats
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.textPrimary, AppColors.textSecondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.category,
                value: '${dictionary.topics.length}',
                label: 'Topics',
              ),
              _buildStatItem(
                icon: Icons.library_books,
                value: '${dictionary.totalWords}',
                label: 'Words',
              ),
              _buildStatItem(
                icon: Icons.check_circle,
                value: '${provider.pictureProgress?.masteredWords.length ?? 0}',
                label: 'Learned',
              ),
            ],
          ),
        ),

        // Topics grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: dictionary.topics.length,
            itemBuilder: (context, index) {
              final topic = dictionary.topics[index];
              return _buildTopicCard(topic, provider);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.black87, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTopicCard(
    PictureDictionaryTopic topic,
    VocabularyProvider provider,
  ) {
    final progress = provider.pictureProgress;
    final progressPercent = progress?.getTopicProgressPercent(
          topic.id,
          topic.entries.length,
        ) ??
        0;

    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => provider.selectTopic(topic.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Topic icon/image area
            Expanded(
              flex: 3,
              child: ColoredBox(
                color: _getTopicColor(topic.id).withValues(alpha: 0.2),
                child: Center(
                  child: Icon(
                    _getTopicIcon(topic.iconName),
                    size: 60,
                    color: _getTopicColor(topic.id),
                  ),
                ),
              ),
            ),
            // Topic info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${topic.entries.length} words',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(topic.difficulty)
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            topic.difficultyText,
                            style: TextStyle(
                              color: _getDifficultyColor(topic.difficulty),
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progressPercent / 100,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.textSecondary,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicView(VocabularyProvider provider) {
    final topic = provider.currentTopic!;

    return Column(
      children: [
        // Topic header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _getTopicColor(topic.id).withValues(alpha: 0.1),
          ),
          child: Column(
            children: [
              Icon(
                _getTopicIcon(topic.iconName),
                size: 48,
                color: _getTopicColor(topic.id),
              ),
              const SizedBox(height: 12),
              Text(
                topic.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                topic.description,
                style: const TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '${topic.entries.length} words',
                style: TextStyle(
                  color: _getTopicColor(topic.id),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Entries list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: topic.entries.length,
            itemBuilder: (context, index) {
              final entry = topic.entries[index];
              return _buildEntryCard(entry, topic.id, provider);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEntryCard(
    PictureDictionaryEntry entry,
    String topicId,
    VocabularyProvider provider,
  ) {
    final isLearned =
        provider.pictureProgress?.hasLearnedWord(entry.id) ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showEntryDetail(entry, topicId, provider),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Image placeholder
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.image,
                  color: AppColors.textDisabled,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (entry.article != null) ...[
                          Text(
                            entry.article!,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          entry.word,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.pronunciation,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entry.translation,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              // Learned indicator
              IconButton(
                icon: Icon(
                  isLearned ? Icons.check_circle : Icons.check_circle_outline,
                  color: isLearned
                      ? AppColors.textSecondary
                      : Colors.white.withValues(alpha: 0.3),
                  size: 28,
                ),
                onPressed: () {
                  final id = _courseId;
                  if (!isLearned && id != null) {
                    provider.markWordAsLearned(
                      id,
                      topicId,
                      entry.id,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Learned: ${entry.word}'),
                        backgroundColor: AppColors.textSecondary,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEntryDetail(
    PictureDictionaryEntry entry,
    String topicId,
    VocabularyProvider provider,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Image placeholder
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.image,
                      color: AppColors.textDisabled,
                      size: 80,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Word with article
                  Text(
                    entry.fullWord,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.pronunciation,
                    style: const TextStyle(
                      fontSize: 20,
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Translation
                  Text(
                    entry.translation,
                    style: const TextStyle(
                      fontSize: 28,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Additional info
                  if (entry.pluralForm != null) ...[
                    _buildInfoRow('Plural', entry.pluralForm!),
                  ],
                  if (entry.usageNote != null) ...[
                    _buildInfoRow('Note', entry.usageNote!),
                  ],
                  if (entry.relatedWords.isNotEmpty) ...[
                    _buildInfoRow('Related', entry.relatedWords.join(', ')),
                  ],

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implement TTS
                        },
                        icon: const Icon(Icons.volume_up),
                        label: const Text('Listen'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.textPrimary,
                          foregroundColor: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          final id = _courseId;
                          if (id != null) {
                            provider.markWordAsLearned(
                              id,
                              topicId,
                              entry.id,
                            );
                          }
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Mark Learned'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.textSecondary,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(VocabularyProvider provider) {
    final results = provider.searchResults;

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            const Text(
              'No words found',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final entry = results[index];
        return _buildEntryCard(entry, '', provider);
      },
    );
  }

  IconData _getTopicIcon(String iconName) {
    switch (iconName) {
      case 'kitchen':
        return Icons.kitchen;
      case 'home':
        return Icons.home;
      case 'restaurant':
        return Icons.restaurant;
      case 'directions_car':
        return Icons.directions_car;
      case 'accessibility_new':
        return Icons.accessibility_new;
      default:
        return Icons.category;
    }
  }

  Color _getTopicColor(String topicId) {
    switch (topicId) {
      case 'topic_kitchen':
        return AppColors.textSecondary;
      case 'topic_home':
        return const Color(0xFF4ECDC4);
      case 'topic_food':
        return AppColors.textSecondary;
      case 'topic_transport':
        return AppColors.textPrimary;
      case 'topic_body':
        return AppColors.textSecondary;
      default:
        return AppColors.textPrimary;
    }
  }

  Color _getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1:
        return AppColors.textSecondary;
      case 2:
        return AppColors.textPrimary;
      case 3:
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }
}

class _VocabularyEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _VocabularyEmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textDisabled),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
