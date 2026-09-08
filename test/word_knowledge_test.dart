import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lingua_sprint/models/word_knowledge.dart';
import 'package:lingua_sprint/providers/word_knowledge_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('word normalisation', () {
    test('folds case, accents and decorating punctuation', () {
      expect(WordKnowledge.normaliseWord('¡Hola!'), 'hola');
      expect(WordKnowledge.normaliseWord('  CAFÉ '), 'cafe');
      expect(WordKnowledge.normaliseWord('Niño'), 'nino');
      // Same word reached two ways must collapse to one entry, or a learner
      // has to learn it twice.
      expect(
        WordKnowledge.normaliseWord('¿Qué?'),
        WordKnowledge.normaliseWord('que'),
      );
    });
  });

  group('promotion', () {
    test('three fast correct answers retire a word', () {
      var word = const WordKnowledge(word: 'gato');
      const fast = Duration(milliseconds: 900);

      for (var i = 0; i < WordKnowledge.fastCorrectToKnow; i++) {
        expect(word.isKnown, isFalse, reason: 'known too early at $i');
        word = word.afterAnswer(correct: true, elapsed: fast);
      }

      expect(word.isKnown, isTrue);
      expect(word.timesSeen, WordKnowledge.fastCorrectToKnow);
    });

    test('slow correct answers keep a word in rotation', () {
      var word = const WordKnowledge(word: 'gato');
      const slow = Duration(seconds: 6);

      for (var i = 0; i < 6; i++) {
        word = word.afterAnswer(correct: true, elapsed: slow);
      }

      // Correct but laboured is exactly the case that still needs practice.
      expect(word.isKnown, isFalse);
      expect(word.confidence, WordConfidence.learning);
      expect(word.correctStreak, 6);
    });

    test('a miss resets progress toward known', () {
      var word = const WordKnowledge(word: 'gato');
      const fast = Duration(milliseconds: 500);

      word = word.afterAnswer(correct: true, elapsed: fast);
      word = word.afterAnswer(correct: true, elapsed: fast);
      word = word.afterAnswer(correct: false, elapsed: fast);

      expect(word.fastCorrect, 0);
      expect(word.correctStreak, 0);
      expect(word.isKnown, isFalse);
    });

    test('missing a declared-known word pulls it back into rotation', () {
      final declared = const WordKnowledge(word: 'gato').asDeclaredKnown();
      expect(declared.isKnown, isTrue);

      final missed = declared.afterAnswer(
        correct: false,
        elapsed: const Duration(seconds: 1),
      );

      // Claiming a word then missing it is the case the drill exists to catch.
      expect(missed.isKnown, isFalse);
      expect(missed.confidence, WordConfidence.learning);
    });
  });

  group('WordKnowledgeProvider', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('declaring known survives a reload', () async {
      final provider = WordKnowledgeProvider();
      await provider.load('spanish');
      await provider.declareKnown('¡Hola!');
      await provider.flushPending();

      final reloaded = WordKnowledgeProvider();
      await reloaded.load('spanish');

      // Normalisation must apply on lookup too, not just on write.
      expect(reloaded.isKnown('hola'), isTrue);
      expect(reloaded.knownCount, 1);
    });

    test('knowledge is kept per course', () async {
      final provider = WordKnowledgeProvider();
      await provider.load('spanish');
      await provider.declareKnown('gato');
      await provider.flushPending();

      await provider.load('french');
      expect(provider.isKnown('gato'), isFalse);
    });

    test('unseen is true only before a word is answered', () async {
      final provider = WordKnowledgeProvider();
      await provider.load('spanish');

      expect(provider.isUnseen('perro'), isTrue);
      await provider.recordAnswer('perro',
          correct: false, elapsed: const Duration(seconds: 1));
      expect(provider.isUnseen('perro'), isFalse);
    });

    test('bulk declaring marks every word known', () async {
      final provider = WordKnowledgeProvider();
      await provider.load('spanish');
      await provider.declareAllKnown(['uno', 'dos', 'tres']);

      expect(provider.knownCount, 3);
      expect(provider.isKnown('DOS'), isTrue);
    });
  });
}
