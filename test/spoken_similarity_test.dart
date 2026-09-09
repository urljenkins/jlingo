import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_sprint/widgets/exercises/speak_this_widget.dart';

void main() {
  group('spokenSimilarity', () {
    test('exact match scores 1.0', () {
      expect(spokenSimilarity('hola', 'hola'), 1.0);
    });

    test('ignores accents the recognizer drops', () {
      expect(spokenSimilarity('cafe', 'café'), 1.0);
      expect(spokenSimilarity('kilometro', 'kilómetro'), 1.0);
    });

    test('ignores punctuation and capitalisation', () {
      expect(spokenSimilarity('Perro carro', 'perro, carro'), 1.0);
    });

    test('ignores word order', () {
      expect(spokenSimilarity('carro perro', 'perro carro'), 1.0);
    });

    test('a repeated-phrase recognizer glitch still passes a good attempt', () {
      // The recognizer sometimes echoes the phrase; extra copies of correct
      // words must not drag the score down.
      expect(
        spokenSimilarity('perro carro perro carro', 'perro carro'),
        greaterThan(0.7),
      );
    });

    test('a genuinely wrong attempt fails', () {
      // "pero"/"caro" are the single-R mistakes this exercise tests against,
      // and "ferrocarril" was dropped entirely.
      expect(
        spokenSimilarity('pero caro pero caro', 'perro carro ferrocarril'),
        lessThan(0.7),
      );
    });

    test('empty spoken input scores 0', () {
      expect(spokenSimilarity('', 'hola'), 0.0);
    });

    test('a close single-word attempt passes', () {
      expect(spokenSimilarity('kilometros', 'kilómetro'), greaterThan(0.7));
    });
  });
}
