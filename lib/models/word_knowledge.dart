import 'package:json_annotation/json_annotation.dart';

part 'word_knowledge.g.dart';

/// How confident we are that a learner knows one word.
///
/// The ladder is deliberately short. A word is either unseen, being learned,
/// or done with — finer gradations would be guesswork given how little signal
/// a tap carries, and they would make the "known" filter harder to reason
/// about when a learner asks why a word keeps reappearing.
enum WordConfidence {
  /// Never presented. The only state that still counts as new material.
  unseen,

  /// Seen, but not yet answered well enough often enough to retire.
  learning,

  /// Retired from drills. Reached by answering fast and correctly enough
  /// times, or declared outright by the learner.
  known,
}

/// What we know about one word, keyed by the word itself rather than by any
/// exercise id — the same word is drilled from several skills and both
/// vocabulary decks, and knowing it in one place means knowing it everywhere.
@JsonSerializable()
class WordKnowledge {
  const WordKnowledge({
    required this.word,
    this.confidence = WordConfidence.unseen,
    this.correctStreak = 0,
    this.timesSeen = 0,
    this.fastCorrect = 0,
    this.declaredKnown = false,
    this.lastSeen,
  });

  /// The target-language word, normalised by [normaliseWord].
  final String word;

  final WordConfidence confidence;

  /// Consecutive correct answers. Reset by any miss, which is what stops a
  /// half-learned word from creeping up the ladder on lucky guesses.
  final int correctStreak;

  final int timesSeen;

  /// Correct answers that also came back inside [fastAnswerThreshold].
  /// Speed is the signal that separates recall from working it out.
  final int fastCorrect;

  /// Set when the learner said "I know this" outright. Kept separate from
  /// [confidence] so that a later miss can demote the word without losing
  /// the fact that they once claimed it.
  final bool declaredKnown;

  final DateTime? lastSeen;

  /// Answers quicker than this are treated as recall rather than reasoning.
  /// Tuned for a tap on a four-option row: long enough to read the options,
  /// short enough to exclude deliberation.
  static const Duration fastAnswerThreshold = Duration(milliseconds: 2500);

  /// Fast, correct answers needed before a word retires itself.
  static const int fastCorrectToKnow = 3;

  /// Words are compared case- and accent-insensitively, and without
  /// surrounding punctuation, so "¡Hola!" and "hola" are one word rather
  /// than two entries that must each be learned.
  static String normaliseWord(String raw) {
    const accents = 'áàâäãåéèêëíìîïóòôöõúùûüñçÁÀÂÄÃÅÉÈÊËÍÌÎÏÓÒÔÖÕÚÙÛÜÑÇ';
    const plain = 'aaaaaaeeeeiiiiooooouuuuncAAAAAAEEEEIIIIOOOOOUUUUNC';
    final buffer = StringBuffer();
    for (final rune in raw.trim().toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      final index = accents.indexOf(char);
      buffer.write(index >= 0 ? plain[index] : char);
    }
    // Strip punctuation that decorates a prompt rather than identifying the
    // word: ¡Hola! and Hola are the same vocabulary item.
    return buffer
        .toString()
        .replaceAll(RegExp(r'''^[¡¿"'(\[]+|[!?.,;:"')\]]+$'''), '')
        .trim();
  }

  bool get isKnown => confidence == WordConfidence.known;

  /// The word after one answer, with [elapsed] the time the learner took.
  ///
  /// Promotion needs [fastCorrectToKnow] fast correct answers, so a learner
  /// who already knows the vocabulary clears it in three light taps, while
  /// slow-but-correct answers keep the word in rotation.
  WordKnowledge afterAnswer({required bool correct, Duration? elapsed}) {
    final wasFast =
        correct && elapsed != null && elapsed <= fastAnswerThreshold;
    final nextFastCorrect = correct ? fastCorrect + (wasFast ? 1 : 0) : 0;
    final nextStreak = correct ? correctStreak + 1 : 0;

    // A miss always pulls the word back into rotation, even one the learner
    // declared known — claiming a word and then missing it is exactly the
    // case the drill exists to catch.
    final WordConfidence next;
    if (!correct) {
      next = WordConfidence.learning;
    } else if (nextFastCorrect >= fastCorrectToKnow) {
      next = WordConfidence.known;
    } else {
      next = confidence == WordConfidence.known
          ? WordConfidence.known
          : WordConfidence.learning;
    }

    return copyWith(
      confidence: next,
      correctStreak: nextStreak,
      timesSeen: timesSeen + 1,
      fastCorrect: nextFastCorrect,
      lastSeen: DateTime.now(),
    );
  }

  /// The word after the learner declares they already know it.
  WordKnowledge asDeclaredKnown() => copyWith(
        confidence: WordConfidence.known,
        declaredKnown: true,
        fastCorrect: fastCorrectToKnow,
        lastSeen: DateTime.now(),
      );

  /// The word after the learner takes that claim back.
  WordKnowledge asUnknown() => copyWith(
        confidence: WordConfidence.learning,
        declaredKnown: false,
        fastCorrect: 0,
        correctStreak: 0,
      );

  WordKnowledge copyWith({
    WordConfidence? confidence,
    int? correctStreak,
    int? timesSeen,
    int? fastCorrect,
    bool? declaredKnown,
    DateTime? lastSeen,
  }) =>
      WordKnowledge(
        word: word,
        confidence: confidence ?? this.confidence,
        correctStreak: correctStreak ?? this.correctStreak,
        timesSeen: timesSeen ?? this.timesSeen,
        fastCorrect: fastCorrect ?? this.fastCorrect,
        declaredKnown: declaredKnown ?? this.declaredKnown,
        lastSeen: lastSeen ?? this.lastSeen,
      );

  factory WordKnowledge.fromJson(Map<String, dynamic> json) =>
      _$WordKnowledgeFromJson(json);
  Map<String, dynamic> toJson() => _$WordKnowledgeToJson(this);
}
