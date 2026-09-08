import '../models/flashcard.dart';
import '../models/skill.dart';
import '../models/word_pair.dart';
import '../providers/word_knowledge_provider.dart';

/// Builds the pool of word pairs a high-volume drill runs on, merging the
/// course vocabulary deck with any word-shaped items in the current skill.
///
/// Merging is what makes the drills usable today: the skills alone are
/// mostly sentences, and the deck alone is not tied to what the learner is
/// currently studying. Skill words lead so a drill opened from a skill
/// practises that skill first, then widens into the deck for volume.
class WordPool {
  const WordPool(this.pairs);

  final List<WordPair> pairs;

  bool get isEmpty => pairs.isEmpty;
  int get length => pairs.length;

  /// Builds a pool from a deck and an optional skill.
  ///
  /// Deduplication is by normalised target word, so a word appearing in both
  /// the skill and the deck is drilled once. The skill's version wins because
  /// it carries the phrasing the learner just saw.
  static WordPool build({
    FlashcardDeck? deck,
    Skill? skill,
  }) {
    final seen = <String>{};
    final merged = <WordPair>[];

    void add(WordPair? pair) {
      if (pair == null) return;
      final key = _normalise(pair.target);
      if (key.isEmpty || !seen.add(key)) return;
      merged.add(pair);
    }

    if (skill != null) {
      for (final exercise in skill.exercises) {
        add(WordPair.fromExercise(exercise));
        WordPair.fromMatchPairs(exercise).forEach(add);
      }
    }

    if (deck != null) {
      for (final card in deck.cards) {
        add(WordPair.fromFlashcard(card));
      }
    }

    return WordPool(merged);
  }

  /// The words worth drilling right now: everything the learner has not
  /// already retired.
  ///
  /// Known words are dropped rather than shown rarely — the whole point of
  /// marking a word known is never seeing it again unless it is missed.
  WordPool excludingKnown(WordKnowledgeProvider knowledge) => WordPool(
        pairs.where((p) => !knowledge.isKnown(p.target)).toList(),
      );

  /// Splits the pool into words the learner has met and words they have not.
  ///
  /// This is the teach-before-test rule made concrete: a drill introduces the
  /// unseen ones before testing them, rather than asking for a word the
  /// learner has never been shown.
  ({List<WordPair> seen, List<WordPair> unseen}) partitionBySeen(
    WordKnowledgeProvider knowledge,
  ) {
    final seen = <WordPair>[];
    final unseen = <WordPair>[];
    for (final pair in pairs) {
      (knowledge.isUnseen(pair.target) ? unseen : seen).add(pair);
    }
    return (seen: seen, unseen: unseen);
  }

  /// Distractors for [answer], drawn from the same category where possible.
  ///
  /// Same-category options make the choice a real discrimination rather than
  /// a guess between one plausible word and three obviously wrong ones.
  List<WordPair> distractorsFor(WordPair answer, {int count = 3}) {
    bool notAnswer(WordPair p) =>
        _normalise(p.target) != _normalise(answer.target);

    final sameCategory = pairs
        .where((p) =>
            notAnswer(p) &&
            answer.category != null &&
            p.category == answer.category)
        .toList()
      ..shuffle();

    final picked = sameCategory.take(count).toList();
    if (picked.length < count) {
      final rest = pairs
          .where(notAnswer)
          .where((p) => !picked.contains(p))
          .toList()
        ..shuffle();
      picked.addAll(rest.take(count - picked.length));
    }
    return picked;
  }

  static String _normalise(String raw) => raw.trim().toLowerCase();
}
