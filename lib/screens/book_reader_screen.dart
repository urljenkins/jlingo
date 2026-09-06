import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/book_provider.dart';
import '../models/book.dart';
import '../theme/app_colors.dart';

class BookReaderScreen extends StatefulWidget {
  const BookReaderScreen({super.key});

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showChapterList = false;
  double _fontSize = 18.0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookProvider>(
      builder: (context, provider, child) {
        final book = provider.currentBook;
        if (book == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(provider, book),
          body: Stack(
            children: [
              _buildReaderContent(provider, book),
              if (_showChapterList) _buildChapterOverlay(provider, book),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(provider, book),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BookProvider provider, BilingualBook book) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          provider.closeBook();
          Navigator.of(context).pop();
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            book.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            provider.currentChapter?.title ?? '',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            provider.showSideBySide ? Icons.view_agenda : Icons.view_column,
          ),
          onPressed: provider.toggleSideBySide,
          tooltip: provider.showSideBySide ? 'Stacked View' : 'Side by Side',
        ),
        IconButton(
          icon: Icon(
            provider.showTranslation ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: provider.toggleTranslation,
          tooltip: provider.showTranslation
              ? 'Hide Translation'
              : 'Show Translation',
        ),
        IconButton(
          icon: const Icon(Icons.format_size),
          onPressed: _showFontSizeDialog,
          tooltip: 'Font Size',
        ),
        IconButton(
          icon: const Icon(Icons.list),
          onPressed: () => setState(() => _showChapterList = !_showChapterList),
          tooltip: 'Chapters',
        ),
      ],
    );
  }

