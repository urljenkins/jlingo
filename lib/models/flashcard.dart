import 'package:json_annotation/json_annotation.dart';

part 'flashcard.g.dart';

/// Spaced Repetition System (SRS) quality ratings
/// Based on the SM-2 algorithm used by Anki and SuperMemo
enum SRSQuality {
  /// Complete blackout - card shown again immediately
  again(0),

  /// Incorrect response after hesitation
  hard(1),

  /// Correct response with difficulty
  good(2),

  /// Perfect response with no hesitation
  easy(3);

  const SRSQuality(this.value);
  final int value;
}

@JsonSerializable()
class Flashcard {
  final String id;
  final String front; // Question/word in target language
  final String back; // Answer/translation
  final String? pronunciation; // IPA or phonetic pronunciation
  final String? exampleSentence; // Example usage
  final String? exampleTranslation; // Translation of example
  final String? imageUrl; // Optional image for visual learning
  final String? audioUrl; // Optional audio pronunciation
  final String category; // Thematic category (e.g., "Kitchen", "Travel")
  final List<String> tags; // Additional tags for filtering

  // SRS fields
  final double easeFactor; // Multiplier for interval (default 2.5)
  final int interval; // Current interval in days
  final int repetitions; // Number of successful reviews
  final DateTime? nextReviewDate; // When to show this card next
  final DateTime? lastReviewDate; // Last time card was reviewed
  final int lapses; // Number of times "Again" was pressed

  Flashcard({
    required this.id,
    required this.front,
    required this.back,
    this.pronunciation,
    this.exampleSentence,
    this.exampleTranslation,
    this.imageUrl,
    this.audioUrl,
    this.category = 'General',
    this.tags = const [],
    this.easeFactor = 2.5,
    this.interval = 0,
    this.repetitions = 0,
    this.nextReviewDate,
    this.lastReviewDate,
    this.lapses = 0,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) =>
      _$FlashcardFromJson(json);
  Map<String, dynamic> toJson() => _$FlashcardToJson(this);

  /// Calculates the next review date and interval based on SM-2 algorithm
  Flashcard reviewCard(SRSQuality quality) {
    final now = DateTime.now();
    double newEaseFactor = easeFactor;
    int newInterval;
    int newRepetitions = repetitions;
    int newLapses = lapses;

    if (quality == SRSQuality.again) {
      // Failed - reset to beginning
      newRepetitions = 0;
      newInterval = 1; // Review tomorrow
      newLapses++;
    } else {
      // Successful review
      newRepetitions++;

      if (newRepetitions == 1) {
        newInterval = 1;
      } else if (newRepetitions == 2) {
        newInterval = 6;
      } else {
        newInterval = (interval * newEaseFactor).round();
      }

      // Update ease factor based on quality
      newEaseFactor = easeFactor +
          (0.1 - (3 - quality.value) * (0.08 + (3 - quality.value) * 0.02));
      if (newEaseFactor < 1.3) newEaseFactor = 1.3;

      // Adjust interval based on quality
      if (quality == SRSQuality.hard) {
        newInterval = (newInterval * 0.8).round();
      } else if (quality == SRSQuality.easy) {
        newInterval = (newInterval * 1.3).round();
      }
    }

    // Ensure minimum interval of 1 day
    if (newInterval < 1) newInterval = 1;

    return copyWith(
      easeFactor: newEaseFactor,
      interval: newInterval,
      repetitions: newRepetitions,
      nextReviewDate: now.add(Duration(days: newInterval)),
      lastReviewDate: now,
      lapses: newLapses,
    );
  }

  /// Check if this card is due for review
  bool get isDue {
    if (nextReviewDate == null) return true;
    return DateTime.now().isAfter(nextReviewDate!) ||
        DateTime.now().day == nextReviewDate!.day;
  }

  /// Check if this is a new card (never reviewed)
  bool get isNew => repetitions == 0 && nextReviewDate == null;

  /// Get the card's maturity level
  String get maturityLevel {
    if (isNew) return 'New';
    if (interval < 21) return 'Learning';
    if (interval < 60) return 'Young';
    return 'Mature';
  }

  Flashcard copyWith({
    String? id,
    String? front,
    String? back,
    String? pronunciation,
    String? exampleSentence,
    String? exampleTranslation,
    String? imageUrl,
    String? audioUrl,
    String? category,
    List<String>? tags,
    double? easeFactor,
    int? interval,
    int? repetitions,
    DateTime? nextReviewDate,
    DateTime? lastReviewDate,
    int? lapses,
  }) {
    return Flashcard(
      id: id ?? this.id,
      front: front ?? this.front,
      back: back ?? this.back,
      pronunciation: pronunciation ?? this.pronunciation,
      exampleSentence: exampleSentence ?? this.exampleSentence,
      exampleTranslation: exampleTranslation ?? this.exampleTranslation,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      easeFactor: easeFactor ?? this.easeFactor,
      interval: interval ?? this.interval,
      repetitions: repetitions ?? this.repetitions,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      lastReviewDate: lastReviewDate ?? this.lastReviewDate,
      lapses: lapses ?? this.lapses,
    );
  }
}

@JsonSerializable()
class FlashcardDeck {
  final String id;
  final String name;
  final String description;
  final String targetLanguage;
  final String nativeLanguage;
  final List<Flashcard> cards;
  final DateTime createdAt;
  final DateTime? lastStudiedAt;

  FlashcardDeck({
    required this.id,
    required this.name,
    required this.description,
    required this.targetLanguage,
    required this.nativeLanguage,
    required this.cards,
    required this.createdAt,
    this.lastStudiedAt,
  });

  factory FlashcardDeck.fromJson(Map<String, dynamic> json) =>
      _$FlashcardDeckFromJson(json);
  Map<String, dynamic> toJson() => _$FlashcardDeckToJson(this);

  /// Get cards due for review
  List<Flashcard> get dueCards => cards.where((c) => c.isDue).toList();

  /// Get new cards
  List<Flashcard> get newCards => cards.where((c) => c.isNew).toList();

  /// Get statistics for the deck
  DeckStats get stats {
    final dueCount = dueCards.length;
    final newCount = newCards.length;
    final learned = cards.where((c) => c.repetitions > 0).length;

    return DeckStats(
      totalCards: cards.length,
      dueCards: dueCount,
      newCards: newCount,
      learnedCards: learned,
      matureCards: cards.where((c) => c.interval >= 21).length,
    );
  }

  FlashcardDeck copyWith({
    String? id,
    String? name,
    String? description,
    String? targetLanguage,
    String? nativeLanguage,
    List<Flashcard>? cards,
    DateTime? createdAt,
    DateTime? lastStudiedAt,
  }) {
    return FlashcardDeck(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
      cards: cards ?? this.cards,
      createdAt: createdAt ?? this.createdAt,
      lastStudiedAt: lastStudiedAt ?? this.lastStudiedAt,
    );
  }
}

class DeckStats {
  final int totalCards;
  final int dueCards;
  final int newCards;
  final int learnedCards;
  final int matureCards;

  DeckStats({
    required this.totalCards,
    required this.dueCards,
    required this.newCards,
    required this.learnedCards,
    required this.matureCards,
  });

  double get retentionRate =>
      totalCards > 0 ? (matureCards / totalCards) * 100 : 0;
}
