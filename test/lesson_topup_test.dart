import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_sprint/models/exercise.dart';
import 'package:lingua_sprint/models/word_pair.dart';
import 'package:lingua_sprint/services/lesson_topup.dart';
import 'package:lingua_sprint/services/word_pool.dart';

/// A pool the size of a real course deck, in two categories so the
/// same-category distractor path is exercised.
WordPool _pool({int count = 40}) => WordPool([
      for (var i = 0; i < count; i++)
        WordPair(
          target: 'palabra$i',
          native: 'word$i',
          category: i.isEven ? 'Greetings' : 'Food',
        ),
    ]);

Exercise _authored(String id, {String answer = 'algo'}) => Exercise(
      id: id,
      type: ExerciseType.translateThis,
      question: 'Question $id',
      options: const [],
      correctAnswer: answer,
    );

void main() {
  group('LessonTopUp.extend', () {
    test('pads a five-exercise skill to a full lesson', () {
      final authored = [for (var i = 0; i < 5; i++) _authored('a$i')];

      final result = LessonTopUp.extend(
        authored: authored,
        pool: _pool(),
        seed: 1,
      );

      expect(result.length, LessonTopUp.targetLength);
      // The authored exercises lead, untouched and in order.
      expect(
        result.take(5).map((e) => e.id),
        authored.map((e) => e.id),
      );
    });

    test('leaves a skill that is already long enough alone', () {
      final authored = [for (var i = 0; i < 20; i++) _authored('a$i')];

      final result = LessonTopUp.extend(
        authored: authored,
        pool: _pool(),
        seed: 1,
      );

      expect(result, same(authored));
    });

    test('gives a different lesson on a repeat visit', () {
      final authored = [for (var i = 0; i < 5; i++) _authored('a$i')];

      List<String> questionsFor(int seed) => LessonTopUp.extend(
            authored: authored,
            pool: _pool(),
            seed: seed,
          ).skip(5).map((e) => e.question).toList();

      // This is the actual complaint: five exercises, then the same five.
      expect(questionsFor(1), isNot(equals(questionsFor(17))));
    });

    test('does not top up when the pool is too thin to build from', () {
      final authored = [for (var i = 0; i < 5; i++) _authored('a$i')];

      final result = LessonTopUp.extend(
        authored: authored,
        pool: _pool(count: 3),
        seed: 1,
      );

      // Three pairs cannot furnish an answer plus three distractors, and a
      // question with two options is worse than no question.
      expect(result, same(authored));
    });

    test('never asks for a word the skill already covers', () {
      final authored = [_authored('a0', answer: 'word3')];

      final result = LessonTopUp.extend(
        authored: authored,
        pool: WordPool([
          const WordPair(target: 'word3', native: 'covered'),
          for (var i = 0; i < 10; i++)
            WordPair(target: 'otro$i', native: 'other$i'),
        ]),
        seed: 0,
      );

      final generated = result.skip(1);
      expect(
        generated.where((e) => e.question.toLowerCase() == 'word3'),
        isEmpty,
      );
    });

    test('every generated choice has four options and a correct answer', () {
      final result = LessonTopUp.extend(
        authored: [_authored('a0')],
        pool: _pool(),
        seed: 5,
      );

      final choices =
          result.where((e) => e.type == ExerciseType.multipleChoice);
      expect(choices, isNotEmpty);
      for (final exercise in choices) {
        expect(exercise.options, hasLength(4));
        expect(exercise.options, contains(exercise.correctAnswer));
        // Duplicate options would put two right-looking answers on screen.
        expect(exercise.options.toSet(), hasLength(4));
      }
    });

    test('generated exercises are marked as generated', () {
      final result = LessonTopUp.extend(
        authored: [_authored('a0')],
        pool: _pool(),
        seed: 2,
      );

      for (final exercise in result.skip(1)) {
        expect(exercise.metadata?['generated'], isTrue);
      }
    });

    test('the match exercise carries usable pairs', () {
      final result = LessonTopUp.extend(
        authored: [_authored('a0')],
        pool: _pool(),
        seed: 3,
      );

      final match = result.firstWhere((e) => e.type == ExerciseType.matchPairs);
      final pairs = WordPair.fromMatchPairs(match);
      expect(pairs, hasLength(4));
      // A match with a repeated side is unsolvable.
      expect(pairs.map((p) => p.target).toSet(), hasLength(4));
      expect(pairs.map((p) => p.native).toSet(), hasLength(4));
    });
  });
}
