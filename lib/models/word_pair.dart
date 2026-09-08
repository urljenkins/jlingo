import 'package:characters/characters.dart';

import 'exercise.dart';
import 'flashcard.dart';

/// One target-word/meaning pair, the unit every high-volume drill works in.
///
/// Both the vocabulary decks and the skill exercises are reduced to this so
/// the drills do not care where a word came from.
class WordPair {
  const WordPair({
    required this.target,
    required this.native,
    this.category,
    this.pronunciation,
  });

  /// The word in the language being learned — the side that is drilled and
  /// the key that word knowledge is tracked against.
  final String target;

  /// Its meaning in the learner's own language.
  final String native;

  final String? category;
  final String? pronunciation;

  /// Words longer than this are sentences wearing a word's clothes. The
  /// rapid drills need something readable at a glance, and a translation
  /// exercise's full sentence is neither flashable nor matchable.
  static const int _maxWords = 3;
  static const int _maxChars = 28;

  /// Character budget for space-free scripts, where word count cannot apply.
  static const int _maxCjkChars = 4;

  /// Whether [text] looks like a vocabulary item rather than a sentence.
  ///
  /// This is the filter that makes merging skill exercises with the decks
  /// safe: most skill answers are sentences, and they are simply skipped.
  static bool looksLikeWord(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed.length > _maxChars) return false;
    // Sentence punctuation in the middle means it is a clause, not a word.
    if (RegExp(r'[.;:!?]\s').hasMatch(trimmed)) return false;
    if (trimmed.contains('___')) return false;
    // CJK has no spaces, so a word-count test would pass any sentence.
    // Fall back to a character budget: four covers ordinary vocabulary and
    // most set phrases, while excluding sentence-length skill answers.
    final hasCjk = RegExp(r'[\u3040-\u30ff\u4e00-\u9fff]').hasMatch(trimmed);
    if (hasCjk) return trimmed.characters.length <= _maxCjkChars;
    return trimmed.split(RegExp(r'\s+')).length <= _maxWords;
  }

  /// Splits a trailing parenthesised romanisation off a word.
  ///
  /// The Chinese and Japanese decks write their fronts as "你好 (Nǐ hǎo)".
  /// Drilled as-is that is neither word-shaped nor the thing being learned —
  /// the reading belongs beneath the word, the way [WordPair.pronunciation]
  /// is already displayed.
  static ({String word, String? reading}) splitReading(String raw) {
    final match =
        RegExp(r'^(.+?)\s*[（(]([^)）]+)[)）]\s*$').firstMatch(raw.trim());
    if (match == null) return (word: raw.trim(), reading: null);
    return (word: match.group(1)!.trim(), reading: match.group(2)!.trim());
  }

  static WordPair? fromFlashcard(Flashcard card) {
    final front = splitReading(card.front);
    if (!looksLikeWord(front.word)) return null;
    return WordPair(
      target: front.word,
      native: card.back.trim(),
      category: card.category,
      // An authored pronunciation wins; the parenthesised reading is the
      // fallback for decks that inline it instead.
      pronunciation: card.pronunciation ?? front.reading,
    );
  }

  /// Extracts a pair from a skill exercise, or null when the exercise is not
  /// word-shaped.
  ///
  /// Only the types whose question/answer really are a word and its meaning
  /// are considered. A fill-in-the-blank answer, for instance, is a word but
  /// its question is a sentence with a gap — there is no meaning to pair it
  /// with, so it is left out rather than guessed at.
  static WordPair? fromExercise(Exercise exercise) {
    switch (exercise.type) {
      case ExerciseType.translateThis:
        final target = exercise.question.trim();
        final native = exercise.correctAnswer.trim();
        if (!looksLikeWord(target) || !looksLikeWord(native)) return null;
        return WordPair(target: target, native: native);
      case ExerciseType.matchPairs:
        // Handled by [fromMatchPairs] — a single exercise yields many pairs.
        return null;
      default:
        return null;
    }
  }

  /// The pairs carried in a matchPairs exercise's metadata.
  static List<WordPair> fromMatchPairs(Exercise exercise) {
    if (exercise.type != ExerciseType.matchPairs) return const [];
    final raw = exercise.metadata?['pairs'] as List<dynamic>? ?? const [];
    final pairs = <WordPair>[];
    for (final entry in raw) {
      if (entry is! Map<String, dynamic>) continue;
      final pair = MatchPair.fromJson(entry);
      if (!looksLikeWord(pair.target)) continue;
      pairs.add(
          WordPair(target: pair.target.trim(), native: pair.native.trim()));
    }
    return pairs;
  }

  @override
  bool operator ==(Object other) =>
      other is WordPair && other.target == target && other.native == native;

  @override
  int get hashCode => Object.hash(target, native);
}
