import 'package:json_annotation/json_annotation.dart';

part 'word_of_day.g.dart';

@JsonSerializable()
class WordOfDay {
  final String id;
  final String word; // Word in target language
  final String translation; // Translation in native language
  final String pronunciation; // IPA or phonetic
  final String partOfSpeech; // noun, verb, adjective, etc.
  final String exampleSentence; // Example usage in target language
  final String exampleTranslation; // Translation of example
  final String? etymology; // Optional word origin
  final String? funFact; // Optional interesting fact
  final String? imageUrl; // Optional related image
  final String? audioUrl; // Optional pronunciation audio
  final String category; // Thematic category
  final DateTime date; // The date this word is for
  final int difficulty; // 1-5 difficulty rating

  WordOfDay({
    required this.id,
    required this.word,
    required this.translation,
    required this.pronunciation,
    required this.partOfSpeech,
    required this.exampleSentence,
    required this.exampleTranslation,
    this.etymology,
    this.funFact,
    this.imageUrl,
    this.audioUrl,
    this.category = 'General',
    required this.date,
    this.difficulty = 1,
  });

  factory WordOfDay.fromJson(Map<String, dynamic> json) =>
      _$WordOfDayFromJson(json);
  Map<String, dynamic> toJson() => _$WordOfDayToJson(this);

  /// Check if this word is for today
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Get difficulty stars (for display)
  String get difficultyStars => '★' * difficulty + '☆' * (5 - difficulty);

  WordOfDay copyWith({
    String? id,
    String? word,
    String? translation,
    String? pronunciation,
    String? partOfSpeech,
    String? exampleSentence,
    String? exampleTranslation,
    String? etymology,
    String? funFact,
    String? imageUrl,
    String? audioUrl,
    String? category,
    DateTime? date,
    int? difficulty,
  }) {
    return WordOfDay(
      id: id ?? this.id,
      word: word ?? this.word,
      translation: translation ?? this.translation,
      pronunciation: pronunciation ?? this.pronunciation,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      exampleSentence: exampleSentence ?? this.exampleSentence,
      exampleTranslation: exampleTranslation ?? this.exampleTranslation,
      etymology: etymology ?? this.etymology,
      funFact: funFact ?? this.funFact,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      category: category ?? this.category,
      date: date ?? this.date,
      difficulty: difficulty ?? this.difficulty,
    );
  }
}

@JsonSerializable()
class WordOfDayHistory {
  final String courseId;
  final List<String> viewedWordIds; // Words the user has seen
  final List<String> savedWordIds; // Words the user saved for later
  final DateTime? lastViewedDate;

  WordOfDayHistory({
    required this.courseId,
    this.viewedWordIds = const [],
    this.savedWordIds = const [],
    this.lastViewedDate,
  });

  factory WordOfDayHistory.fromJson(Map<String, dynamic> json) =>
      _$WordOfDayHistoryFromJson(json);
  Map<String, dynamic> toJson() => _$WordOfDayHistoryToJson(this);

  bool hasViewedWord(String wordId) => viewedWordIds.contains(wordId);
  bool hasSavedWord(String wordId) => savedWordIds.contains(wordId);

  WordOfDayHistory copyWith({
    String? courseId,
    List<String>? viewedWordIds,
    List<String>? savedWordIds,
    DateTime? lastViewedDate,
  }) {
    return WordOfDayHistory(
      courseId: courseId ?? this.courseId,
      viewedWordIds: viewedWordIds ?? this.viewedWordIds,
      savedWordIds: savedWordIds ?? this.savedWordIds,
      lastViewedDate: lastViewedDate ?? this.lastViewedDate,
    );
  }
}
