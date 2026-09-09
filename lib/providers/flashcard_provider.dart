import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/flashcard.dart';

class FlashcardProvider extends ChangeNotifier {
  List<FlashcardDeck> _decks = [];
  FlashcardDeck? _currentDeck;
  List<Flashcard> _sessionCards = [];
  int _currentCardIndex = 0;
  bool _isShowingAnswer = false;

  // Session statistics
  int _cardsReviewedToday = 0;
  int _correctAnswersToday = 0;
  DateTime? _sessionStartTime;

  // Getters
  List<FlashcardDeck> get decks => _decks;
  FlashcardDeck? get currentDeck => _currentDeck;
  List<Flashcard> get sessionCards => _sessionCards;
  Flashcard? get currentCard =>
      _sessionCards.isNotEmpty && _currentCardIndex < _sessionCards.length
          ? _sessionCards[_currentCardIndex]
          : null;
  int get currentCardIndex => _currentCardIndex;
  bool get isShowingAnswer => _isShowingAnswer;
  int get cardsReviewedToday => _cardsReviewedToday;
  int get correctAnswersToday => _correctAnswersToday;
  int get remainingCards => _sessionCards.length - _currentCardIndex;
  bool get hasMoreCards => _currentCardIndex < _sessionCards.length;
  Duration get sessionDuration => _sessionStartTime != null
      ? DateTime.now().difference(_sessionStartTime!)
      : Duration.zero;

  // Settings
  int _newCardsPerDay = 20;
  int _reviewCardsPerDay = 100;

  int get newCardsPerDay => _newCardsPerDay;
  int get reviewCardsPerDay => _reviewCardsPerDay;

  Future<void> loadDecks(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final decksJson = prefs.getString('flashcard_decks_$courseId');

    if (decksJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(decksJson) as List<dynamic>;
        _decks = decoded
            .map((d) => FlashcardDeck.fromJson(d as Map<String, dynamic>))
            .toList();
        // Saved decks are a snapshot from whenever the course was first
        // opened. Adopt any cards added to the bundled deck since then, or a
        // learner would be stuck with the deck the app shipped with on the
        // day they installed it.
        await _adoptNewBundledCards(courseId);
      } catch (e) {
        // Corrupt or old-format data must not brick startup.
        debugPrint('Error loading flashcard decks for $courseId: $e');
        _decks = await _initialDecks(courseId);
        await _saveDecks(courseId);
      }
    } else {
      // Seed from the course's bundled starter deck, if it has one.
      _decks = await _initialDecks(courseId);
      await _saveDecks(courseId);
    }

