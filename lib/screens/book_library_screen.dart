import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import '../models/book.dart';
import 'book_reader_screen.dart';
import '../theme/app_colors.dart';

class BookLibraryScreen extends StatefulWidget {
  const BookLibraryScreen({super.key});

  @override
  State<BookLibraryScreen> createState() => _BookLibraryScreenState();
}

class _BookLibraryScreenState extends State<BookLibraryScreen> {
  String? _selectedDifficulty;
  final Map<String, double> _bookProgress = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadBooks());
    });
  }

  Future<void> _loadBooks() async {
    final provider = context.read<BookProvider>();
    await provider.loadAvailableBooks();
    await _loadAllProgress();
  }

  Future<void> _loadAllProgress() async {
    final provider = context.read<BookProvider>();
    for (final book in provider.availableBooks) {
      final progress = await provider.getProgressForBook(book.id);
      if (progress != null) {
        setState(() {
          _bookProgress[book.id] = progress.percentComplete;
        });
      }
    }
  }

  List<BookManifestEntry> _getFilteredBooks(List<BookManifestEntry> books) {
    if (_selectedDifficulty == null) return books;
    return books.where((b) => b.difficulty == _selectedDifficulty).toList();
  }

  Future<void> _openBook(BookManifestEntry entry) async {
    final provider = context.read<BookProvider>();
    final success = await provider.loadBook(entry.id);

    if (mounted && success) {
      unawaited(Navigator.of(context).push(
        PageRouteBuilder<void>(
          pageBuilder: (context, _, __) => const BookReaderScreen(),
          transitionDuration: Duration.zero,
        ),
      ));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading book')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: _showSavedWords,
            tooltip: 'Saved Words',
          ),
        ],
      ),
      body: Consumer<BookProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.availableBooks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No books available',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            );
          }

          final filteredBooks = _getFilteredBooks(provider.filteredBooks);

          return Column(
            children: [
              _buildFilterBar(),
              Expanded(
                child: _buildBookGrid(filteredBooks),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildFilterChip('All', null),
          const SizedBox(width: 8),
          _buildFilterChip('Beginner', 'beginner'),
          const SizedBox(width: 8),
          _buildFilterChip('Intermediate', 'intermediate'),
          const SizedBox(width: 8),
          _buildFilterChip('Advanced', 'advanced'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? difficulty) {
    final isSelected = _selectedDifficulty == difficulty;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedDifficulty = selected ? difficulty : null;
        });
      },
      selectedColor: AppColors.textPrimary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white,
      ),
    );
  }

  Widget _buildBookGrid(List<BookManifestEntry> books) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1024
            ? 4
            : constraints.maxWidth > 600
                ? 3
                : 2;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.65,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: books.length,
          itemBuilder: (context, index) {
            return _buildBookCard(books[index]);
          },
        );
      },
    );
  }

  Widget _buildBookCard(BookManifestEntry book) {
    final progress = _bookProgress[book.id] ?? 0.0;
    final hasProgress = progress > 0;

    return GestureDetector(
      onTap: () => _openBook(book),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Book cover placeholder
            Expanded(
              flex: 3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _getDifficultyColor(book.difficulty)
                      .withValues(alpha: 0.2),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.menu_book,
                        size: 48,
                        color: _getDifficultyColor(book.difficulty),
                      ),
                    ),
                    // Language badges
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Row(
                        children: [
                          _buildLanguageBadge(book.originalLanguage),
                          const SizedBox(width: 4),
                          const Icon(Icons.swap_horiz,
                              size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          _buildLanguageBadge(book.translatedLanguage),
                        ],
                      ),
                    ),
                    // Difficulty badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(book.difficulty),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          book.difficulty.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Book info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.article_outlined,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${book.totalWords} words',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    if (hasProgress) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress / 100,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${progress.toStringAsFixed(0)}% complete',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageBadge(String language) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _getLanguageCode(language),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getLanguageCode(String language) {
    final codes = {
      'english': 'EN',
      'spanish': 'ES',
      'french': 'FR',
      'german': 'DE',
      'italian': 'IT',
      'portuguese': 'PT',
      'dutch': 'NL',
      'japanese': 'JA',
      'chinese': 'ZH',
    };
    return codes[language.toLowerCase()] ??
        language.substring(0, 2).toUpperCase();
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return AppColors.textSecondary;
      case 'intermediate':
        return AppColors.textPrimary;
      case 'advanced':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  void _showSavedWords() {
    final provider = context.read<BookProvider>();
    unawaited(showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Saved Words',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${provider.savedWords.length} words',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (provider.savedWords.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.bookmark_border,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No saved words yet',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap on words while reading to save them',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: provider.savedWords.length,
                    itemBuilder: (context, index) {
                      final word = provider.savedWords[index];
                      return ListTile(
                        title: Text(
                          word,
                          style: const TextStyle(color: Colors.white),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.textMuted),
                          onPressed: () {
                            provider.removeWord(word);
                            if (mounted) {
                              Navigator.pop(context);
                              _showSavedWords();
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    ));
  }
}
