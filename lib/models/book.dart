import 'package:json_annotation/json_annotation.dart';

part 'book.g.dart';

/// A paragraph in a bilingual book with text in two languages
@JsonSerializable()
class BilingualParagraph {
  final String id;
  final String originalText;
  final String translatedText;
  final List<String> vocabularyWords;

  BilingualParagraph({
    required this.id,
    required this.originalText,
    required this.translatedText,
    this.vocabularyWords = const [],
  });

  factory BilingualParagraph.fromJson(Map<String, dynamic> json) {
    String original = json['originalText'] as String? ?? '';
    String translated = json['translatedText'] as String? ?? '';
    List<String> vocab = (json['vocabularyWords'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        const [];

    if (original.isEmpty || translated.isEmpty || vocab.isEmpty) {
      for (final entry in json.entries) {
        if (original.isEmpty &&
            entry.key.startsWith('originalText_') &&
            entry.value is String) {
          original = entry.value as String;
        } else if (translated.isEmpty &&
            entry.key.startsWith('translatedText_') &&
            entry.value is String) {
          translated = entry.value as String;
        } else if (vocab.isEmpty &&
            entry.key.startsWith('vocabularyWords_') &&
            entry.value is List) {
          vocab = (entry.value as List).map((e) => e.toString()).toList();
        }
      }
    }

    return BilingualParagraph(
      id: json['id'] as String? ?? '',
      originalText: original,
      translatedText: translated,
      vocabularyWords: vocab,
    );
  }
  Map<String, dynamic> toJson() => _$BilingualParagraphToJson(this);
}

/// A chapter in a bilingual book
@JsonSerializable()
class BookChapter {
  final String id;
  final String title;
  final String? translatedTitle;
  final List<BilingualParagraph> paragraphs;

  BookChapter({
    required this.id,
    required this.title,
    this.translatedTitle,
    required this.paragraphs,
  });

  factory BookChapter.fromJson(Map<String, dynamic> json) =>
      _$BookChapterFromJson(json);
  Map<String, dynamic> toJson() => _$BookChapterToJson(this);
}

/// A public domain book available in two languages
@JsonSerializable()
class BilingualBook {
  final String id;
  final String title;
  final String author;
  final String originalLanguage;
  final String translatedLanguage;
  final String description;
  final String? coverImage;
  final String difficulty; // beginner, intermediate, advanced
  final int totalWords;
  final String? category; // literature, document
  final List<BookChapter> chapters;

  BilingualBook({
    required this.id,
    required this.title,
    required this.author,
    required this.originalLanguage,
    required this.translatedLanguage,
    required this.description,
    this.coverImage,
    required this.difficulty,
    required this.totalWords,
    this.category,
    required this.chapters,
  });

  factory BilingualBook.fromJson(Map<String, dynamic> json) =>
      _$BilingualBookFromJson(json);
  Map<String, dynamic> toJson() => _$BilingualBookToJson(this);
}

/// Book reading progress
@JsonSerializable()
class BookProgress {
  final String bookId;
  final String currentChapterId;
  final int currentParagraphIndex;
  final double percentComplete;
  final List<String> learnedWords;
  final DateTime lastReadAt;

  BookProgress({
    required this.bookId,
    required this.currentChapterId,
    required this.currentParagraphIndex,
    required this.percentComplete,
    required this.learnedWords,
    required this.lastReadAt,
  });

  factory BookProgress.fromJson(Map<String, dynamic> json) =>
      _$BookProgressFromJson(json);
  Map<String, dynamic> toJson() => _$BookProgressToJson(this);

  BookProgress copyWith({
    String? bookId,
    String? currentChapterId,
    int? currentParagraphIndex,
    double? percentComplete,
    List<String>? learnedWords,
    DateTime? lastReadAt,
  }) {
    return BookProgress(
      bookId: bookId ?? this.bookId,
      currentChapterId: currentChapterId ?? this.currentChapterId,
      currentParagraphIndex:
          currentParagraphIndex ?? this.currentParagraphIndex,
      percentComplete: percentComplete ?? this.percentComplete,
      learnedWords: learnedWords ?? this.learnedWords,
      lastReadAt: lastReadAt ?? this.lastReadAt,
    );
  }
}

/// Book manifest entry (lightweight reference)
@JsonSerializable()
class BookManifestEntry {
  final String id;
  final String title;
  final String author;
  final String originalLanguage;
  final String translatedLanguage;
  final String description;
  final String? coverImage;
  final String difficulty;
  final int totalWords;
  final int chapterCount;
  final String? category; // literature, document

  BookManifestEntry({
    required this.id,
    required this.title,
    required this.author,
    required this.originalLanguage,
    required this.translatedLanguage,
    required this.description,
    this.coverImage,
    required this.difficulty,
    required this.totalWords,
    required this.chapterCount,
    this.category,
  });

  factory BookManifestEntry.fromJson(Map<String, dynamic> json) =>
      _$BookManifestEntryFromJson(json);
  Map<String, dynamic> toJson() => _$BookManifestEntryToJson(this);
}