    // Load daily stats
    await _loadDailyStats(courseId);
    notifyListeners();
  }

  Future<void> _saveDecks(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'flashcard_decks_$courseId',
      jsonEncode(_decks.map((d) => d.toJson()).toList()),
    );
  }

  Future<void> _loadDailyStats(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final statsKey = 'flashcard_stats_${courseId}_$today';
    final statsJson = prefs.getString(statsKey);

    if (statsJson != null) {
      try {
        final stats = jsonDecode(statsJson) as Map<String, dynamic>;
        _cardsReviewedToday = stats['reviewed'] as int? ?? 0;
        _correctAnswersToday = stats['correct'] as int? ?? 0;
      } catch (e) {
        debugPrint('Error loading flashcard stats for $courseId: $e');
        _cardsReviewedToday = 0;
        _correctAnswersToday = 0;
      }
    } else {
      _cardsReviewedToday = 0;
      _correctAnswersToday = 0;
    }
  }

  Future<void> _saveDailyStats(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final statsKey = 'flashcard_stats_${courseId}_$today';
    await prefs.setString(
      statsKey,
      jsonEncode({
        'reviewed': _cardsReviewedToday,
        'correct': _correctAnswersToday,
      }),
    );
  }

  void selectDeck(String deckId) {
    _currentDeck = _decks.firstWhere(
      (d) => d.id == deckId,
      orElse: () => _decks.first,
    );
    notifyListeners();
  }

  void startStudySession({int? newCardLimit, int? reviewLimit}) {
    if (_currentDeck == null) return;

    _sessionStartTime = DateTime.now();
    _currentCardIndex = 0;
    _isShowingAnswer = false;

    final newLimit = newCardLimit ?? _newCardsPerDay;
    final revLimit = reviewLimit ?? _reviewCardsPerDay;

    // Get due cards (cards that need review)
    final dueCards =
        _currentDeck!.cards.where((c) => c.isDue && !c.isNew).toList();

    // Get new cards
    final newCards = _currentDeck!.newCards.take(newLimit).toList();

    // Combine and shuffle
    _sessionCards = [
      ...dueCards.take(revLimit),
      ...newCards,
    ]..shuffle();

    notifyListeners();
  }

  void showAnswer() {
    _isShowingAnswer = true;
    notifyListeners();
  }

  Future<void> answerCard(SRSQuality quality, String courseId) async {
    if (currentCard == null || _currentDeck == null) return;

    // Update the card with SRS algorithm
    final updatedCard = currentCard!.reviewCard(quality);

    // Update the deck's card list
    final updatedCards = _currentDeck!.cards.map((c) {
      return c.id == updatedCard.id ? updatedCard : c;
    }).toList();

    _currentDeck = _currentDeck!.copyWith(
      cards: updatedCards,
      lastStudiedAt: DateTime.now(),
    );

    // Update the decks list
    _decks = _decks.map((d) {
      return d.id == _currentDeck!.id ? _currentDeck! : d;
    }).toList();

    // Update stats
    _cardsReviewedToday++;
    if (quality != SRSQuality.again) {
      _correctAnswersToday++;
    }

    // Move to next card
    _currentCardIndex++;
    _isShowingAnswer = false;

    // Save progress
    await _saveDecks(courseId);
    await _saveDailyStats(courseId);

    notifyListeners();
  }

  void updateSettings({int? newCardsPerDay, int? reviewCardsPerDay}) {
    if (newCardsPerDay != null) _newCardsPerDay = newCardsPerDay;
    if (reviewCardsPerDay != null) _reviewCardsPerDay = reviewCardsPerDay;
    notifyListeners();
  }

  /// Adds cards present in the bundled deck but missing from the saved one.
  ///
  /// Review state lives on the card, so merging by id keeps every ease
  /// factor, interval and lapse count the learner has built up. Cards are
  /// only ever added: one removed from the asset stays put rather than
  /// discarding the history attached to it.
  Future<void> _adoptNewBundledCards(String courseId) async {
    final bundled = await _bundledDeck(courseId);
    if (bundled == null || bundled.cards.isEmpty) return;

    final index = _decks.indexWhere((d) => d.id == bundled.id);
    if (index == -1) {
      _decks = [..._decks, bundled];
      await _saveDecks(courseId);
      notifyListeners();
      return;
    }

    final saved = _decks[index];
    final known = saved.cards.map((c) => c.id).toSet();
    final additions =
        bundled.cards.where((c) => !known.contains(c.id)).toList();
    if (additions.isEmpty) return;

    _decks = [..._decks]..[index] =
        saved.copyWith(cards: [...saved.cards, ...additions]);
    await _saveDecks(courseId);
    notifyListeners();
  }

  Future<List<FlashcardDeck>> _initialDecks(String courseId) async {
    final deck = await _bundledDeck(courseId);
    return deck == null ? <FlashcardDeck>[] : [deck];
  }

  /// Loads the course's bundled starter deck.
  ///
  /// Returns null when a course has no authored flashcards yet, so learners
  /// see an honest empty state rather than another language's cards.
  Future<FlashcardDeck?> _bundledDeck(String courseId) async {
    try {
      final raw = await rootBundle
          .loadString('assets/vocabulary/flashcards_$courseId.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      // createdAt is per-install state rather than authored content, so the
      // bundled asset omits it and we stamp it on first load.
      json.putIfAbsent('createdAt', () => DateTime.now().toIso8601String());
      return FlashcardDeck.fromJson(json);
    } catch (e) {
      debugPrint('No bundled flashcard deck for $courseId: $e');
      return null;
    }
  }

  // Get deck statistics
  Map<String, dynamic> getDeckStatistics(String deckId) {
    final deck = _decks.firstWhere(
      (d) => d.id == deckId,
      orElse: () => _decks.first,
    );

    final stats = deck.stats;
    return {
      'totalCards': stats.totalCards,
      'dueCards': stats.dueCards,
      'newCards': stats.newCards,
      'learnedCards': stats.learnedCards,
      'matureCards': stats.matureCards,
      'retentionRate': stats.retentionRate,
    };
  }
}
