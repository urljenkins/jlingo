import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_sprint/models/alphabet.dart';
import 'package:lingua_sprint/services/alphabet_data.dart';

/// Every course the app ships, as the manifest ids name them.
const _courseIds = [
  'spanish_en',
  'spanish_latam_en',
  'french_en',
  'portuguese_en',
  'portuguese_br_en',
  'dutch_en',
  'japanese_en',
  'chinese_en',
];

void main() {
  group('AlphabetData', () {
    test('every course has a chart', () {
      for (final id in _courseIds) {
        expect(AlphabetData.forCourse(id), isNotNull, reason: id);
      }
    });

    test('an unknown course has none, rather than an empty chart', () {
      expect(AlphabetData.forCourse('klingon_en'), isNull);
      expect(AlphabetData.hasChart('klingon_en'), isFalse);
    });

    test('every letter is complete enough to render and speak', () {
      for (final id in _courseIds) {
        final alphabet = AlphabetData.forCourse(id)!;
        expect(alphabet.languageCode, isNotEmpty, reason: id);
        expect(alphabet.sections, isNotEmpty, reason: id);

        for (final letter in alphabet.allLetters) {
          final where = '$id/${letter.letter}';
          expect(letter.letter, isNotEmpty, reason: where);
          // The name is what TTS actually speaks; empty means a silent tile.
          expect(letter.name, isNotEmpty, reason: where);
          expect(letter.soundHint, isNotEmpty, reason: where);
          // IPA is rendered on the tile and must look like IPA.
          expect(letter.ipa, startsWith('/'), reason: where);
          expect(letter.ipa, endsWith('/'), reason: where);
        }
      }
    });

    test('letters are unique within a course', () {
      for (final id in _courseIds) {
        final letters =
            AlphabetData.forCourse(id)!.allLetters.map((l) => l.letter);
        // Selection is keyed by the glyph, so a duplicate would highlight and
        // expand two tiles at once.
        expect(letters.toSet(), hasLength(letters.length), reason: id);
      }
    });

    test('an example carries its meaning', () {
      for (final id in _courseIds) {
        for (final letter in AlphabetData.forCourse(id)!.allLetters) {
          if (letter.example != null && letter.example!.isNotEmpty) {
            expect(
              letter.exampleMeaning,
              isNotNull,
              reason: '$id/${letter.letter} has an example with no gloss',
            );
          }
        }
      }
    });

    test('the two Spanish courses differ where the dialects differ', () {
      final spain = AlphabetData.forCourse('spanish_en')!;
      final latam = AlphabetData.forCourse('spanish_latam_en')!;

      String ipaOf(Alphabet alphabet, String letter) => alphabet.allLetters
          .firstWhere((LetterSound l) => l.letter == letter)
          .ipa;

      // Z is "zeta" with /θ/ in Spain, /s/ across Latin America.
      expect(ipaOf(spain, 'Z'), contains('θ'));
      expect(ipaOf(latam, 'Z'), isNot(contains('θ')));
      expect(spain.languageCode, 'es-ES');
      expect(latam.languageCode, 'es-419');
    });

    test('the two Portuguese courses differ where the dialects differ', () {
      final pt = AlphabetData.forCourse('portuguese_en')!;
      final br = AlphabetData.forCourse('portuguese_br_en')!;

      expect(pt.languageCode, 'pt-PT');
      expect(br.languageCode, 'pt-BR');

      String hintOf(Alphabet alphabet, String letter) => alphabet.allLetters
          .firstWhere((LetterSound l) => l.letter == letter)
          .soundHint;

      // Brazilian T palatalises before I; European does not.
      expect(hintOf(br, 'T'), contains('cheese'));
      expect(hintOf(pt, 'T'), isNot(contains('cheese')));
    });

    test('the languageCode is a real BCP-47 tag TTS can use', () {
      for (final id in _courseIds) {
        expect(
          AlphabetData.forCourse(id)!.languageCode,
          matches(RegExp(r'^[a-z]{2}-[A-Z0-9]{2,3}$')),
          reason: id,
        );
      }
    });
  });
}
