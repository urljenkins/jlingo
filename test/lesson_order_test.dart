import 'package:flutter_test/flutter_test.dart';

import 'package:lingua_sprint/models/exercise.dart';
import 'package:lingua_sprint/services/lesson_order.dart';

Exercise _ex({
  required String id,
  required ExerciseType type,
  String question = 'q',
  List<String> options = const [],
  String answer = '',
  Map<String, dynamic>? metadata,
}) =>
    Exercise(
      id: id,
      type: type,
      question: question,
      options: options,
      correctAnswer: answer,
      metadata: metadata,
    );

int _indexOf(List<Exercise> list, String id) =>
    list.indexWhere((e) => e.id == id);

void main() {
  group('teaching classification', () {
    test('exercises that reveal their answer can teach', () {
      expect(
        LessonOrder.teaches(_ex(id: 'a', type: ExerciseType.multipleChoice)),
        isTrue,
      );
      expect(
        LessonOrder.teaches(_ex(id: 'b', type: ExerciseType.matchPairs)),
        isTrue,
      );
    });

    test('exercises demanding production do not teach', () {
      expect(
        LessonOrder.teaches(_ex(id: 'a', type: ExerciseType.translateThis)),
        isFalse,
      );
      expect(
        LessonOrder.teaches(_ex(id: 'b', type: ExerciseType.speakThis)),
        isFalse,
      );
    });

    test('fill-in-the-blank teaches only when options are shown', () {
      // With options it is recognition; without, it is recall, and recall
      // cannot introduce a word.
      final withOptions = _ex(
        id: 'a',
        type: ExerciseType.fillInBlank,
        options: ['hache', 'eñe', 'elle'],
        answer: 'hache',
      );
      final typed = _ex(
        id: 'b',
        type: ExerciseType.fillInBlank,
        answer: 'hache',
      );

      expect(LessonOrder.teaches(withOptions), isTrue);
      expect(LessonOrder.teaches(typed), isFalse);
    });
  });

  group('arrangement', () {
    test('teaching exercises precede the tests that need them', () {
      final exercises = [
        _ex(
          id: 'test',
          type: ExerciseType.translateThis,
          question: 'gato',
          answer: 'cat',
        ),
        _ex(
          id: 'teach',
          type: ExerciseType.multipleChoice,
          options: ['cat', 'dog'],
          answer: 'cat',
        ),
      ];

      // Run repeatedly: the tiers are shuffled internally, so a single pass
      // could pass by luck.
      for (var i = 0; i < 50; i++) {
        final ordered = LessonOrder.arrange(exercises);
        expect(
          _indexOf(ordered, 'teach'),
          lessThan(_indexOf(ordered, 'test')),
        );
      }
    });

    test('a word the skill never teaches is tested last', () {
      // This is the reported bug: "hache" is tested at position 3 of 101 and
      // introduced nowhere in the skill.
      final exercises = [
        _ex(
          id: 'hache',
          type: ExerciseType.fillInBlank,
          question: 'La ___ es una letra que no se pronuncia',
          answer: 'hache',
        ),
        for (var i = 0; i < 8; i++)
          _ex(
            id: 'other$i',
            type: ExerciseType.multipleChoice,
            options: ['A', 'E'],
            answer: 'A',
          ),
      ];

      for (var i = 0; i < 20; i++) {
        final ordered = LessonOrder.arrange(exercises);
        expect(_indexOf(ordered, 'hache'), ordered.length - 1);
      }
    });

    test('match pairs introduce both sides of every pair', () {
      final exercises = [
        _ex(
          id: 'test',
          type: ExerciseType.translateThis,
          question: 'perro',
          answer: 'dog',
        ),
        _ex(
          id: 'teach',
          type: ExerciseType.matchPairs,
          metadata: {
            'pairs': [
              {'target': 'perro', 'native': 'dog'},
            ],
          },
        ),
      ];

      for (var i = 0; i < 20; i++) {
        final ordered = LessonOrder.arrange(exercises);
        // Supported, so it must not be pushed to the unsupported tail.
        expect(_indexOf(ordered, 'test'), 1);
      }
    });

    test('word identity ignores case and accents', () {
      final exercises = [
        _ex(
          id: 'test',
          type: ExerciseType.translateThis,
          question: 'x',
          answer: 'CAFÉ',
        ),
        _ex(
          id: 'teach',
          type: ExerciseType.multipleChoice,
          options: ['cafe', 'te'],
          answer: 'cafe',
        ),
        _ex(
          id: 'orphan',
          type: ExerciseType.translateThis,
          question: 'y',
          answer: 'nunca',
        ),
      ];

      final ordered = LessonOrder.arrange(exercises);
      // "cafe" taught, "CAFÉ" tested — the same word, so not an orphan.
      expect(_indexOf(ordered, 'orphan'), ordered.length - 1);
      expect(_indexOf(ordered, 'test'), lessThan(_indexOf(ordered, 'orphan')));
    });

    test('every exercise survives the reordering', () {
      final exercises = [
        for (var i = 0; i < 12; i++)
          _ex(
            id: 'e$i',
            type: i.isEven
                ? ExerciseType.multipleChoice
                : ExerciseType.translateThis,
            options: i.isEven ? ['a', 'b'] : const [],
            answer: 'w$i',
          ),
      ];

      final ordered = LessonOrder.arrange(exercises);
      expect(ordered.length, exercises.length);
      expect(
        ordered.map((e) => e.id).toSet(),
        exercises.map((e) => e.id).toSet(),
      );
    });

    test('order varies between runs so lessons are not identical', () {
      final exercises = [
        for (var i = 0; i < 10; i++)
          _ex(
            id: 'e$i',
            type: ExerciseType.multipleChoice,
            options: ['a', 'b'],
            answer: 'w$i',
          ),
      ];

      final orders = {
        for (var i = 0; i < 20; i++)
          LessonOrder.arrange(exercises).map((e) => e.id).join(','),
      };
      expect(orders.length, greaterThan(1));
    });
  });

  group('untaughtWords', () {
    test('reports the words a skill tests but never introduces', () {
      final exercises = [
        _ex(
          id: 'teach',
          type: ExerciseType.multipleChoice,
          options: ['cat'],
          answer: 'cat',
        ),
        _ex(
          id: 'ok',
          type: ExerciseType.translateThis,
          question: 'gato',
          answer: 'cat',
        ),
        _ex(
          id: 'gap',
          type: ExerciseType.fillInBlank,
          answer: 'hache',
        ),
      ];

      expect(LessonOrder.untaughtWords(exercises), {'hache'});
    });
  });

  group('options are not introductions', () {
    test('seeing a word among four options does not teach it', () {
      // The reported bug in miniature: "hache" appears only as an option in
      // the exercise testing it. A one-in-four guess is not an introduction.
      final exercise = _ex(
        id: 'hache',
        type: ExerciseType.fillInBlank,
        question: 'La ___ es una letra que no se pronuncia',
        options: ['hache', 'eñe', 'elle', 'jota'],
        answer: 'hache',
      );

      expect(LessonOrder.wordsTaught(exercise), isEmpty);
      expect(LessonOrder.wordAsked(exercise), 'hache');
      expect(LessonOrder.untaughtWords([exercise]), {'hache'});
    });

    test('a question giving the meaning does introduce its answer', () {
      // "Vocal → Vowel" pairs word with meaning, so it teaches both.
      final exercise = _ex(
        id: 'vocal',
        type: ExerciseType.multipleChoice,
        question: 'Vocal',
        options: ['Vowel', 'Consonant'],
        answer: 'Vowel',
      );

      expect(
          LessonOrder.wordsTaught(exercise), containsAll(['vocal', 'vowel']));
      expect(LessonOrder.wordAsked(exercise), isNull);
    });

    test('distractors never count as taught words', () {
      final exercise = _ex(
        id: 'q',
        type: ExerciseType.multipleChoice,
        question: 'Gato',
        options: ['cat', 'elephant', 'giraffe'],
        answer: 'cat',
      );

      final taught = LessonOrder.wordsTaught(exercise);
      expect(taught, containsAll(['gato', 'cat']));
      // The wrong options are noise to reject, not vocabulary handed over.
      expect(taught, isNot(contains('elephant')));
      expect(taught, isNot(contains('giraffe')));
    });
  });
}
