import 'exercise.dart';

/// A real, playable example of each exercise type, for the catalogue.
///
/// Prose can say what an exercise is like, but a learner deciding whether to
/// switch a type off is really asking "do I want to do this?" — and the only
/// honest answer is to let them do one. These samples are wired to the same
/// renderers a lesson uses, so what they try is exactly what they would get.
///
/// Content is deliberately trivial Spanish: the point is the interaction, not
/// the vocabulary, and a learner mid-decision should not be asked to think.
abstract final class ExerciseSamples {
  static Exercise of(ExerciseType type) => _samples[type] ?? _fallback(type);

  /// Every sample carries the same id so a lesson's progress tracking can
  /// never mistake a try-out for real practice.
  static const String sampleId = 'sample_exercise';

  static Exercise _fallback(ExerciseType type) => Exercise(
        id: sampleId,
        type: type,
        question: 'gato',
        options: const ['cat', 'dog', 'bird', 'fish'],
        correctAnswer: 'cat',
        targetLanguage: 'es-ES',
        nativeLanguage: 'en-US',
      );

  static final Map<ExerciseType, Exercise> _samples = {
    ExerciseType.translateThis: Exercise(
      id: sampleId,
      type: ExerciseType.translateThis,
      question: 'el gato',
      options: const [],
      correctAnswer: 'the cat',
      targetLanguage: 'es-ES',
    ),
    ExerciseType.matchPairs: Exercise(
      id: sampleId,
      type: ExerciseType.matchPairs,
      question: 'Match the pairs',
      options: const [],
      correctAnswer: '',
      targetLanguage: 'es-ES',
      metadata: const {
        'pairs': [
          {'target': 'gato', 'native': 'cat'},
          {'target': 'perro', 'native': 'dog'},
          {'target': 'casa', 'native': 'house'},
        ],
      },
    ),
    ExerciseType.multipleChoice: Exercise(
      id: sampleId,
      type: ExerciseType.multipleChoice,
      question: 'What does "gato" mean?',
      options: const ['cat', 'dog', 'house', 'water'],
      correctAnswer: 'cat',
      targetLanguage: 'es-ES',
    ),
    ExerciseType.fillInBlank: Exercise(
      id: sampleId,
      type: ExerciseType.fillInBlank,
      question: 'El ___ bebe leche.',
      options: const ['gato', 'casa', 'agua'],
      correctAnswer: 'gato',
      targetLanguage: 'es-ES',
    ),
    ExerciseType.listeningComprehension: Exercise(
      id: sampleId,
      type: ExerciseType.listeningComprehension,
      question: 'gato',
      options: const ['gato', 'pato', 'gata'],
      correctAnswer: 'gato',
      targetLanguage: 'es-ES',
    ),
    ExerciseType.speakThis: Exercise(
      id: sampleId,
      type: ExerciseType.speakThis,
      question: 'Hola',
      options: const [],
      correctAnswer: 'Hola',
      targetLanguage: 'es-ES',
    ),
    ExerciseType.pronunciationPractice: Exercise(
      id: sampleId,
      type: ExerciseType.pronunciationPractice,
      question: 'Buenos días',
      options: const [],
      correctAnswer: 'Buenos días',
      targetLanguage: 'es-ES',
    ),
    ExerciseType.nativeAudio: Exercise(
      id: sampleId,
      type: ExerciseType.nativeAudio,
      question: 'Buenos días',
      options: const [],
      correctAnswer: 'Buenos días',
      targetLanguage: 'es-ES',
    ),
    ExerciseType.wordBankTranslate: Exercise(
      id: sampleId,
      type: ExerciseType.wordBankTranslate,
      question: 'Yo soy de México.',
      options: const ['and', 'nice'],
      correctAnswer: 'I am from Mexico',
      targetLanguage: 'es-ES',
    ),
    ExerciseType.tapWhatYouHear: Exercise(
      id: sampleId,
      type: ExerciseType.tapWhatYouHear,
      question: '',
      options: const ['taco', 'por favor'],
      correctAnswer: 'Yo soy de Alemania',
      targetLanguage: 'es-ES',
    ),
    ExerciseType.selectImage: Exercise(
      id: sampleId,
      type: ExerciseType.selectImage,
      question: 'helado',
      options: const ['ice cream', 'taco', 'sandwich', 'tea'],
      correctAnswer: 'ice cream',
      targetLanguage: 'es-ES',
      metadata: const {
        'emoji': {
          'ice cream': '🍦',
          'taco': '🌮',
          'sandwich': '🥪',
          'tea': '🍵',
        },
      },
    ),
    ExerciseType.completeTheChat: Exercise(
      id: sampleId,
      type: ExerciseType.completeTheChat,
      question: 'Hola, yo soy Luis.',
      options: const ['¡Mucho gusto, Luis!', 'No, un café, por favor.'],
      correctAnswer: '¡Mucho gusto, Luis!',
      targetLanguage: 'es-ES',
      metadata: const {
        'lines': [
          {'text': 'Hola, yo soy Luis. Yo soy de México.', 'isLearner': false},
        ],
      },
    ),
    ExerciseType.clozeTest: Exercise(
      id: sampleId,
      type: ExerciseType.clozeTest,
      question: 'El ___ bebe ___.',
      options: const ['gato', 'leche'],
      correctAnswer: 'gato,leche',
      targetLanguage: 'es-ES',
      metadata: const {
        'blanks': [
          {
            'options': ['gato', 'perro'],
            'answer': 'gato'
          },
          {
            'options': ['leche', 'agua'],
            'answer': 'leche'
          },
        ],
      },
    ),
    ExerciseType.storyLesson: Exercise(
      id: sampleId,
      type: ExerciseType.storyLesson,
      question: 'El gato bebe leche. El gato es feliz.',
      options: const ['Milk', 'Water', 'Juice'],
      correctAnswer: 'Milk',
      targetLanguage: 'es-ES',
      metadata: const {
        'story': 'El gato bebe leche. El gato es feliz.',
        'question': 'What does the cat drink?',
        'vocabulary': [
          {'word': 'gato', 'translation': 'cat'},
          {'word': 'leche', 'translation': 'milk'},
        ],
      },
    ),
    ExerciseType.translationExercise: Exercise(
      id: sampleId,
      type: ExerciseType.translationExercise,
      question: 'El gato bebe leche.',
      options: const [],
      correctAnswer: 'The cat drinks milk.',
      targetLanguage: 'es-ES',
      metadata: const {
        'hints': ['gato = cat', 'leche = milk']
      },
    ),
    ExerciseType.interactiveDialogue: Exercise(
      id: sampleId,
      type: ExerciseType.interactiveDialogue,
      question: '¿Cómo estás?',
      options: const ['Muy bien, gracias', 'Un café, por favor'],
      correctAnswer: 'Muy bien, gracias',
      targetLanguage: 'es-ES',
      metadata: const {
        'topic': 'Greetings',
        'dialogue': [
          {'speaker': 'Ana', 'text': '¿Cómo estás?'},
          {
            'speaker': 'You',
            'isUserTurn': true,
            'options': ['Muy bien, gracias', 'Un café, por favor'],
            'answer': 'Muy bien, gracias',
          },
        ],
      },
    ),
    ExerciseType.dialogueListening: Exercise(
      id: sampleId,
      type: ExerciseType.dialogueListening,
      question: '¿Cómo estás?',
      options: const ['She asks how you are', 'She orders a coffee'],
      correctAnswer: 'She asks how you are',
      targetLanguage: 'es-ES',
      metadata: const {
        'dialogue': [
          {'speaker': 'Ana', 'text': '¿Cómo estás?'},
        ],
        'options': ['She asks how you are', 'She orders a coffee'],
        'question': 'What does Ana ask?',
      },
    ),
    ExerciseType.songFill: Exercise(
      id: sampleId,
      type: ExerciseType.songFill,
      question: 'La ___ es bella',
      options: const ['vida', 'casa'],
      correctAnswer: 'vida',
      targetLanguage: 'es-ES',
      metadata: const {
        'lyrics': ['La ___ es bella'],
        'blanks': ['vida'],
      },
    ),
  };
}
