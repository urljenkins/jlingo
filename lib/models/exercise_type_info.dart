import 'package:flutter/material.dart';

import 'exercise.dart';

/// Broad grouping used to organise the exercise catalogue in settings and to
/// let a learner switch a whole skill area on or off in one go.
///
/// Declaration order is display order. Recall leads because those types make
/// up most of a lesson; speaking trails because it is the one most people
/// switch off, and it should not be the first thing the screen offers.
enum ExerciseCategory {
  recall('Vocabulary & Recall', Icons.style_outlined),
  reading('Reading & Writing', Icons.menu_book_outlined),
  listening('Listening', Icons.hearing_outlined),
  speaking('Speaking', Icons.mic_none_outlined);

  const ExerciseCategory(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Everything the UI needs to describe one exercise type: its short chip
/// label, the icon it is drawn with, the family it belongs to, and a plain
/// explanation of what the learner is actually asked to do.
///
/// This is the single source of truth for exercise-type presentation — the
/// home filter bar, the settings catalogue and the tutorial all read from it,
/// so a new type is described once and appears everywhere.
class ExerciseTypeInfo {
  const ExerciseTypeInfo({
    required this.type,
    required this.label,
    required this.icon,
    required this.category,
    required this.summary,
    required this.howItWorks,
    this.requiresMicrophone = false,
    this.requiresAudio = false,
  });

  final ExerciseType type;

  /// Short name used on chips and list rows.
  final String label;

  final IconData icon;
  final ExerciseCategory category;

  /// One line — what the exercise asks of you.
  final String summary;

  /// The full explanation: what you see, what you do, how it is marked.
  final String howItWorks;

  /// Needs speech recognition. Worth flagging: a learner practising in
  /// public may want these off without hunting for why they keep appearing.
  final bool requiresMicrophone;

  /// Plays audio, so it needs sound (or headphones) to be usable.
  final bool requiresAudio;

  static const List<ExerciseTypeInfo> all = [
    ExerciseTypeInfo(
      type: ExerciseType.translateThis,
      label: 'Translate',
      icon: Icons.translate_outlined,
      category: ExerciseCategory.recall,
      summary: 'Type the translation of a short word or phrase.',
      howItWorks:
          'You are shown a word or short phrase and type what it means in '
          'the other language. Your answer is compared to the expected one '
          'ignoring case, surrounding spaces and accents, so "cafe" is '
          'accepted for "café". Good for building active recall — you have '
          'to produce the word rather than recognise it.',
    ),
    ExerciseTypeInfo(
      type: ExerciseType.matchPairs,
      label: 'Match',
      icon: Icons.grid_view_outlined,
      category: ExerciseCategory.recall,
      summary: 'Pair each word with its translation.',
      howItWorks:
          'Two columns appear: words in the language you are learning on one '
          'side, their meanings on the other. Tap one from each side to link '
          'them; a correct pair locks in place and a wrong one clears so you '
          'can try again. The exercise is marked correct when every pair is '
          'matched. The lightest way to meet new vocabulary.',
    ),
    ExerciseTypeInfo(
      type: ExerciseType.multipleChoice,
      label: 'Multiple Choice',
      icon: Icons.checklist_outlined,
      category: ExerciseCategory.recall,
      summary: 'Pick the right answer from a few options.',
      howItWorks:
          'A question with several options, one of them right. You tap an '
          'option and the answer is revealed immediately — correct choices '
          'are highlighted, and the right one is shown if you missed it. '
          'Recognition rather than recall, so it is the gentlest type when '
          'material is new.',
    ),
    ExerciseTypeInfo(
      type: ExerciseType.fillInBlank,
      label: 'Fill Blank',
      icon: Icons.short_text_outlined,
      category: ExerciseCategory.recall,
      summary: 'Complete a sentence with the missing word.',
      howItWorks:
          'A sentence appears with one word removed. You supply the missing '
          'word, either by typing it or by choosing from options when they '
          'are provided. Because the rest of the sentence is intact, this '
          'practises grammar and word endings as much as vocabulary.',
    ),
    ExerciseTypeInfo(
      type: ExerciseType.clozeTest,
      label: 'Cloze Test',
      icon: Icons.notes_outlined,
      category: ExerciseCategory.reading,
      summary: 'Fill several gaps in a longer passage.',
      howItWorks:
          'A paragraph with several blanks rather than one. Each gap is '
          'filled from its own set of options, and the passage is only '
          'marked correct when every blank is right. Harder than a single '
          'fill-in-the-blank because the gaps depend on each other and on '
          'the sense of the whole passage.',
    ),
    ExerciseTypeInfo(
      type: ExerciseType.storyLesson,
      label: 'Story',
      icon: Icons.auto_stories_outlined,
      category: ExerciseCategory.reading,
      summary: 'Read a short graded story, then answer about it.',
      howItWorks: 'A short story written for your level, with key vocabulary '
          'highlighted — tap a highlighted word to see what it means. When '
          'you have read it, a comprehension question follows. Reading at '
          'length is where words you have drilled start to feel like '
          'language rather than a list.',
    ),
    ExerciseTypeInfo(
      type: ExerciseType.translationExercise,
      label: 'Translation',
      icon: Icons.compare_arrows_outlined,
      category: ExerciseCategory.reading,
      summary: 'Translate a full sentence or paragraph, either direction.',
      howItWorks:
          'A longer passage to translate, sometimes into the language you '
          'are learning and sometimes out of it. Hints are available if you '
          'get stuck, and several phrasings are usually accepted — the '
          'marking looks for the sense rather than one exact wording. The '
          'most demanding written type.',
    ),
    ExerciseTypeInfo(
      type: ExerciseType.interactiveDialogue,
      label: 'Interactive',
      icon: Icons.forum_outlined,
      category: ExerciseCategory.reading,
      summary: 'Hold up your side of a short conversation.',
      howItWorks:
          'A conversation plays out line by line, and at your turn you pick '
          'the reply that fits. The other speaker responds to what you '
          'chose, so the exchange reads as a whole. Practises the phrases '
          'that actually carry a conversation: greetings, ordering, asking '
          'for directions.',
    ),
    ExerciseTypeInfo(
      type: ExerciseType.listeningComprehension,
      label: 'Listening',
      icon: Icons.headphones_outlined,
      category: ExerciseCategory.listening,
      summary: 'Hear a phrase and answer what it was.',
      howItWorks:
          'A phrase is spoken aloud — you can replay it as often as you '
          'like — and you answer what you heard. Nothing is shown in '
          'writing until you have answered, so it trains your ear rather '
          'than your reading.',
      requiresAudio: true,
    ),
    ExerciseTypeInfo(
      type: ExerciseType.nativeAudio,
      label: 'Native Audio',
      icon: Icons.record_voice_over_outlined,
      category: ExerciseCategory.listening,
      summary: 'Listen to a native recording and type what you hear.',
      howItWorks: 'A recorded native speaker — or a synthesised voice where no '
          'recording exists yet — says a phrase, and you type it back. '
          'Playback speed follows the speech-speed setting, so you can slow '
          'a phrase down until it separates into words. The closest thing '
          'to hearing the language as it is really spoken.',
      requiresAudio: true,
    ),
    ExerciseTypeInfo(
      type: ExerciseType.dialogueListening,
      label: 'Dialogue',
      icon: Icons.hearing_outlined,
      category: ExerciseCategory.listening,
      summary: 'Follow a spoken conversation, then answer about it.',
      howItWorks:
          'A short conversation, news item or story is played through, one '
          'speaker after another, followed by a comprehension question. You '
          'can replay the whole thing, and the transcript can be revealed if '
          'you need it. Bridges single phrases and real connected speech.',
      requiresAudio: true,
    ),
    ExerciseTypeInfo(
      type: ExerciseType.songFill,
      label: 'Song Fill',
      icon: Icons.music_note_outlined,
      category: ExerciseCategory.listening,
      summary: 'Fill in missing lyrics as a song plays.',
      howItWorks:
          'Lyrics scroll past with words removed, and you fill the gaps from '
          'what you hear. Hints are available on each blank. Songs stick in '
          'the memory in a way drills do not, but they also take liberties '
          'with grammar — treat them as ear training rather than a model to '
          'copy.',
      requiresAudio: true,
    ),
    ExerciseTypeInfo(
      type: ExerciseType.speakThis,
      label: 'Speaking',
      icon: Icons.mic_none_outlined,
      category: ExerciseCategory.speaking,
      summary: 'Say a phrase out loud and have it recognised.',
      howItWorks: 'A phrase is shown and you read it aloud; speech recognition '
          'checks what it heard against it. You can skip any prompt, and if '
          'the microphone is unavailable the exercise says so rather than '
          'marking you wrong. Needs a quiet-ish room and permission to use '
          'the microphone.',
      requiresMicrophone: true,
    ),
    ExerciseTypeInfo(
      type: ExerciseType.pronunciationPractice,
      label: 'Pronunciation',
      icon: Icons.graphic_eq_outlined,
      category: ExerciseCategory.speaking,
      summary: 'Say a phrase and get word-by-word feedback.',
      howItWorks:
          'Like Speaking, but the result is broken down: an accuracy score '
          'plus which words came through clearly and which did not, with '
          'suggestions for the sounds that tripped. Slower than the other '
          'types and unforgiving in a noisy room — worth turning off if you '
          'usually study on a train.',
      requiresMicrophone: true,
    ),
    ExerciseTypeInfo(
      type: ExerciseType.wordBankTranslate,
      label: 'Word Bank',
      icon: Icons.dashboard_customize_outlined,
      category: ExerciseCategory.recall,
      summary: 'Build a translation by tapping word tiles.',
      howItWorks:
          'A sentence is shown, and beneath it a scattered bank of words. '
          'You tap words to place them on the answer line and tap them again '
          'to send them back. A few extra words are mixed in, so the tiles '
          'alone do not give the answer away. Easier than typing on a phone '
          'and it keeps the exercise about word order and meaning rather '
          'than spelling and accents.',
    ),
    ExerciseTypeInfo(
      type: ExerciseType.tapWhatYouHear,
      label: 'Tap What You Hear',
      icon: Icons.hearing_outlined,
      category: ExerciseCategory.listening,
      summary: 'Hear a phrase and rebuild it from word tiles.',
      howItWorks:
          'A phrase plays and you reassemble it from a bank of words. Two '
          'speaker buttons are offered: one at normal speed and one slowed '
          'down, which is what makes a run-together phrase separate into '
          'individual words. Nothing is shown in writing until you have '
          'answered, so it trains the ear while asking far less of your '
          'spelling than typing would.',
      requiresAudio: true,
    ),
    ExerciseTypeInfo(
      type: ExerciseType.selectImage,
      label: 'Select Image',
      icon: Icons.image_outlined,
      category: ExerciseCategory.recall,
      summary: 'Hear a word and pick the picture it names.',
      howItWorks:
          'A word is spoken and shown, with four pictures to choose between. '
          'Tapping one reveals the answer immediately, and the correct '
          'picture is highlighted whether or not you found it. Meaning '
          'attaches to an image without passing through your own language, '
          'which is why this is one of the gentlest ways to meet a new word.',
      requiresAudio: true,
    ),
    ExerciseTypeInfo(
      type: ExerciseType.completeTheChat,
      label: 'Complete Chat',
      icon: Icons.chat_bubble_outline,
      category: ExerciseCategory.reading,
      summary: 'Fill in your side of a short conversation.',
      howItWorks:
          'A short exchange is shown with your turn left blank, and you pick '
          'the reply that belongs there. Because the whole conversation is '
          'visible, the choice is judged against what was actually said — an '
          'answer in the wrong register or on the wrong subject reads as '
          'obviously wrong rather than merely unlucky.',
    ),
  ];

  static final Map<ExerciseType, ExerciseTypeInfo> _byType = {
    for (final info in all) info.type: info,
  };

  /// The catalogue entry for [type]. Every [ExerciseType] has one — a missing
  /// entry is a bug caught by `exercise_type_catalog_test.dart`.
  static ExerciseTypeInfo of(ExerciseType type) => _byType[type]!;

  static String labelOf(ExerciseType type) => of(type).label;

  static List<ExerciseTypeInfo> inCategory(ExerciseCategory category) =>
      all.where((info) => info.category == category).toList();
}
