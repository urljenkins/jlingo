import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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
      final List<dynamic> decoded = jsonDecode(decksJson) as List<dynamic>;
      _decks = decoded
          .map((d) => FlashcardDeck.fromJson(d as Map<String, dynamic>))
          .toList();
    } else {
      // Initialize with default deck containing sample vocabulary
      _decks = [_createSampleDeck(courseId)];
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
      final stats = jsonDecode(statsJson) as Map<String, dynamic>;
      _cardsReviewedToday = stats['reviewed'] as int? ?? 0;
      _correctAnswersToday = stats['correct'] as int? ?? 0;
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

  Future<FlashcardDeck> createDeck({
    required String courseId,
    required String name,
    required String description,
    required String targetLanguage,
    required String nativeLanguage,
  }) async {
    final deck = FlashcardDeck(
      id: 'deck_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      targetLanguage: targetLanguage,
      nativeLanguage: nativeLanguage,
      cards: [],
      createdAt: DateTime.now(),
    );

    _decks.add(deck);
    await _saveDecks(courseId);
    notifyListeners();
    return deck;
  }

  Future<void> addCardToDeck({
    required String courseId,
    required String deckId,
    required Flashcard card,
  }) async {
    final deckIndex = _decks.indexWhere((d) => d.id == deckId);
    if (deckIndex == -1) return;

    final deck = _decks[deckIndex];
    final updatedCards = [...deck.cards, card];
    _decks[deckIndex] = deck.copyWith(cards: updatedCards);

    if (_currentDeck?.id == deckId) {
      _currentDeck = _decks[deckIndex];
    }

    await _saveDecks(courseId);
    notifyListeners();
  }

  Future<void> deleteDeck(String courseId, String deckId) async {
    _decks.removeWhere((d) => d.id == deckId);
    if (_currentDeck?.id == deckId) {
      _currentDeck = _decks.isNotEmpty ? _decks.first : null;
    }
    await _saveDecks(courseId);
    notifyListeners();
  }

  void updateSettings({int? newCardsPerDay, int? reviewCardsPerDay}) {
    if (newCardsPerDay != null) _newCardsPerDay = newCardsPerDay;
    if (reviewCardsPerDay != null) _reviewCardsPerDay = reviewCardsPerDay;
    notifyListeners();
  }

  FlashcardDeck _createSampleDeck(String courseId) {
    return FlashcardDeck(
      id: 'default_deck',
      name: 'Core Vocabulary',
      description: 'Essential words and phrases for beginners',
      targetLanguage: 'target',
      nativeLanguage: 'native',
      cards: _sampleFlashcards,
      createdAt: DateTime.now(),
    );
  }

  List<Flashcard> get _sampleFlashcards => [
        Flashcard(
          id: 'fc_1',
          front: 'Bonjour',
          back: 'Hello / Good day',
          pronunciation: '/bɔ̃.ʒuʁ/',
          exampleSentence: 'Bonjour, comment allez-vous ?',
          exampleTranslation: 'Hello, how are you?',
          category: 'Greetings',
          tags: ['basic', 'polite'],
        ),
        Flashcard(
          id: 'fc_2',
          front: 'Merci',
          back: 'Thank you',
          pronunciation: '/mɛʁ.si/',
          exampleSentence: 'Merci beaucoup pour votre aide.',
          exampleTranslation: 'Thank you very much for your help.',
          category: 'Greetings',
          tags: ['basic', 'polite'],
        ),
        Flashcard(
          id: 'fc_3',
          front: 'Au revoir',
          back: 'Goodbye',
          pronunciation: '/o ʁə.vwaʁ/',
          exampleSentence: 'Au revoir, à demain !',
          exampleTranslation: 'Goodbye, see you tomorrow!',
          category: 'Greetings',
          tags: ['basic', 'polite'],
        ),
        Flashcard(
          id: 'fc_4',
          front: 'S\'il vous plaît',
          back: 'Please (formal)',
          pronunciation: '/sil vu plɛ/',
          exampleSentence: 'Un café, s\'il vous plaît.',
          exampleTranslation: 'A coffee, please.',
          category: 'Greetings',
          tags: ['basic', 'polite', 'formal'],
        ),
        Flashcard(
          id: 'fc_5',
          front: 'Excusez-moi',
          back: 'Excuse me',
          pronunciation: '/ɛk.sky.ze mwa/',
          exampleSentence: 'Excusez-moi, où est la gare ?',
          exampleTranslation: 'Excuse me, where is the train station?',
          category: 'Greetings',
          tags: ['basic', 'polite'],
        ),
        Flashcard(
          id: 'fc_6',
          front: 'Je m\'appelle',
          back: 'My name is',
          pronunciation: '/ʒə ma.pɛl/',
          exampleSentence: 'Je m\'appelle Marie.',
          exampleTranslation: 'My name is Marie.',
          category: 'Introduction',
          tags: ['basic', 'introduction'],
        ),
        Flashcard(
          id: 'fc_7',
          front: 'Comment ça va ?',
          back: 'How are you? (informal)',
          pronunciation: '/kɔ.mɑ̃ sa va/',
          exampleSentence: 'Salut ! Comment ça va ?',
          exampleTranslation: 'Hi! How are you?',
          category: 'Greetings',
          tags: ['basic', 'informal'],
        ),
        Flashcard(
          id: 'fc_8',
          front: 'Oui',
          back: 'Yes',
          pronunciation: '/wi/',
          exampleSentence: 'Oui, je comprends.',
          exampleTranslation: 'Yes, I understand.',
          category: 'Basics',
          tags: ['basic', 'essential'],
        ),
        Flashcard(
          id: 'fc_9',
          front: 'Non',
          back: 'No',
          pronunciation: '/nɔ̃/',
          exampleSentence: 'Non, merci.',
          exampleTranslation: 'No, thank you.',
          category: 'Basics',
          tags: ['basic', 'essential'],
        ),
        Flashcard(
          id: 'fc_10',
          front: 'Je ne comprends pas',
          back: 'I don\'t understand',
          pronunciation: '/ʒə nə kɔ̃.pʁɑ̃ pa/',
          exampleSentence: 'Désolé, je ne comprends pas.',
          exampleTranslation: 'Sorry, I don\'t understand.',
          category: 'Communication',
          tags: ['basic', 'useful'],
        ),
      ];

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
