import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_sprint/models/flashcard.dart';
import 'package:lingua_sprint/providers/flashcard_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bundled decks grow over time. A learner who opened a course last year has a
/// saved snapshot of the deck as it was then, so new cards only reach them if
/// the saved deck is merged with the bundled one — and that merge must not
/// disturb the review state they have built up.

Flashcard _card(String id, {int repetitions = 0, double ease = 2.5}) =>
    Flashcard(
      id: id,
      front: 'front-$id',
      back: 'back-$id',
      category: 'Test',
      repetitions: repetitions,
      easeFactor: ease,
      interval: repetitions > 0 ? 6 : 0,
      nextReviewDate: repetitions > 0 ? DateTime(2030) : null,
    );

FlashcardDeck _deck(String id, List<Flashcard> cards) => FlashcardDeck(
      id: id,
      name: 'Test deck',
      description: 'test',
      targetLanguage: 'es-ES',
      nativeLanguage: 'en-US',
      cards: cards,
      createdAt: DateTime(2024),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a saved deck keeps its review state when new cards arrive', () async {
    // Simulate a learner who has already studied two cards.
    final saved = _deck('spanish_flashcards', [
      _card('fc_es_greet_1', repetitions: 4, ease: 2.9),
      _card('fc_es_greet_2', repetitions: 2, ease: 1.7),
    ]);
    SharedPreferences.setMockInitialValues({
      'flashcard_decks_spanish_en': jsonEncode([saved.toJson()]),
    });

    final provider = FlashcardProvider();
    await provider.loadDecks('spanish_en');

    final deck = provider.decks.firstWhere((d) => d.id == saved.id);

    // The bundled deck is far larger than the two saved cards.
    expect(deck.cards.length, greaterThan(2),
        reason: 'new bundled cards should have been adopted');

    final studied = deck.cards.firstWhere((c) => c.id == 'fc_es_greet_1');
    expect(studied.repetitions, 4, reason: 'review history was lost');
    expect(studied.easeFactor, 2.9, reason: 'ease factor was reset');

    final struggled = deck.cards.firstWhere((c) => c.id == 'fc_es_greet_2');
    expect(struggled.easeFactor, 1.7,
        reason: 'a hard card was reset to default ease');
  });

  test('adopted cards arrive unstudied', () async {
    final saved = _deck('spanish_flashcards', [
      _card('fc_es_greet_1', repetitions: 3),
    ]);
    SharedPreferences.setMockInitialValues({
      'flashcard_decks_spanish_en': jsonEncode([saved.toJson()]),
    });

    final provider = FlashcardProvider();
    await provider.loadDecks('spanish_en');

    final deck = provider.decks.firstWhere((d) => d.id == saved.id);
    final adopted = deck.cards.where((c) => c.id != 'fc_es_greet_1').toList();

    expect(adopted, isNotEmpty);
    expect(adopted.every((c) => c.isNew), isTrue,
        reason: 'newly adopted cards must start unstudied');
  });

  test('merging twice adds nothing the second time', () async {
    final provider = FlashcardProvider();
    await provider.loadDecks('spanish_en');
    final first = provider.decks.first.cards.length;

    final again = FlashcardProvider();
    await again.loadDecks('spanish_en');

    expect(again.decks.first.cards.length, first,
        reason: 'a second load duplicated cards');
  });

  test('a fresh install seeds the full bundled deck', () async {
    final provider = FlashcardProvider();
    await provider.loadDecks('spanish_en');

    expect(provider.decks, isNotEmpty);
    expect(provider.decks.first.cards.length, greaterThan(100),
        reason: 'the expanded deck should be seeded in full');
  });
}
