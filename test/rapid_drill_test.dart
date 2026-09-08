import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lingua_sprint/models/flashcard.dart';
import 'package:lingua_sprint/models/word_pair.dart';
import 'package:lingua_sprint/services/word_pool.dart';
import 'package:lingua_sprint/widgets/drills/waterfall_match_drill.dart';
import 'package:lingua_sprint/widgets/drills/word_flash_drill.dart';

WordPool _pool(int count) => WordPool.build(
      deck: FlashcardDeck(
        id: 'd',
        name: 'Deck',
        description: '',
        targetLanguage: 'es-ES',
        nativeLanguage: 'en-US',
        cards: [
          for (var i = 0; i < count; i++)
            Flashcard(
              id: 'c$i',
              front: 'palabra$i',
              back: 'word$i',
            ),
        ],
        createdAt: DateTime(2026),
      ),
    );

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('WordFlashDrill', () {
    testWidgets('options appear only after the word has flashed',
        (tester) async {
      await tester.pumpWidget(_host(WordFlashDrill(
        pool: _pool(8),
        onAnswer: (_, __, ___) {},
        onDeclareKnown: (_) {},
      )));

      // Before the flash elapses the options are rendered but transparent —
      // the beat that makes it a flash rather than a multiple-choice card.
      final fade = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity).first,
      );
      expect(fade.opacity, 0);

      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();

      final revealed = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity).first,
      );
      expect(revealed.opacity, 1);
    });

    testWidgets('tapping an option reports the answer with elapsed time',
        (tester) async {
      WordPair? answered;
      bool? wasCorrect;
      Duration? elapsed;

      final pool = _pool(8);
      await tester.pumpWidget(_host(WordFlashDrill(
        pool: pool,
        onAnswer: (pair, correct, took) {
          answered = pair;
          wasCorrect = correct;
          elapsed = took;
        },
        onDeclareKnown: (_) {},
      )));

      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();

      // Find the word on screen, then tap its true meaning.
      final target = tester.widget<Text>(find.byType(Text).at(2)).data;
      final expected = pool.pairs.firstWhere((p) => p.target == target).native;

      await tester.tap(find.text(expected));
      await tester.pump();

      expect(answered?.target, target);
      expect(wasCorrect, isTrue);
      expect(elapsed, isNotNull);
    });

    testWidgets('"I know this" retires the word without an answer',
        (tester) async {
      WordPair? declared;
      var answers = 0;

      await tester.pumpWidget(_host(WordFlashDrill(
        pool: _pool(8),
        onAnswer: (_, __, ___) => answers++,
        onDeclareKnown: (pair) => declared = pair,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.text('I know this'));
      await tester.pump();

      expect(declared, isNotNull);
      // Declaring is not an answer — it must not count as practice.
      expect(answers, 0);
    });

    testWidgets('an empty pool states why rather than rendering a drill',
        (tester) async {
      await tester.pumpWidget(_host(WordFlashDrill(
        pool: const WordPool([]),
        onAnswer: (_, __, ___) {},
        onDeclareKnown: (_) {},
      )));

      expect(find.textContaining('marked known'), findsOneWidget);
    });
  });

  group('WaterfallMatchDrill', () {
    testWidgets('shows a live window rather than the whole pool',
        (tester) async {
      await tester.pumpWidget(_host(WaterfallMatchDrill(
        pool: _pool(30),
        onAnswer: (_, __, ___) {},
        onDeclareKnown: (_) {},
        windowSize: 5,
      )));
      await tester.pumpAndSettle();

      // Five pairs live means five target tiles, not thirty.
      final shown = <String>[
        for (var i = 0; i < 30; i++)
          if (find.text('palabra$i').evaluate().isNotEmpty) 'palabra$i',
      ];
      expect(shown.length, 5);
    });

    testWidgets('a matched pair clears and the window refills', (tester) async {
      await tester.pumpWidget(_host(WaterfallMatchDrill(
        pool: _pool(30),
        onAnswer: (_, __, ___) {},
        onDeclareKnown: (_) {},
        windowSize: 5,
      )));
      await tester.pumpAndSettle();

      final live = <String>[
        for (var i = 0; i < 30; i++)
          if (find.text('palabra$i').evaluate().isNotEmpty) 'palabra$i',
      ];
      final first = live.first;
      final index = first.replaceAll('palabra', '');

      await tester.tap(find.text(first));
      await tester.pump();
      await tester.tap(find.text('word$index'));
      await tester.pumpAndSettle();

      // The cleared pair is gone and the window is topped back up.
      expect(find.text(first), findsNothing);
      final after = <String>[
        for (var i = 0; i < 30; i++)
          if (find.text('palabra$i').evaluate().isNotEmpty) 'palabra$i',
      ];
      expect(after.length, 5);
    });

    testWidgets('long-press retires a word and refills its slot',
        (tester) async {
      WordPair? declared;

      await tester.pumpWidget(_host(WaterfallMatchDrill(
        pool: _pool(30),
        onAnswer: (_, __, ___) {},
        onDeclareKnown: (pair) => declared = pair,
        windowSize: 5,
      )));
      await tester.pumpAndSettle();

      final live = <String>[
        for (var i = 0; i < 30; i++)
          if (find.text('palabra$i').evaluate().isNotEmpty) 'palabra$i',
      ];

      await tester.longPress(find.text(live.first));
      await tester.pumpAndSettle();

      expect(declared?.target, live.first);
      expect(find.text(live.first), findsNothing);
    });
  });
}
