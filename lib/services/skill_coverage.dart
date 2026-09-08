import '../models/exercise.dart';
import '../models/skill.dart';
import '../models/word_pair.dart';

/// What a skill actually covers, derived from its exercises.
///
/// The syllabus needs to answer "what is in this topic?" before the learner
/// commits to it. Nothing in the content files states that directly — the
/// skill carries a one-line description and a pile of exercises — so it is
/// read back out of the exercises themselves.
///
/// Derived rather than authored on purpose: a hand-written summary drifts
/// from the content the moment an exercise is added, and with 552 skill
/// files no one would keep them in step.
class SkillCoverage {
  const SkillCoverage({
    required this.vocabulary,
    required this.types,
    required this.exerciseCount,
    required this.hasAudio,
    required this.needsMicrophone,
  });

  /// The word pairs the skill puts in front of the learner, in the order the
  /// content introduces them.
  final List<WordPair> vocabulary;

  /// Exercise types present, most frequent first — a fair picture of what
  /// the lesson will feel like to sit through.
  final List<ExerciseType> types;

  final int exerciseCount;

  /// Whether any exercise plays audio, so the learner knows to bring sound.
  final bool hasAudio;

  /// Whether any exercise wants the microphone — worth knowing before you
  /// start a lesson on a bus.
  final bool needsMicrophone;

  bool get isEmpty => exerciseCount == 0;

  static SkillCoverage of(Skill skill) {
    final vocabulary = <WordPair>[];
    final seen = <String>{};

    void add(WordPair? pair) {
      if (pair == null) return;
      final key = pair.target.trim().toLowerCase();
      if (key.isEmpty || !seen.add(key)) return;
      vocabulary.add(pair);
    }

    final counts = <ExerciseType, int>{};
    var hasAudio = false;
    var needsMicrophone = false;

    for (final exercise in skill.exercises) {
      counts.update(exercise.type, (n) => n + 1, ifAbsent: () => 1);

      add(WordPair.fromExercise(exercise));
      WordPair.fromMatchPairs(exercise).forEach(add);

      switch (exercise.type) {
        case ExerciseType.listeningComprehension:
        case ExerciseType.nativeAudio:
        case ExerciseType.dialogueListening:
        case ExerciseType.songFill:
        case ExerciseType.tapWhatYouHear:
          hasAudio = true;
        case ExerciseType.speakThis:
        case ExerciseType.pronunciationPractice:
          needsMicrophone = true;
        default:
          break;
      }
    }

    final types = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));

    return SkillCoverage(
      vocabulary: vocabulary,
      types: types,
      exerciseCount: skill.exercises.length,
      hasAudio: hasAudio,
      needsMicrophone: needsMicrophone,
    );
  }
}
