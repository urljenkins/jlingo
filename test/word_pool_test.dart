import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lingua_sprint/models/exercise.dart';
import 'package:lingua_sprint/models/flashcard.dart';
import 'package:lingua_sprint/models/skill.dart';
import 'package:lingua_sprint/models/word_pair.dart';
import 'package:lingua_sprint/providers/word_knowledge_provider.dart';
import 'package:lingua_sprint/services/word_pool.dart';

Exercise _exercise({
  required String id,
  required ExerciseType type,
  required String question,
  required String answer,
  Map<String, dynamic>? metadata,
}) =>
    Exercise(
      id: id,
      type: type,
      question: question,
      options: const [],
      correctAnswer: answer,
      metadata: metadata,
    );

FlashcardDeck _deck(List<Flashcard> cards) => FlashcardDeck(
      id: 'd',
      name: 'Deck',
      description: '',
      targetLanguage: 'es-ES',
      nativeLanguage: 'en-US',
      cards: cards,
      createdAt: DateTime(2026),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('word-shape filter', () {
    test('accepts short vocabulary items', () {
      expect(WordPair.looksLikeWord('gato'), isTrue);
      expect(WordPair.looksLikeWord('el perro'), isTrue);
      expect(WordPair.looksLikeWord('¡Hola!'), isTrue);
    });

    test('rejects sentences, gapped prompts and overlong strings', () {
      // This is what keeps the 77% of sentence-shaped skill answers out of
      // the drills.
      expect(
        WordPair.looksLikeWord('Take this medicine three times a day'),
        isFalse,
      );
      expect(
        WordPair.looksLikeWord('La ___ es una letra que no se pronuncia'),
        isFalse,
      );
      expect(WordPair.looksLikeWord('Hola. Buenos dias'), isFalse);
      expect(WordPair.looksLikeWord(''), isFalse);
    });

    test('uses a tighter budget for space-free scripts', () {
      // A CJK sentence has no spaces, so a word-count test alone would
      // wave it through.
      expect(WordPair.looksLikeWord('猫'), isTrue);
      expect(WordPair.looksLikeWord('这种药一天吃三次'), isFalse);
    });
  });

  group('pool building', () {
    test('merges skill words with deck cards and dedupes by target', () {
      final skill = Skill(
        id: 's',
        name: 'Skill',
        description: '',
        level: 1,
        exercises: [
          _exercise(
            id: 'e1',
            type: ExerciseType.translateThis,
            question: 'gato',
            answer: 'cat',
          ),
          // Sentence-shaped: must not reach the drill.
          _exercise(
            id: 'e2',
            type: ExerciseType.translateThis,
            question: 'Take this medicine three times a day',
            answer: 'Tome este medicamento',
          ),
          _exercise(
            id: 'e3',
            type: ExerciseType.matchPairs,
            question: 'Match',
            answer: '',
            metadata: {
              'pairs': [
                {'target': 'perro', 'native': 'dog'},
              ],
            },
          ),
        ],
      );

      final deck = _deck([
        Flashcard(id: 'c1', front: 'gato', back: 'cat (deck)'),
        Flashcard(id: 'c2', front: 'casa', back: 'house'),
      ]);

      final pool = WordPool.build(deck: deck, skill: skill);
      final targets = pool.pairs.map((p) => p.target).toList();

      expect(targets, containsAll(['gato', 'perro', 'casa']));
      expect(targets.length, 3, reason: 'sentence excluded, gato deduped');

      // The skill's phrasing wins, since it is what the learner just saw.
      final gato = pool.pairs.firstWhere((p) => p.target == 'gato');
      expect(gato.native, 'cat');
    });

    test('excludingKnown drops retired words', () async {
      SharedPreferences.setMockInitialValues({});
      final knowledge = WordKnowledgeProvider();
      await knowledge.load('spanish');
      await knowledge.declareKnown('gato');

      final pool = WordPool.build(
        deck: _deck([
          Flashcard(id: 'c1', front: 'gato', back: 'cat'),
          Flashcard(id: 'c2', front: 'casa', back: 'house'),
        ]),
      );

      final active = pool.excludingKnown(knowledge);
      expect(active.pairs.map((p) => p.target), ['casa']);
    });

    test('partitionBySeen separates untaught words', () async {
      SharedPreferences.setMockInitialValues({});
      final knowledge = WordKnowledgeProvider();
      await knowledge.load('spanish');
      await knowledge.recordAnswer('gato',
          correct: true, elapsed: const Duration(seconds: 3));

      final pool = WordPool.build(
        deck: _deck([
          Flashcard(id: 'c1', front: 'gato', back: 'cat'),
          Flashcard(id: 'c2', front: 'casa', back: 'house'),
        ]),
      );

      final split = pool.partitionBySeen(knowledge);
      expect(split.seen.map((p) => p.target), ['gato']);
      expect(split.unseen.map((p) => p.target), ['casa']);
    });

    test('distractors prefer the same category and exclude the answer', () {
      final pool = WordPool.build(
        deck: _deck([
          Flashcard(id: '1', front: 'gato', back: 'cat', category: 'Animals'),
          Flashcard(id: '2', front: 'perro', back: 'dog', category: 'Animals'),
          Flashcard(id: '3', front: 'pez', back: 'fish', category: 'Animals'),
          Flashcard(id: '4', front: 'ave', back: 'bird', category: 'Animals'),
          Flashcard(id: '5', front: 'casa', back: 'house', category: 'Home'),
        ]),
      );

      final answer = pool.pairs.firstWhere((p) => p.target == 'gato');
      final distractors = pool.distractorsFor(answer);

      expect(distractors.length, 3);
      expect(distractors.contains(answer), isFalse);
      // Same-category options make it a real discrimination, not a guess.
      expect(distractors.every((d) => d.category == 'Animals'), isTrue);
    });

    test('distractors fall back across categories in a thin pool', () {
      final pool = WordPool.build(
        deck: _deck([
          Flashcard(id: '1', front: 'gato', back: 'cat', category: 'Animals'),
          Flashcard(id: '2', front: 'casa', back: 'house', category: 'Home'),
          Flashcard(id: '3', front: 'mesa', back: 'table', category: 'Home'),
        ]),
      );

      final answer = pool.pairs.firstWhere((p) => p.target == 'gato');
      final distractors = pool.distractorsFor(answer);

      // Only two other words exist; the drill must still run.
      expect(distractors.length, 2);
      expect(distractors.contains(answer), isFalse);
    });
  });

  group('inlined readings', () {
    test('splits a parenthesised romanisation off the word', () {
      // The Chinese and Japanese decks write fronts as "你好 (Nǐ hǎo)".
      final split = WordPair.splitReading('你好 (Nǐ hǎo)');
      expect(split.word, '你好');
      expect(split.reading, 'Nǐ hǎo');

      final plain = WordPair.splitReading('gato');
      expect(plain.word, 'gato');
      expect(plain.reading, isNull);
    });

    test('a card with an inlined reading still reaches the pool', () {
      final pool = WordPool.build(
        deck: _deck([
          Flashcard(id: 'c1', front: '你好 (Nǐ hǎo)', back: 'Hello'),
        ]),
      );

      // Drilled as-is this would be rejected as too long for a CJK item.
      expect(pool.pairs.single.target, '你好');
      expect(pool.pairs.single.pronunciation, 'Nǐ hǎo');
    });

    test('an authored pronunciation is not overwritten', () {
      final pool = WordPool.build(
        deck: _deck([
          Flashcard(
            id: 'c1',
            front: 'café (kah-FEH)',
            back: 'coffee',
            pronunciation: '/kaˈfe/',
          ),
        ]),
      );

      expect(pool.pairs.single.pronunciation, '/kaˈfe/');
    });
  });
}
