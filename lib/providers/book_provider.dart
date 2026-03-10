import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/book.dart';

const _bookProgressKey = 'book_progress_';
const _savedWordsKey = 'saved_vocabulary_words';

class BookProvider extends ChangeNotifier {
  List<BookManifestEntry> _availableBooks = [];
  List<BookManifestEntry> get availableBooks => _availableBooks;

  BilingualBook? _currentBook;
  BilingualBook? get currentBook => _currentBook;

  BookProgress? _currentProgress;
  BookProgress? get currentProgress => _currentProgress;

  int _currentChapterIndex = 0;
  int get currentChapterIndex => _currentChapterIndex;

  int _currentParagraphIndex = 0;
  int get currentParagraphIndex => _currentParagraphIndex;

  bool _showTranslation = true;
  bool get showTranslation => _showTranslation;

  bool _showSideBySide = false;
  bool get showSideBySide => _showSideBySide;

  List<String> _savedWords = [];
  List<String> get savedWords => _savedWords;

  String? _filterLanguage;
  String? get filterLanguage => _filterLanguage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Load available books from assets
  Future<void> loadAvailableBooks() async {
    _isLoading = true;
    notifyListeners();

    try {
      final jsonString =
          await rootBundle.loadString('assets/books/manifest.json');
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final booksList = jsonData['books'] as List<dynamic>;

      _availableBooks = booksList
          .map((e) => BookManifestEntry.fromJson(e as Map<String, dynamic>))
          .toList();

      // Load saved words
      final prefs = await SharedPreferences.getInstance();
      final wordsJson = prefs.getString(_savedWordsKey);
      if (wordsJson != null) {
        _savedWords = List<String>.from(jsonDecode(wordsJson) as List);
      }
    } catch (e) {
      debugPrint('Error loading books manifest: $e');
      _availableBooks = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Filter books by target language
  void setLanguageFilter(String? language) {
    _filterLanguage = language;
    notifyListeners();
  }

  List<BookManifestEntry> get filteredBooks {
    if (_filterLanguage == null) return _availableBooks;
    return _availableBooks
        .where((book) =>
            book.originalLanguage == _filterLanguage ||
            book.translatedLanguage == _filterLanguage)
        .toList();
  }

  /// Load a specific book by ID
  Future<bool> loadBook(String bookId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final jsonString =
          await rootBundle.loadString('assets/books/$bookId.json');
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      _currentBook = BilingualBook.fromJson(jsonData);

      // Load progress for this book
      await _loadBookProgress(bookId);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error loading book $bookId: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Load saved progress for a book
  Future<void> _loadBookProgress(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = prefs.getString('$_bookProgressKey$bookId');

    if (progressJson != null) {
      _currentProgress = BookProgress.fromJson(
          jsonDecode(progressJson) as Map<String, dynamic>);
      _currentChapterIndex =
          _findChapterIndex(_currentProgress!.currentChapterId);
      _currentParagraphIndex = _currentProgress!.currentParagraphIndex;
    } else {
      _currentChapterIndex = 0;
      _currentParagraphIndex = 0;
      _currentProgress = BookProgress(
        bookId: bookId,
        currentChapterId: _currentBook!.chapters.first.id,
        currentParagraphIndex: 0,
        percentComplete: 0.0,
        learnedWords: [],
        lastReadAt: DateTime.now(),
      );
    }
  }

  int _findChapterIndex(String chapterId) {
    if (_currentBook == null) return 0;
    final index = _currentBook!.chapters.indexWhere((ch) => ch.id == chapterId);
    return index >= 0 ? index : 0;
  }

  /// Save current reading progress
  Future<void> _saveProgress() async {
    if (_currentBook == null || _currentProgress == null) return;

    final totalParagraphs = _currentBook!.chapters
        .fold<int>(0, (sum, ch) => sum + ch.paragraphs.length);
    final completedParagraphs = _currentBook!.chapters
            .take(_currentChapterIndex)
            .fold<int>(0, (sum, ch) => sum + ch.paragraphs.length) +
        _currentParagraphIndex;
    final percentComplete = (completedParagraphs / totalParagraphs) * 100;

    _currentProgress = _currentProgress!.copyWith(
      currentChapterId: _currentBook!.chapters[_currentChapterIndex].id,
      currentParagraphIndex: _currentParagraphIndex,
      percentComplete: percentComplete,
      lastReadAt: DateTime.now(),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_bookProgressKey${_currentBook!.id}',
      jsonEncode(_currentProgress!.toJson()),
    );
  }

  /// Navigate to next paragraph
  Future<void> nextParagraph() async {
    if (_currentBook == null) return;

    final currentChapter = _currentBook!.chapters[_currentChapterIndex];
    if (_currentParagraphIndex < currentChapter.paragraphs.length - 1) {
      _currentParagraphIndex++;
    } else if (_currentChapterIndex < _currentBook!.chapters.length - 1) {
      _currentChapterIndex++;
      _currentParagraphIndex = 0;
    }

    await _saveProgress();
    notifyListeners();
  }

  /// Navigate to previous paragraph
  Future<void> previousParagraph() async {
    if (_currentBook == null) return;

    if (_currentParagraphIndex > 0) {
      _currentParagraphIndex--;
    } else if (_currentChapterIndex > 0) {
      _currentChapterIndex--;
      _currentParagraphIndex =
          _currentBook!.chapters[_currentChapterIndex].paragraphs.length - 1;
    }

    await _saveProgress();
    notifyListeners();
  }

  /// Jump to a specific chapter
  Future<void> goToChapter(int chapterIndex) async {
    if (_currentBook == null ||
        chapterIndex < 0 ||
        chapterIndex >= _currentBook!.chapters.length) {
      return;
    }

    _currentChapterIndex = chapterIndex;
    _currentParagraphIndex = 0;
    await _saveProgress();
    notifyListeners();
  }

  /// Get current paragraph
  BilingualParagraph? get currentParagraph {
    if (_currentBook == null) return null;
    final chapter = _currentBook!.chapters[_currentChapterIndex];
    if (_currentParagraphIndex >= chapter.paragraphs.length) return null;
    return chapter.paragraphs[_currentParagraphIndex];
  }

  /// Get current chapter
  BookChapter? get currentChapter {
    if (_currentBook == null) return null;
    return _currentBook!.chapters[_currentChapterIndex];
  }

  /// Toggle translation visibility
  void toggleTranslation() {
    _showTranslation = !_showTranslation;
    notifyListeners();
  }

  /// Toggle side-by-side mode
  void toggleSideBySide() {
    _showSideBySide = !_showSideBySide;
    notifyListeners();
  }

  /// Save a word to vocabulary list
  Future<void> saveWord(String word) async {
    if (!_savedWords.contains(word)) {
      _savedWords.add(word);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_savedWordsKey, jsonEncode(_savedWords));

      // Also update the book progress learned words
      if (_currentProgress != null) {
        final learnedWords = List<String>.from(_currentProgress!.learnedWords);
        if (!learnedWords.contains(word)) {
          learnedWords.add(word);
          _currentProgress =
              _currentProgress!.copyWith(learnedWords: learnedWords);
          await _saveProgress();
        }
      }

      notifyListeners();
    }
  }

  /// Remove a word from vocabulary list
  Future<void> removeWord(String word) async {
    _savedWords.remove(word);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedWordsKey, jsonEncode(_savedWords));
    notifyListeners();
  }

  /// Check if a word is saved
  bool isWordSaved(String word) {
    return _savedWords.contains(word.toLowerCase());
  }

  /// Close current book
  void closeBook() {
    _currentBook = null;
    _currentProgress = null;
    _currentChapterIndex = 0;
    _currentParagraphIndex = 0;
    notifyListeners();
  }

  /// Get progress for a book by ID (for library display)
  Future<BookProgress?> getProgressForBook(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = prefs.getString('$_bookProgressKey$bookId');
    if (progressJson != null) {
      return BookProgress.fromJson(
          jsonDecode(progressJson) as Map<String, dynamic>);
    }
    return null;
  }

  /// Check if user has started reading a book
  bool hasStartedBook(String bookId) {
    // This would need async, so we'll handle it differently in the UI
    return false;
  }
}
