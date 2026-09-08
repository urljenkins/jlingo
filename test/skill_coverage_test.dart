import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_sprint/models/exercise.dart';
import 'package:lingua_sprint/models/skill.dart';
import 'package:lingua_sprint/services/skill_coverage.dart';

Skill _skill(List<Exercise> exercises) => Skill(
      id: 's',
      name: 'Test skill',
      description: 'A skill',
      level: 1,
      exercises: exercises,
    );

Exercise _ex(
  ExerciseType type, {
  String question = 'q',
  String answer = 'a',
  Map<String, dynamic>? metadata,
}) =>
    Exercise(
      id: '$type-$question',
      type: type,
      question: question,
      options: const [],
      correctAnswer: answer,
      metadata: metadata,
    );

void main() {
  group('SkillCoverage', () {
    test('reads vocabulary out of translate and match exercises', () {
      final coverage = SkillCoverage.of(_skill([
        _ex(ExerciseType.translateThis, question: 'gato', answer: 'cat'),
        _ex(
          ExerciseType.matchPairs,
          metadata: {
            'pairs': [
              {'target': 'perro', 'native': 'dog'},
            ],
          },
        ),
      ]));

      expect(
        coverage.vocabulary.map((p) => p.target),
        containsAll(['gato', 'perro']),
      );
    });

    test('does not repeat a word taught twice', () {
      final coverage = SkillCoverage.of(_skill([
        _ex(ExerciseType.translateThis, question: 'gato', answer: 'cat'),
        _ex(ExerciseType.translateThis, question: 'Gato', answer: 'cat'),
      ]));

      expect(coverage.vocabulary, hasLength(1));
    });

    test('flags audio and microphone requirements', () {
      final quiet = SkillCoverage.of(_skill([
        _ex(ExerciseType.translateThis),
      ]));
      expect(quiet.hasAudio, isFalse);
      expect(quiet.needsMicrophone, isFalse);

      final loud = SkillCoverage.of(_skill([
        _ex(ExerciseType.nativeAudio),
        _ex(ExerciseType.pronunciationPractice),
      ]));
      expect(loud.hasAudio, isTrue);
      expect(loud.needsMicrophone, isTrue);
    });

    test('orders types by how often they appear', () {
      final coverage = SkillCoverage.of(_skill([
        _ex(ExerciseType.translateThis, question: 'a'),
        _ex(ExerciseType.multipleChoice, question: 'b'),
        _ex(ExerciseType.multipleChoice, question: 'c'),
        _ex(ExerciseType.multipleChoice, question: 'd'),
      ]));

      expect(coverage.types.first, ExerciseType.multipleChoice);
      expect(coverage.exerciseCount, 4);
    });

    test('an empty skill reports empty rather than throwing', () {
      final coverage = SkillCoverage.of(_skill([]));
      expect(coverage.isEmpty, isTrue);
      expect(coverage.vocabulary, isEmpty);
      expect(coverage.types, isEmpty);
    });
  });
}
