import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/word_of_day.dart';
import '../models/picture_dictionary.dart';

class VocabularyProvider extends ChangeNotifier {
  // Word of the Day
  WordOfDay? _todaysWord;
  List<WordOfDay> _wordArchive = [];
  WordOfDayHistory? _wordHistory;

  // Picture Dictionary
  PictureDictionary? _pictureDictionary;
  PictureDictionaryProgress? _pictureProgress;
  PictureDictionaryTopic? _currentTopic;
  String _searchQuery = '';
  bool _isLoaded = false;

  // Getters
  /// True once a load attempt has finished, so screens can tell "still
  /// loading" apart from "this course has no vocabulary authored yet".
  bool get isLoaded => _isLoaded;
  WordOfDay? get todaysWord => _todaysWord;
  List<WordOfDay> get wordArchive => _wordArchive;
  WordOfDayHistory? get wordHistory => _wordHistory;
  PictureDictionary? get pictureDictionary => _pictureDictionary;
  PictureDictionaryProgress? get pictureProgress => _pictureProgress;
  PictureDictionaryTopic? get currentTopic => _currentTopic;
  String get searchQuery => _searchQuery;

  List<PictureDictionaryEntry> get searchResults {
    if (_searchQuery.isEmpty || _pictureDictionary == null) return [];
    return _pictureDictionary!.searchEntries(_searchQuery);
  }

  Future<void> loadVocabularyData(String courseId) async {
    _isLoaded = false;
    await Future.wait([
      _loadWordOfDay(courseId),
      _loadPictureDictionary(courseId),
    ]);
    _isLoaded = true;
    notifyListeners();
  }

  // ==================== Word of the Day ====================

  Future<void> _loadWordOfDay(String courseId) async {
    final prefs = await SharedPreferences.getInstance();

    // Load word archive
    final archiveJson = prefs.getString('word_archive_$courseId');
    if (archiveJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(archiveJson) as List<dynamic>;
        _wordArchive = decoded
            .map((w) => WordOfDay.fromJson(w as Map<String, dynamic>))
            .toList();
      } catch (e) {
        // Corrupt or old-format data must not brick startup.
        debugPrint('Error loading word archive for $courseId: $e');
        _wordArchive = await _bundledWordArchive(courseId);
        await _saveWordArchive(courseId);
      }
    } else {
      _wordArchive = await _bundledWordArchive(courseId);
      await _saveWordArchive(courseId);
    }

    // Load word history
    final historyJson = prefs.getString('word_history_$courseId');
    if (historyJson != null) {
      try {
        _wordHistory = WordOfDayHistory.fromJson(
            jsonDecode(historyJson) as Map<String, dynamic>);
      } catch (e) {
        debugPrint('Error loading word history for $courseId: $e');
        _wordHistory = WordOfDayHistory(courseId: courseId);
      }
    } else {
      _wordHistory = WordOfDayHistory(courseId: courseId);
    }

