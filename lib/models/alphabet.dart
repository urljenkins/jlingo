/// One entry in a course's alphabet chart.
///
/// A letter is not just a glyph: what a learner needs is the symbol, what the
/// letter is *called* when you recite the alphabet, how it *sounds* inside a
/// word, and an English anchor for that sound. These are four different
/// things and conflating them is why alphabet charts are usually useless —
/// Spanish "H" is called "hache" but sounds like nothing at all.
class LetterSound {
  const LetterSound({
    required this.letter,
    required this.name,
    required this.ipa,
    required this.soundHint,
    this.example,
    this.exampleMeaning,
    this.note,
  });

  /// The glyph as written, e.g. "Ñ" or "し".
  final String letter;

  /// What the letter is called when reciting the alphabet ("eñe").
  ///
  /// This is what gets spoken aloud, because it is the answer to "what is
  /// this letter?" — the sound alone is often not pronounceable in isolation.
  final String name;

  /// Phonetic spelling of [name], in IPA.
  final String ipa;

  /// How the letter sounds inside a word, anchored to English where honest.
  final String soundHint;

  /// A short word in the target language showing the letter at work.
  final String? example;

  final String? exampleMeaning;

  /// Anything irregular worth flagging — silent letters, context-dependent
  /// sounds, letters that only appear in loanwords.
  final String? note;
}

/// A course's alphabet, grouped into sections.
///
/// Sections exist because not every writing system is one flat A-Z. Japanese
/// needs hiragana and katakana kept apart; Spanish benefits from separating
/// the vowels, which are the five sounds everything else is built on.
class AlphabetSection {
  const AlphabetSection({
    required this.title,
    required this.letters,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<LetterSound> letters;
}

class Alphabet {
  const Alphabet({
    required this.languageCode,
    required this.sections,
    this.note,
  });

  /// BCP-47 code used for text-to-speech, e.g. "es-ES".
  final String languageCode;

  final List<AlphabetSection> sections;

  /// A sentence about the writing system as a whole, shown above the chart.
  final String? note;

  List<LetterSound> get allLetters =>
      [for (final section in sections) ...section.letters];
}
