import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_sprint/widgets/exercises/translate_this_widget.dart';

void main() {
  group('TranslateThisWidget.isAnswerMatch', () {
    test('matches exact answer case-insensitively', () {
      expect(TranslateThisWidget.isAnswerMatch('hello', 'Hello'), isTrue);
      expect(TranslateThisWidget.isAnswerMatch('HELLO', 'Hello'), isTrue);
    });

    test('ignores terminal and internal punctuation', () {
      expect(
        TranslateThisWidget.isAnswerMatch(
          'See you soon have a good day',
          'See you soon, have a good day!',
        ),
        isTrue,
      );
      expect(TranslateThisWidget.isAnswerMatch('cheers', '¡Salud! / Cheers!'),
          isTrue);
    });

    test('accepts slash-separated alternatives', () {
      expect(
          TranslateThisWidget.isAnswerMatch("That's fine", "That's fine / OK"),
          isTrue);
      expect(
          TranslateThisWidget.isAnswerMatch('OK', "That's fine / OK"), isTrue);
      expect(
          TranslateThisWidget.isAnswerMatch('ok', "That's fine / OK"), isTrue);
    });

    test('ignores explanatory parentheticals in target', () {
      expect(
        TranslateThisWidget.isAnswerMatch(
          'How did you wake up',
          'How did you wake up? (informal, Latin America)',
        ),
        isTrue,
      );
      expect(
        TranslateThisWidget.isAnswerMatch(
          'Pleased to meet you',
          'Pleased to meet you (formal, female speaker)',
        ),
        isTrue,
      );
    });

    test('rejects incorrect answers', () {
      expect(TranslateThisWidget.isAnswerMatch('goodbye', 'Hello'), isFalse);
      expect(TranslateThisWidget.isAnswerMatch('', 'Hello'), isFalse);
      expect(TranslateThisWidget.isAnswerMatch('   ', 'Hello'), isFalse);
    });
  });
}