  Widget _buildReaderContent(BookProvider provider, BilingualBook book) {
    final paragraph = provider.currentParagraph;
    if (paragraph == null) {
      return const Center(child: Text('No content available'));
    }

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -100) {
            unawaited(provider.nextParagraph());
          } else if (details.primaryVelocity! > 100) {
            unawaited(provider.previousParagraph());
          }
        }
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        child: provider.showSideBySide
            ? _buildSideBySideView(provider, paragraph)
            : _buildStackedView(provider, paragraph),
      ),
    );
  }

  Widget _buildStackedView(
      BookProvider provider, BilingualParagraph paragraph) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Original text
        _buildTextBlock(
          text: paragraph.originalText,
          language: provider.currentBook!.originalLanguage,
          isOriginal: true,
          provider: provider,
        ),
        if (provider.showTranslation) ...[
          const SizedBox(height: 24),
          const Divider(color: AppColors.border),
          const SizedBox(height: 24),
          // Translation
          _buildTextBlock(
            text: paragraph.translatedText,
            language: provider.currentBook!.translatedLanguage,
            isOriginal: false,
            provider: provider,
          ),
        ],
        const SizedBox(height: 40),
        _buildVocabularySection(paragraph.vocabularyWords, provider),
      ],
    );
  }

  Widget _buildSideBySideView(
      BookProvider provider, BilingualParagraph paragraph) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Original text
        Expanded(
          child: _buildTextBlock(
            text: paragraph.originalText,
            language: provider.currentBook!.originalLanguage,
            isOriginal: true,
            provider: provider,
          ),
        ),
        if (provider.showTranslation) ...[
          const SizedBox(width: 24),
          Container(
            width: 1,
            height: 300,
            color: AppColors.border,
          ),
          const SizedBox(width: 24),
          // Translation
          Expanded(
            child: _buildTextBlock(
              text: paragraph.translatedText,
              language: provider.currentBook!.translatedLanguage,
              isOriginal: false,
              provider: provider,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextBlock({
    required String text,
    required String language,
    required bool isOriginal,
    required BookProvider provider,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Language label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isOriginal
                ? AppColors.textPrimary.withValues(alpha: 0.2)
                : AppColors.textSecondary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            language.toUpperCase(),
            style: TextStyle(
              color:
                  isOriginal ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Selectable text with word tap
        _buildSelectableText(text, isOriginal, provider),
      ],
    );
  }

  Widget _buildSelectableText(
      String text, bool isOriginal, BookProvider provider) {
    final words = text.split(RegExp(r'(\s+)'));

    return Wrap(
      children: words.map((word) {
        final cleanWord = word.replaceAll(RegExp(r'[^\w\s]'), '').toLowerCase();
        final isSaved = provider.isWordSaved(cleanWord);
        final isWhitespace = word.trim().isEmpty;

        if (isWhitespace) {
          return Text(
            word,
            style: TextStyle(
              fontSize: _fontSize,
              height: 1.6,
              color: Colors.white,
            ),
          );
        }

        return GestureDetector(
          onTap: () => _showWordDialog(word, cleanWord, provider),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            decoration: isSaved
                ? BoxDecoration(
                    color: AppColors.textPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  )
                : null,
            child: Text(
              word,
              style: TextStyle(
                fontSize: _fontSize,
                height: 1.6,
                color: isSaved ? AppColors.textPrimary : Colors.white,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showWordDialog(String word, String cleanWord, BookProvider provider) {
    final isSaved = provider.isWordSaved(cleanWord);

    unawaited(showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          word,
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSaved
                  ? 'This word is saved to your vocabulary'
                  : 'Save this word to learn later?',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (isSaved) {
                unawaited(provider.removeWord(cleanWord));
              } else {
                unawaited(provider.saveWord(cleanWord));
              }
              Navigator.pop(context);
            },
            child: Text(isSaved ? 'Remove' : 'Save'),
          ),
        ],
      ),
    ));
  }

  Widget _buildVocabularySection(
      List<String> vocabularyWords, BookProvider provider) {
    if (vocabularyWords.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(color: AppColors.border),
        const SizedBox(height: 16),
        Text(
          'Key Vocabulary',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: vocabularyWords.map((word) {
            final isSaved = provider.isWordSaved(word.toLowerCase());
            return GestureDetector(
              onTap: () {
                if (isSaved) {
                  unawaited(provider.removeWord(word.toLowerCase()));
                } else {
                  unawaited(provider.saveWord(word.toLowerCase()));
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSaved
                      ? AppColors.textPrimary.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSaved
                        ? AppColors.textPrimary
                        : Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      word,
                      style: TextStyle(
                        color: isSaved ? AppColors.textPrimary : Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      size: 16,
                      color:
                          isSaved ? AppColors.textPrimary : AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildChapterOverlay(BookProvider provider, BilingualBook book) {
    return GestureDetector(
      onTap: () => setState(() => _showChapterList = false),
      child: ColoredBox(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chapters',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: book.chapters.length,
                    itemBuilder: (context, index) {
                      final chapter = book.chapters[index];
                      final isCurrentChapter =
                          index == provider.currentChapterIndex;
                      return ListTile(
                        leading: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isCurrentChapter
                                ? AppColors.textPrimary
                                : Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isCurrentChapter
                                    ? Colors.black
                                    : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          chapter.title,
                          style: TextStyle(
                            color: isCurrentChapter
                                ? AppColors.textPrimary
                                : Colors.white,
                            fontWeight: isCurrentChapter
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: chapter.translatedTitle != null
                            ? Text(
                                chapter.translatedTitle!,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 12,
                                ),
                              )
                            : null,
                        onTap: () {
                          unawaited(provider.goToChapter(index));
                          setState(() => _showChapterList = false);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BookProvider provider, BilingualBook book) {
    final chapter = provider.currentChapter;
    if (chapter == null) return const SizedBox.shrink();

    final totalParagraphs = chapter.paragraphs.length;
    final currentParagraph = provider.currentParagraphIndex + 1;
    final progress = provider.currentProgress?.percentComplete ?? 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous button
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 32),
                  onPressed: provider.currentChapterIndex == 0 &&
                          provider.currentParagraphIndex == 0
                      ? null
                      : () => provider.previousParagraph(),
                  color: Colors.white,
                  disabledColor: AppColors.border,
                ),
                // Progress info
                Column(
                  children: [
                    Text(
                      'Paragraph $currentParagraph of $totalParagraphs',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${progress.toStringAsFixed(0)}% complete',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                // Next button
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 32),
                  onPressed: provider.currentChapterIndex ==
                              book.chapters.length - 1 &&
                          provider.currentParagraphIndex ==
                              chapter.paragraphs.length - 1
                      ? null
                      : () => provider.nextParagraph(),
                  color: Colors.white,
                  disabledColor: AppColors.border,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFontSizeDialog() {
    unawaited(showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Font Size',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Aa',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _fontSize,
                ),
              ),
              const SizedBox(height: 16),
              Slider(
                value: _fontSize,
                min: 14,
                max: 28,
                divisions: 7,
                label: _fontSize.toStringAsFixed(0),
                onChanged: (value) {
                  setDialogState(() {
                    setState(() {
                      _fontSize = value;
                    });
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    ));
  }
}