    // Get today's word
    _todaysWord = _getWordForToday();
  }

  WordOfDay _getWordForToday() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year)).inDays;

    // Use day of year to cycle through archive
    final index = dayOfYear % _wordArchive.length;
    return _wordArchive[index].copyWith(date: now);
  }

  Future<void> _saveWordArchive(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'word_archive_$courseId',
      jsonEncode(_wordArchive.map((w) => w.toJson()).toList()),
    );
  }

  Future<void> _saveWordHistory(String courseId) async {
    if (_wordHistory == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'word_history_$courseId',
      jsonEncode(_wordHistory!.toJson()),
    );
  }

  Future<void> markWordAsViewed(String courseId, String wordId) async {
    if (_wordHistory == null) return;

    if (!_wordHistory!.hasViewedWord(wordId)) {
      _wordHistory = _wordHistory!.copyWith(
        viewedWordIds: [..._wordHistory!.viewedWordIds, wordId],
        lastViewedDate: DateTime.now(),
      );
      await _saveWordHistory(courseId);
      notifyListeners();
    }
  }

  Future<void> toggleSaveWord(String courseId, String wordId) async {
    if (_wordHistory == null) return;

    List<String> newSavedIds;
    if (_wordHistory!.hasSavedWord(wordId)) {
      newSavedIds =
          _wordHistory!.savedWordIds.where((id) => id != wordId).toList();
    } else {
      newSavedIds = [..._wordHistory!.savedWordIds, wordId];
    }

    _wordHistory = _wordHistory!.copyWith(savedWordIds: newSavedIds);
    await _saveWordHistory(courseId);
    notifyListeners();
  }

  List<WordOfDay> get savedWords {
    if (_wordHistory == null) return [];
    return _wordArchive.where((w) => _wordHistory!.hasSavedWord(w.id)).toList();
  }

  // ==================== Picture Dictionary ====================

  Future<void> _loadPictureDictionary(String courseId) async {
    final prefs = await SharedPreferences.getInstance();

    // Load dictionary (or use sample data)
    final dictJson = prefs.getString('picture_dict_$courseId');
    if (dictJson != null) {
      try {
        _pictureDictionary = PictureDictionary.fromJson(
            jsonDecode(dictJson) as Map<String, dynamic>);
      } catch (e) {
        debugPrint('Error loading picture dictionary for $courseId: $e');
        _pictureDictionary = await _bundledPictureDictionary(courseId);
        await _savePictureDictionary(courseId);
      }
    } else {
      _pictureDictionary = await _bundledPictureDictionary(courseId);
      await _savePictureDictionary(courseId);
    }

    // Load progress
    final progressJson = prefs.getString('picture_progress_$courseId');
    if (progressJson != null) {
      try {
        _pictureProgress = PictureDictionaryProgress.fromJson(
            jsonDecode(progressJson) as Map<String, dynamic>);
      } catch (e) {
        debugPrint('Error loading picture progress for $courseId: $e');
        _pictureProgress = PictureDictionaryProgress(courseId: courseId);
      }
    } else {
      _pictureProgress = PictureDictionaryProgress(courseId: courseId);
    }
  }

  Future<void> _savePictureDictionary(String courseId) async {
    if (_pictureDictionary == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'picture_dict_$courseId',
      jsonEncode(_pictureDictionary!.toJson()),
    );
  }

  Future<void> _savePictureProgress(String courseId) async {
    if (_pictureProgress == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'picture_progress_$courseId',
      jsonEncode(_pictureProgress!.toJson()),
    );
  }

  void selectTopic(String topicId) {
    if (_pictureDictionary == null) return;
    _currentTopic = _pictureDictionary!.topics.firstWhere(
      (t) => t.id == topicId,
      orElse: () => _pictureDictionary!.topics.first,
    );
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> markWordAsLearned(
      String courseId, String topicId, String wordId) async {
    if (_pictureProgress == null) return;

    if (!_pictureProgress!.hasLearnedWord(wordId)) {
      final newProgress =
          Map<String, int>.from(_pictureProgress!.topicProgress);
      newProgress[topicId] = (newProgress[topicId] ?? 0) + 1;

      _pictureProgress = _pictureProgress!.copyWith(
        topicProgress: newProgress,
        masteredWords: [..._pictureProgress!.masteredWords, wordId],
        lastStudiedDate: DateTime.now(),
      );

      await _savePictureProgress(courseId);
      notifyListeners();
    }
  }

  // ==================== Sample Data ====================

  // ==================== Bundled content ====================

  /// Loads the course's bundled word list, e.g.
  /// assets/vocabulary/word_of_day_spanish_en.json.
  ///
  /// Returns an empty list when a course has no authored vocabulary yet, so
  /// learners see an honest empty state rather than another language's words.
  Future<List<WordOfDay>> _bundledWordArchive(String courseId) async {
    try {
      final raw = await rootBundle
          .loadString('assets/vocabulary/word_of_day_$courseId.json');
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final words = decoded['words'] as List<dynamic>? ?? <dynamic>[];
      return words.map((w) {
        final json = w as Map<String, dynamic>;
        // Each word's date is assigned when it is served as the word of the
        // day (see _getWordForToday), so the bundled asset omits it.
        json.putIfAbsent('date',
            () => DateTime.fromMillisecondsSinceEpoch(0).toIso8601String());
        return WordOfDay.fromJson(json);
      }).toList();
    } catch (e) {
      debugPrint('No bundled word list for $courseId: $e');
      return [];
    }
  }

  /// Loads the course's bundled picture dictionary, or null when the course
  /// has none authored yet.
  Future<PictureDictionary?> _bundledPictureDictionary(String courseId) async {
    try {
      final raw = await rootBundle
          .loadString('assets/vocabulary/picture_dictionary_$courseId.json');
      return PictureDictionary.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('No bundled picture dictionary for $courseId: $e');
      return null;
    }
  }
}
