import '../models/exercise.dart';
import '../models/word_pair.dart';
import '../services/word_pool.dart';

/// Extends a thin skill with generated exercises drawn from the word pool.
///
/// Most skills in the course are authored with five exercises. Five is over
/// in under a minute, and — because [LessonOrder] only shuffles within its
/// groups — replaying the skill returns the same five. The lesson was not
/// ending early; there was simply nothing more in the file.
///
/// Rather than wait on authoring 550 skill files, a short skill is topped up
/// at runtime from the course vocabulary deck, which carries 150+ pairs per
/// course. The authored exercises always lead: they are the ones written for
/// this skill, and the generated ones are volume behind them.
///
/// The generated exercises are deliberately the recognition types. A word
/// pair supplies a word and its meaning and nothing else — enough to build a
/// multiple choice or a match, not enough to invent a dialogue or a story
/// with any authorial judgement behind it.
abstract final class LessonTopUp {
  /// How long a lesson should run when there is material to fill it.
  ///
  /// Twelve is roughly three minutes at the pace the exercise widgets set:
  /// long enough to be a session rather than a glance, short enough that a
  /// learner finishes it in one sitting.
  static const int targetLength = 12;

  /// How many pairs one match exercise puts on screen. More than five turns
  /// a match into a scanning chore on a phone.
  static const int _pairsPerMatch = 4;

  /// Builds the lesson for [authored], topping it up from [pool] when short.
  ///
  /// [seed] varies the selection between runs, so tapping the same thin
  /// skill twice gives a different set of generated exercises rather than a
  /// replay. Callers pass something that changes per visit; tests pass a
  /// fixed value to pin the output.
  ///
  /// Returns [authored] untouched when it already reaches [targetLength] or
  /// when the pool has too little to build from — a half-built top-up is
  /// worse than none, since it puts the learner on words with no distractors
  /// to choose between.
  static List<Exercise> extend({
    required List<Exercise> authored,
    required WordPool pool,
    required int seed,
    int targetLength = targetLength,
  }) {
    final shortfall = targetLength - authored.length;
    if (shortfall <= 0) return authored;

    // Words the skill already covers are not topped up with: the learner is
    // about to meet them in the authored exercises anyway, and repeating
    // them here would crowd out the words that add breadth.
    //
    // Both sides of every pairing count, and so does the bare answer text.
    // A translateThis reads "El niño" → "The boy", so which side holds the
    // target language depends on the direction the exercise was authored in;
    // collecting both is what stops a word being asked twice in one lesson.
    final covered = <String>{
      for (final exercise in authored) ...[
        _key(exercise.correctAnswer),
        _key(exercise.question),
        if (WordPair.fromExercise(exercise) case final pair?) ...[
          _key(pair.target),
          _key(pair.native),
        ],
        for (final pair in WordPair.fromMatchPairs(exercise)) ...[
          _key(pair.target),
          _key(pair.native),
        ],
      ],
    }..remove('');

    final candidates =
        pool.pairs.where((p) => !covered.contains(_key(p.target))).toList();

    // A multiple choice needs the answer plus three distractors, so four
    // pairs is the floor for generating anything at all.
    if (candidates.length < 4) return authored;

    // Rotating by the seed rather than shuffling keeps related words — the
    // decks are authored in category order — near each other, so a generated
    // round tends to cohere around a topic instead of being scattershot.
    final start = seed.abs() % candidates.length;
    final rotated = [
      ...candidates.sublist(start),
      ...candidates.sublist(0, start),
    ];

    final generated = <Exercise>[];

    // Lead with a match: it introduces several words with their meanings at
    // once, which is what earns the right to test them in what follows.
    if (rotated.length >= _pairsPerMatch && shortfall >= 2) {
      generated
          .add(_matchExercise(rotated.take(_pairsPerMatch).toList(), seed));
    }

    // Then work along the same rotation asking for those words. The match
    // introduced the first few, so the questions that follow arrive while
    // the introduction is still fresh.
    for (final answer in rotated) {
      if (generated.length >= shortfall) break;

      final distractors = _distractors(answer, rotated);
      if (distractors.length < 3) continue;

      generated.add(_choiceExercise(answer, distractors, generated.length));
    }

    return [...authored, ...generated];
  }

  /// Three wrong meanings for [answer], preferring its own category.
  ///
  /// Same-category distractors make the question a real discrimination
  /// rather than a giveaway — picking "hello" out of "hello, table, to run,
  /// yellow" tests nothing.
  static List<WordPair> _distractors(WordPair answer, List<WordPair> from) {
    bool notAnswer(WordPair p) => _key(p.target) != _key(answer.target);
    // Distinct meanings only: two pairs glossed the same way would put two
    // correct-looking options on screen.
    bool distinctMeaning(WordPair p) => _key(p.native) != _key(answer.native);

    final pool = from.where(notAnswer).where(distinctMeaning).toList();
    final sameCategory = answer.category == null
        ? const <WordPair>[]
        : pool.where((p) => p.category == answer.category).toList();

    final picked = <WordPair>[...sameCategory.take(3)];
    for (final pair in pool) {
      if (picked.length >= 3) break;
      if (picked.any((p) => _key(p.target) == _key(pair.target))) continue;
      picked.add(pair);
    }
    return picked;
  }

  /// A "what does this mean" multiple choice over [answer].
  static Exercise _choiceExercise(
    WordPair answer,
    List<WordPair> distractors,
    int ordinal,
  ) {
    final options = [answer.native, ...distractors.map((p) => p.native)]
      ..shuffle();
    return Exercise(
      id: 'topup_choice_${_slug(answer.target)}_$ordinal',
      type: ExerciseType.multipleChoice,
      question: answer.target,
      options: options,
      correctAnswer: answer.native,
      // Marks the exercise as generated rather than authored, so the UI can
      // tell the learner where it came from and progress can weigh it
      // differently if that is ever wanted.
      metadata: {
        'generated': true,
        if (answer.pronunciation != null) 'pronunciation': answer.pronunciation,
      },
    );
  }

  /// A match-pairs exercise introducing [pairs] with their meanings.
  static Exercise _matchExercise(List<WordPair> pairs, int seed) {
    return Exercise(
      id: 'topup_match_$seed',
      type: ExerciseType.matchPairs,
      question: 'Match the words to their meanings',
      options: const [],
      correctAnswer: '',
      metadata: {
        'generated': true,
        'pairs': [
          for (final pair in pairs)
            {'target': pair.target, 'native': pair.native},
        ],
      },
    );
  }

  static String _key(String raw) => raw.trim().toLowerCase();

  /// A stable id fragment, since exercise ids should not carry spaces or
  /// accents into anything that logs or stores them.
  static String _slug(String raw) =>
      raw.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}
