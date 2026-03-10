import 'package:json_annotation/json_annotation.dart';

part 'picture_dictionary.g.dart';

@JsonSerializable()
class PictureDictionaryEntry {
  final String id;
  final String word; // Word in target language
  final String translation; // Translation in native language
  final String pronunciation; // IPA or phonetic
  final String imageUrl; // Image representing the word
  final String? audioUrl; // Optional pronunciation audio
  final String? pluralForm; // Optional plural form
  final String? article; // Gender article (el/la, le/la, der/die/das)
  final List<String> relatedWords; // Related vocabulary
  final String? usageNote; // Notes about usage

  PictureDictionaryEntry({
    required this.id,
    required this.word,
    required this.translation,
    required this.pronunciation,
    required this.imageUrl,
    this.audioUrl,
    this.pluralForm,
    this.article,
    this.relatedWords = const [],
    this.usageNote,
  });

  factory PictureDictionaryEntry.fromJson(Map<String, dynamic> json) =>
      _$PictureDictionaryEntryFromJson(json);
  Map<String, dynamic> toJson() => _$PictureDictionaryEntryToJson(this);

  /// Full word with article if available
  String get fullWord => article != null ? '$article $word' : word;

  PictureDictionaryEntry copyWith({
    String? id,
    String? word,
    String? translation,
    String? pronunciation,
    String? imageUrl,
    String? audioUrl,
    String? pluralForm,
    String? article,
    List<String>? relatedWords,
    String? usageNote,
  }) {
    return PictureDictionaryEntry(
      id: id ?? this.id,
      word: word ?? this.word,
      translation: translation ?? this.translation,
      pronunciation: pronunciation ?? this.pronunciation,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      pluralForm: pluralForm ?? this.pluralForm,
      article: article ?? this.article,
      relatedWords: relatedWords ?? this.relatedWords,
      usageNote: usageNote ?? this.usageNote,
    );
  }
}

@JsonSerializable()
class PictureDictionaryTopic {
  final String id;
  final String name; // Topic name (e.g., "In the Kitchen")
  final String description; // Brief description
  final String iconName; // Material icon name
  final String coverImageUrl; // Topic cover image
  final List<PictureDictionaryEntry> entries;
  final int difficulty; // 1-3 difficulty level

  PictureDictionaryTopic({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.coverImageUrl,
    required this.entries,
    this.difficulty = 1,
  });

  factory PictureDictionaryTopic.fromJson(Map<String, dynamic> json) =>
      _$PictureDictionaryTopicFromJson(json);
  Map<String, dynamic> toJson() => _$PictureDictionaryTopicToJson(this);

  /// Get difficulty level as text
  String get difficultyText {
    switch (difficulty) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Intermediate';
      case 3:
        return 'Advanced';
      default:
        return 'Beginner';
    }
  }

  /// Get word count
  int get wordCount => entries.length;

  PictureDictionaryTopic copyWith({
    String? id,
    String? name,
    String? description,
    String? iconName,
    String? coverImageUrl,
    List<PictureDictionaryEntry>? entries,
    int? difficulty,
  }) {
    return PictureDictionaryTopic(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      entries: entries ?? this.entries,
      difficulty: difficulty ?? this.difficulty,
    );
  }
}

@JsonSerializable()
class PictureDictionary {
  final String id;
  final String name;
  final String targetLanguage;
  final String nativeLanguage;
  final List<PictureDictionaryTopic> topics;

  PictureDictionary({
    required this.id,
    required this.name,
    required this.targetLanguage,
    required this.nativeLanguage,
    required this.topics,
  });

  factory PictureDictionary.fromJson(Map<String, dynamic> json) =>
      _$PictureDictionaryFromJson(json);
  Map<String, dynamic> toJson() => _$PictureDictionaryToJson(this);

  /// Get all entries across all topics
  List<PictureDictionaryEntry> get allEntries =>
      topics.expand((t) => t.entries).toList();

  /// Get total word count
  int get totalWords => allEntries.length;

  /// Search entries by word
  List<PictureDictionaryEntry> searchEntries(String query) {
    final lowercaseQuery = query.toLowerCase();
    return allEntries
        .where((e) =>
            e.word.toLowerCase().contains(lowercaseQuery) ||
            e.translation.toLowerCase().contains(lowercaseQuery))
        .toList();
  }

  PictureDictionary copyWith({
    String? id,
    String? name,
    String? targetLanguage,
    String? nativeLanguage,
    List<PictureDictionaryTopic>? topics,
  }) {
    return PictureDictionary(
      id: id ?? this.id,
      name: name ?? this.name,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
      topics: topics ?? this.topics,
    );
  }
}

@JsonSerializable()
class PictureDictionaryProgress {
  final String courseId;
  final Map<String, int> topicProgress; // topicId -> number of words learned
  final List<String> masteredWords; // List of mastered word IDs
  final DateTime? lastStudiedDate;

  PictureDictionaryProgress({
    required this.courseId,
    this.topicProgress = const {},
    this.masteredWords = const [],
    this.lastStudiedDate,
  });

  factory PictureDictionaryProgress.fromJson(Map<String, dynamic> json) =>
      _$PictureDictionaryProgressFromJson(json);
  Map<String, dynamic> toJson() => _$PictureDictionaryProgressToJson(this);

  bool hasLearnedWord(String wordId) => masteredWords.contains(wordId);

  int getTopicProgress(String topicId) => topicProgress[topicId] ?? 0;

  double getTopicProgressPercent(String topicId, int totalWords) {
    if (totalWords == 0) return 0;
    return (getTopicProgress(topicId) / totalWords) * 100;
  }

  PictureDictionaryProgress copyWith({
    String? courseId,
    Map<String, int>? topicProgress,
    List<String>? masteredWords,
    DateTime? lastStudiedDate,
  }) {
    return PictureDictionaryProgress(
      courseId: courseId ?? this.courseId,
      topicProgress: topicProgress ?? this.topicProgress,
      masteredWords: masteredWords ?? this.masteredWords,
      lastStudiedDate: lastStudiedDate ?? this.lastStudiedDate,
    );
  }
}
