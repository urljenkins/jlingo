import '../models/exercise.dart';
import '../models/word_knowledge.dart';
import '../models/word_pair.dart';

/// Orders a lesson's exercises so a word is met before it is tested.
///
/// The lesson used to `shuffle()` its whole list, which destroyed whatever
/// order the content was authored in. That is what let a fill-in-the-blank on
/// "hache" appear third in a 101-exercise skill when the word is introduced
/// nowhere else in that skill at all.
///
/// Two things are fixed here. Exercises that introduce a word — pairing it
/// with its meaning — are sorted ahead of the exercises that ask for it, and
/// a word the skill introduces nowhere is asked for only at the very end.
/// Shuffling then happens within each group rather than across the whole
/// lesson, so runs still vary without the teaching order being lost.
///
/// Ordering cannot invent an introduction that the content does not contain.
/// Where a skill never teaches a word, the best this can do is stop it
/// ambushing the learner in the opening exercises; the fix is authoring the
/// introduction, and [untaughtWords] reports which ones are missing.
abstract final class LessonOrder {
  /// Whether the exercise reveals its answer rather than demanding recall.
  ///
  /// This decides the ordering tier — recognition before production — and is
  /// separate from which words the exercise actually introduces, which is
  /// the stricter question [wordsTaught] answers.
  static bool teaches(Exercise exercise) {
    switch (exercise.type) {
      case ExerciseType.matchPairs:
      case ExerciseType.multipleChoice:
      case ExerciseType.storyLesson:
      case ExerciseType.nativeAudio:
      case ExerciseType.dialogueListening:
      case ExerciseType.interactiveDialogue:
        return true;
      case ExerciseType.selectImage:
      case ExerciseType.completeTheChat:
        // Both show every option, so the answer is on screen to be
        // recognised rather than produced from memory.
        return true;
      case ExerciseType.listeningComprehension:
      case ExerciseType.fillInBlank:
        // These teach only when the answer is among the options shown. A
        // fill-in-the-blank with options is recognition; one without is
        // recall, and recall cannot introduce a word.
        return exercise.options.length > 1;
      case ExerciseType.wordBankTranslate:
      case ExerciseType.tapWhatYouHear:
        // The bank supplies the words, but the learner still has to choose
        // and order them — closer to production than to being shown a word,
        // and the tiles carry no meanings to learn from.
        return false;
      case ExerciseType.translateThis:
      case ExerciseType.speakThis:
      case ExerciseType.pronunciationPractice:
      case ExerciseType.translationExercise:
      case ExerciseType.clozeTest:
      case ExerciseType.songFill:
        return false;
    }
  }

  /// The words an exercise actually introduces — shows *with its meaning*.
  ///
  /// Stricter than [teaches] on purpose. Seeing "hache" as one of four
  /// options does not teach it: the learner still has no idea which option
  /// means "the silent letter", and picking right is a one-in-four guess.
  /// A word counts as introduced only where the exercise pairs it with its
  /// meaning, so the learner comes away knowing what it means:
  ///
  ///  - match pairs, which put word and meaning side by side;
  ///  - a question naming the word whose answer is its meaning (or the
  ///    reverse), as a translation-shaped multiple choice does.
  ///
  /// Distractor options are never introductions — they are noise the learner
  /// is meant to reject.
  static Set<String> wordsTaught(Exercise exercise) {
    if (!teaches(exercise)) return const {};

    final words = <String>{};

    // Match pairs are the clearest introduction there is: both sides shown
    // together, explicitly linked.
    for (final pair in WordPair.fromMatchPairs(exercise)) {
      words
        ..add(_key(pair.target))
        ..add(_key(pair.native));
    }

    // Elsewhere, the answer is introduced only when the question supplies the
    // meaning — the question and answer are the two halves of one pairing.
    // The question being a bare word or short phrase is what distinguishes
    // "Vocal → Vowel" from "Which letter is silent? → hache", where the
    // question describes a property instead of giving the meaning.
    if (WordPair.looksLikeWord(exercise.question)) {
      words
        ..add(_key(exercise.correctAnswer))
        ..add(_key(exercise.question));
    }

    words.remove('');
    return words;
  }

  /// The word an exercise asks the learner for, if it is identifiable.
  ///
  /// Applies to recognition exercises too, not just production ones: being
  /// shown "hache" among four options you have never met is still being
  /// tested on it. An exercise that introduces its own answer — a match
  /// pair, or a question that supplies the meaning — is not testing it.
  static String? wordAsked(Exercise exercise) {
    final key = _key(exercise.correctAnswer);
    if (key.isEmpty) return null;
    // Self-introducing: the exercise hands over the meaning itself.
    if (wordsTaught(exercise).contains(key)) return null;
    return key;
  }

  /// Arranges [exercises] into teaching order.
  ///
  /// Three groups, in order: exercises that introduce words; exercises whose
  /// word has by then been introduced; and last, exercises asking for a word
  /// this skill never introduces anywhere.
  ///
  /// That last group is the content gap made visible rather than hidden. The
  /// exercises still run — dropping them would silently shrink the course —
  /// but only after the learner has had every chance the skill offers to meet
  /// the word.
  static List<Exercise> arrange(List<Exercise> exercises) {
    // What the skill introduces anywhere in itself, since a later exercise
    // can be the one that teaches an earlier exercise's word.
    final introduced = <String>{
      for (final exercise in exercises) ...wordsTaught(exercise),
    };

    final introducing = <Exercise>[];
    final supported = <Exercise>[];
    final unsupported = <Exercise>[];

    for (final exercise in exercises) {
      final asked = wordAsked(exercise);
      if (asked == null) {
        // Introduces its word, or has no single word to ask for.
        introducing.add(exercise);
      } else if (introduced.contains(asked)) {
        supported.add(exercise);
      } else {
        unsupported.add(exercise);
      }
    }

    // Shuffle within groups, never across them: variety between runs without
    // losing the guarantee that introduction precedes testing.
    introducing.shuffle();
    supported.shuffle();
    unsupported.shuffle();

    // Within the supported group, recognition before production: seeing a
    // word among options is the gentler step toward having to produce it.
    supported.sort((a, b) {
      final aTeaches = teaches(a) ? 0 : 1;
      final bTeaches = teaches(b) ? 0 : 1;
      return aTeaches.compareTo(bTeaches);
    });

    return [...introducing, ...supported, ...unsupported];
  }

  /// Words the skill tests but never introduces — the content gap, per skill.
  ///
  /// Exposed for tooling: this is what an author needs to see to know which
  /// introductions are missing.
  static Set<String> untaughtWords(List<Exercise> exercises) {
    final introduced = <String>{
      for (final exercise in exercises) ...wordsTaught(exercise),
    };
    return {
      for (final exercise in exercises)
        if (wordAsked(exercise) case final word?)
          if (!introduced.contains(word)) word,
    };
  }

  /// Words are compared case- and accent-insensitively so an exercise that
  /// shows "Hache" counts as teaching the word a later one asks for as
  /// "hache".
  static String _key(String raw) => WordKnowledge.normaliseWord(raw);
}
