import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import 'course_provider.dart';

class OnboardingProvider extends ChangeNotifier {
  static const String _profileKey = 'user_profile';

  UserProfile _profile = UserProfile();
  bool _isLoading = true;

  UserProfile get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isOnboardingComplete => _profile.onboardingComplete;

  // Quiz state
  final List<QuizQuestion> _quizQuestions = [];
  int _currentQuestionIndex = 0;
  int _correctAnswers = 0;
  String? _selectedLanguage;

  List<QuizQuestion> get quizQuestions => _quizQuestions;
  int get currentQuestionIndex => _currentQuestionIndex;
  int get correctAnswers => _correctAnswers;
  String? get selectedLanguage => _selectedLanguage;

  QuizQuestion? get currentQuestion =>
      _currentQuestionIndex < _quizQuestions.length
          ? _quizQuestions[_currentQuestionIndex]
          : null;

  bool get isQuizComplete => _currentQuestionIndex >= _quizQuestions.length;

  OnboardingProvider() {
    _init();
  }

  void _init() {
    unawaited(loadProfile());
  }

  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_profileKey);

      if (profileJson != null) {
        final decoded = jsonDecode(profileJson) as Map<String, dynamic>;
        // Levels were once a single value shared across all courses. Tell the
        // migration which course that value belonged to, so it lands on the
        // right language rather than being dropped.
        decoded['legacyLevelLanguage'] = prefs.getString(selectedLanguageKey);
        _profile = UserProfile.fromJson(decoded);
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileKey, jsonEncode(_profile.toJson()));
    } catch (e) {
      debugPrint('Error saving user profile: $e');
    }
  }

  void setSelectedLanguage(String language) {
    _selectedLanguage = language;
    _loadQuizQuestions(language);
    notifyListeners();
  }

  void _loadQuizQuestions(String language) {
    _quizQuestions.clear();
    _currentQuestionIndex = 0;
    _correctAnswers = 0;

    // Generate quiz questions based on language
    _quizQuestions.addAll(_getQuestionsForLanguage(language));
  }

  List<QuizQuestion> _getQuestionsForLanguage(String language) {
    switch (language.toLowerCase()) {
      case 'spanish':
        return _spanishQuestions;
      case 'french':
        return _frenchQuestions;
      case 'portuguese':
        return _portugueseQuestions;
      case 'dutch':
        return _dutchQuestions;
      case 'japanese':
        return _japaneseQuestions;
      case 'chinese':
        return _chineseQuestions;
      default:
        return _spanishQuestions; // Default to Spanish
    }
  }

  void answerQuestion(int selectedIndex) {
    if (currentQuestion == null) return;

    if (selectedIndex == currentQuestion!.correctIndex) {
      _correctAnswers++;
    }

    _currentQuestionIndex++;
    notifyListeners();
  }

  /// The level the quiz suggests.
  ///
  /// Caps at C1: the question bank's hardest tier is `advanced`, so a perfect
  /// score cannot honestly separate C1 from C2. C2 stays something a learner
  /// chooses for themselves in settings rather than something a ten-question
  /// check hands out.
  LanguageLevel calculateLevel() {
    final percentage = _quizQuestions.isNotEmpty
        ? (_correctAnswers / _quizQuestions.length) * 100
        : 0;

    if (percentage >= 90) {
      return LanguageLevel.advanced;
    } else if (percentage >= 70) {
      return LanguageLevel.upperIntermediate;
    } else if (percentage >= 50) {
      return LanguageLevel.intermediate;
    } else if (percentage >= 30) {
      return LanguageLevel.elementary;
    } else {
      return LanguageLevel.beginner;
    }
  }

  Future<void> setGoals(List<LearningGoal> goals) async {
    _profile = _profile.copyWith(goals: goals);
    await _saveProfile();
    notifyListeners();
  }

  Future<void> setDailyGoal(int minutes) async {
    _profile = _profile.copyWith(dailyGoalMinutes: minutes);
    await _saveProfile();
    notifyListeners();
  }

  /// Sets the level directly, without the quiz.
  ///
  /// This is the manual override behind the settings picker: choosing a level
  /// is a statement about where to start, not a score, so it never touches the
  /// recorded quiz result and never clears completed work.
  Future<void> setAssessedLevel(LanguageLevel level, String language) async {
    _profile = _profile.withLevelFor(language, level);
    await _saveProfile();
    notifyListeners();
  }

  /// Prepares the quiz to be retaken from settings.
  ///
  /// The question list lives in memory only, so after an app restart it is
  /// empty; without reloading it here the quiz would report itself complete
  /// immediately and score 0. [language] is the course currently being
  /// studied.
  void restartQuiz({String? language}) {
    final target = language ?? _selectedLanguage;
    if (target != null) {
      // Record the language too: after a restart it is otherwise unset, and
      // the finished retake would have no course to save its result against.
      _selectedLanguage = target;
      _loadQuizQuestions(target);
    } else {
      _currentQuestionIndex = 0;
      _correctAnswers = 0;
    }
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    final level = calculateLevel();
    final language = _selectedLanguage;
    _profile = _profile.copyWith(
      onboardingComplete: true,
      assessedLevels: language == null
          ? _profile.assessedLevels
          : {..._profile.assessedLevels, language: level},
      createdAt: DateTime.now(),
      quizScore: _correctAnswers,
      quizTotal: _quizQuestions.length,
    );
    await _saveProfile();
    notifyListeners();
  }

  Future<void> resetOnboarding() async {
    _profile = UserProfile();
    _quizQuestions.clear();
    _currentQuestionIndex = 0;
    _correctAnswers = 0;
    _selectedLanguage = null;
    await _saveProfile();
    notifyListeners();
  }

  // Spanish questions - Progressive difficulty
  static final List<QuizQuestion> _spanishQuestions = [
    // Beginner (A1)
    const QuizQuestion(
      question: 'What does "Hola" mean?',
      options: ['Hello', 'Goodbye', 'Please', 'Thank you'],
      correctIndex: 0,
      difficulty: QuizDifficulty.beginner,
    ),
    const QuizQuestion(
      question: 'How do you say "Thank you" in Spanish?',
      options: ['Por favor', 'Gracias', 'De nada', 'Lo siento'],
      correctIndex: 1,
      difficulty: QuizDifficulty.beginner,
    ),
    // Elementary (A2)
    const QuizQuestion(
      question: 'What does "Tengo hambre" mean?',
      options: ['I am tired', 'I am happy', 'I am hungry', 'I am cold'],
      correctIndex: 2,
      difficulty: QuizDifficulty.elementary,
    ),
    const QuizQuestion(
      question: 'Complete: "Yo ___ español"',
      options: ['hablas', 'hablo', 'habla', 'hablamos'],
      correctIndex: 1,
      difficulty: QuizDifficulty.elementary,
    ),
    // Intermediate (B1)
    const QuizQuestion(
      question: 'What is the past tense of "comer" for "yo"?',
      options: ['comí', 'comía', 'comeré', 'como'],
      correctIndex: 0,
      difficulty: QuizDifficulty.intermediate,
    ),
    const QuizQuestion(
      question: '"Ojalá que llueva" uses which mood?',
      options: ['Indicative', 'Subjunctive', 'Imperative', 'Conditional'],
      correctIndex: 1,
      difficulty: QuizDifficulty.intermediate,
    ),
    // Upper Intermediate (B2)
    const QuizQuestion(
      question: 'What does "echar de menos" mean?',
      options: ['To throw away', 'To miss someone', 'To be less', 'To echo'],
      correctIndex: 1,
      difficulty: QuizDifficulty.upperIntermediate,
    ),
    const QuizQuestion(
      question: 'Complete: "Si hubiera sabido, ___"',
      options: [
        'habría ido',
        'había ido',
        'he ido',
        'iré',
      ],
      correctIndex: 0,
      difficulty: QuizDifficulty.upperIntermediate,
    ),
    // Advanced (C1)
    const QuizQuestion(
      question: 'What does "dar en el clavo" mean?',
      options: [
        'To give a nail',
        'To hit the nail on the head',
        'To be wrong',
        'To make a mistake',
      ],
      correctIndex: 1,
      difficulty: QuizDifficulty.advanced,
    ),
    const QuizQuestion(
      question: '"Quedarse con las ganas" means:',
      options: [
        'To be satisfied',
        'To stay with friends',
        'To be left wanting',
        'To win',
      ],
      correctIndex: 2,
      difficulty: QuizDifficulty.advanced,
    ),
  ];

  // French questions
  static final List<QuizQuestion> _frenchQuestions = [
    const QuizQuestion(
      question: 'What does "Bonjour" mean?',
      options: ['Good evening', 'Hello/Good day', 'Goodbye', 'Good night'],
      correctIndex: 1,
      difficulty: QuizDifficulty.beginner,
    ),
    const QuizQuestion(
      question: 'How do you say "Thank you" in French?',
      options: ['S\'il vous plaît', 'Merci', 'De rien', 'Pardon'],
      correctIndex: 1,
      difficulty: QuizDifficulty.beginner,
    ),
    const QuizQuestion(
      question: 'What does "Je suis fatigué" mean?',
      options: ['I am happy', 'I am tired', 'I am hungry', 'I am lost'],
      correctIndex: 1,
      difficulty: QuizDifficulty.elementary,
    ),
    const QuizQuestion(
      question: 'Complete: "Nous ___ français"',
      options: ['parle', 'parles', 'parlons', 'parlent'],
      correctIndex: 2,
      difficulty: QuizDifficulty.elementary,
    ),
    const QuizQuestion(
      question: 'What is the passé composé of "aller" for "je"?',
      options: ['j\'ai allé', 'je suis allé', 'j\'allais', 'je vais'],
      correctIndex: 1,
      difficulty: QuizDifficulty.intermediate,
    ),
    const QuizQuestion(
      question: '"Il faut que tu viennes" uses which mood?',
      options: ['Indicative', 'Subjunctive', 'Imperative', 'Conditional'],
      correctIndex: 1,
      difficulty: QuizDifficulty.intermediate,
    ),
    const QuizQuestion(
      question: 'What does "avoir le cafard" mean?',
      options: [
        'To have a bug',
        'To feel down/depressed',
        'To drink coffee',
        'To be scared'
      ],
      correctIndex: 1,
      difficulty: QuizDifficulty.upperIntermediate,
    ),
    const QuizQuestion(
      question: 'Complete: "Si j\'avais su, je ___"',
      options: ['serais venu', 'suis venu', 'étais venu', 'serai venu'],
      correctIndex: 0,
      difficulty: QuizDifficulty.upperIntermediate,
    ),
    const QuizQuestion(
      question: 'What does "mettre les pieds dans le plat" mean?',
      options: [
        'To put feet on a plate',
        'To put one\'s foot in it',
        'To dance',
        'To eat carefully',
      ],
      correctIndex: 1,
      difficulty: QuizDifficulty.advanced,
    ),
    const QuizQuestion(
      question: '"Poser un lapin" means:',
      options: [
        'To pet a rabbit',
        'To cook rabbit',
        'To stand someone up',
        'To be late'
      ],
      correctIndex: 2,
      difficulty: QuizDifficulty.advanced,
    ),
  ];

  // Portuguese questions
  static final List<QuizQuestion> _portugueseQuestions = [
    const QuizQuestion(
      question: 'What does "Olá" mean?',
      options: ['Goodbye', 'Hello', 'Please', 'Sorry'],
      correctIndex: 1,
      difficulty: QuizDifficulty.beginner,
    ),
    const QuizQuestion(
      question: 'How do you say "Thank you" in Portuguese?',
      options: ['Por favor', 'Obrigado/Obrigada', 'De nada', 'Desculpe'],
      correctIndex: 1,
      difficulty: QuizDifficulty.beginner,
    ),
    const QuizQuestion(
      question: 'What does "Estou com fome" mean?',
      options: ['I am tired', 'I am happy', 'I am hungry', 'I am at home'],
      correctIndex: 2,
      difficulty: QuizDifficulty.elementary,
    ),
    const QuizQuestion(
      question: 'Complete: "Eu ___ português"',
      options: ['falas', 'falo', 'fala', 'falamos'],
      correctIndex: 1,
      difficulty: QuizDifficulty.elementary,
    ),
    const QuizQuestion(
      question: 'What is the "pretérito perfeito" of "fazer" for "eu"?',
      options: ['fiz', 'fazia', 'farei', 'faço'],
      correctIndex: 0,
      difficulty: QuizDifficulty.intermediate,
    ),
    const QuizQuestion(
      question: '"Espero que ele venha" uses which mood?',
      options: ['Indicative', 'Subjunctive', 'Imperative', 'Future'],
      correctIndex: 1,
      difficulty: QuizDifficulty.intermediate,
    ),
    const QuizQuestion(
      question: 'What does "ter saudade" mean?',
      options: ['To have health', 'To miss/long for', 'To be sad', 'To leave'],
      correctIndex: 1,
      difficulty: QuizDifficulty.upperIntermediate,
    ),
    const QuizQuestion(
      question: 'Complete: "Se eu tivesse tempo, ___"',
      options: ['iria', 'fui', 'ia', 'vou'],
      correctIndex: 0,
      difficulty: QuizDifficulty.upperIntermediate,
    ),
    const QuizQuestion(
      question: 'What does "pagar mico" mean?',
      options: [
        'To pay a monkey',
        'To embarrass oneself',
        'To buy something',
        'To be rich'
      ],
      correctIndex: 1,
      difficulty: QuizDifficulty.advanced,
    ),
    const QuizQuestion(
      question: '"Ficar de molho" means:',
      options: ['To soak', 'To rest/take it easy', 'To get wet', 'To cook'],
      correctIndex: 1,
      difficulty: QuizDifficulty.advanced,
    ),
  ];

  // Dutch questions
  static final List<QuizQuestion> _dutchQuestions = [
    const QuizQuestion(
      question: 'What does "Hallo" mean?',
      options: ['Hello', 'Goodbye', 'Please', 'Thank you'],
      correctIndex: 0,
      difficulty: QuizDifficulty.beginner,
    ),
    const QuizQuestion(
      question: 'How do you say "Thank you" in Dutch?',
      options: ['Alstublieft', 'Dank u', 'Tot ziens', 'Sorry'],
      correctIndex: 1,
      difficulty: QuizDifficulty.beginner,
    ),
    const QuizQuestion(
      question: 'What does "Ik heb honger" mean?',
      options: ['I am tired', 'I am lost', 'I am hungry', 'I am cold'],
      correctIndex: 2,
      difficulty: QuizDifficulty.elementary,
    ),
    const QuizQuestion(
      question: 'Complete: "Wij ___ Nederlands"',
      options: ['spreek', 'spreekt', 'spreken', 'spreeken'],
      correctIndex: 2,
      difficulty: QuizDifficulty.elementary,
    ),
    const QuizQuestion(
      question: 'What is the past tense of "gaan" for "ik"?',
      options: ['ging', 'ga', 'gegaan', 'gaat'],
      correctIndex: 0,
      difficulty: QuizDifficulty.intermediate,
    ),
    const QuizQuestion(
      question: 'Which article is used with "huis"?',
      options: ['de', 'het', 'een', 'geen'],
      correctIndex: 1,
      difficulty: QuizDifficulty.intermediate,
    ),
    const QuizQuestion(
      question: 'What does "de kat uit de boom kijken" mean?',
      options: ['Watch the cat', 'Wait and see', 'Be curious', 'Climb a tree'],
      correctIndex: 1,
      difficulty: QuizDifficulty.upperIntermediate,
    ),
    const QuizQuestion(
      question: 'Complete: "Als ik het geweten had, ___ ik gekomen"',
      options: ['was', 'ben', 'zou', 'had'],
      correctIndex: 0,
      difficulty: QuizDifficulty.upperIntermediate,
    ),
    const QuizQuestion(
      question: 'What does "met de deur in huis vallen" mean?',
      options: [
        'Fall into house',
        'Get straight to the point',
        'Break the door',
        'Be clumsy'
      ],
      correctIndex: 1,
      difficulty: QuizDifficulty.advanced,
    ),
    const QuizQuestion(
      question: '"Een appeltje voor de dorst" means:',
      options: [
        'An apple drink',
        'A savings for a rainy day',
        'A healthy snack',
        'Being thirsty'
      ],
      correctIndex: 1,
      difficulty: QuizDifficulty.advanced,
    ),
  ];

  // Japanese questions
  static final List<QuizQuestion> _japaneseQuestions = [
    const QuizQuestion(
      question: 'What does "こんにちは" (Konnichiwa) mean?',
      options: [
        'Good morning',
        'Hello/Good afternoon',
        'Good evening',
        'Goodbye'
      ],
      correctIndex: 1,
      difficulty: QuizDifficulty.beginner,
    ),
    const QuizQuestion(
      question: 'How do you say "Thank you" in Japanese?',
      options: ['すみません', 'ありがとう', 'ごめんなさい', 'お願いします'],
      correctIndex: 1,
      difficulty: QuizDifficulty.beginner,
    ),
    const QuizQuestion(
      question: 'What does "お腹が空いた" (Onaka ga suita) mean?',
      options: ['I am tired', 'I am happy', 'I am hungry', 'I am lost'],
      correctIndex: 2,
      difficulty: QuizDifficulty.elementary,
    ),
    const QuizQuestion(
      question: 'Complete: "私は日本語を___" (Watashi wa nihongo o ___)',
      options: [
        '話す (hanasu)',
        '話します (hanashimasu)',
        '話して (hanashite)',
        '話した (hanashita)'
      ],
      correctIndex: 1,
      difficulty: QuizDifficulty.elementary,
    ),
    const QuizQuestion(
      question: 'What is the て-form of "食べる" (taberu)?',
      options: ['食べて', '食べた', '食べない', '食べます'],
      correctIndex: 0,
      difficulty: QuizDifficulty.intermediate,
    ),
    const QuizQuestion(
      question: '"行かなければならない" expresses:',
      options: ['Want to go', 'Must go', 'Can go', 'Went'],
      correctIndex: 1,
      difficulty: QuizDifficulty.intermediate,
    ),
    const QuizQuestion(
      question: 'What does "猫の手も借りたい" mean?',
      options: [
        'Want a cat',
        'So busy you need help',
        'Like cats',
        'Borrow something'
      ],
      correctIndex: 1,
      difficulty: QuizDifficulty.upperIntermediate,
    ),
    const QuizQuestion(
      question: 'Which particle indicates the topic of a sentence?',
      options: ['が', 'を', 'は', 'に'],
      correctIndex: 2,
      difficulty: QuizDifficulty.upperIntermediate,
    ),
    const QuizQuestion(
      question: 'What does "七転び八起き" mean?',
      options: [
        'Lucky seven',
        'Fall 7 times, get up 8',
        'Count sheep',
        'Eight is infinity'
      ],
      correctIndex: 1,
      difficulty: QuizDifficulty.advanced,
    ),
    const QuizQuestion(
      question: '"馬の耳に念仏" is similar to:',
      options: [
        'Horse power',
        'Casting pearls before swine',
        'Horse sense',
        'Religious horse'
      ],
      correctIndex: 1,
      difficulty: QuizDifficulty.advanced,
    ),
  ];

  // Chinese questions
  static final List<QuizQuestion> _chineseQuestions = [
    const QuizQuestion(
      question: 'What does "你好" (Nǐ hǎo) mean?',
      options: ['Goodbye', 'Hello', 'Thank you', 'Sorry'],
      correctIndex: 1,
      difficulty: QuizDifficulty.beginner,
    ),
    const QuizQuestion(
      question: 'How do you say "Thank you" in Chinese?',
      options: ['请 (Qǐng)', '谢谢 (Xièxiè)', '不客气 (Bù kèqi)', '对不起 (Duìbùqǐ)'],
      correctIndex: 1,
      difficulty: QuizDifficulty.beginner,
    ),
    const QuizQuestion(
      question: 'What does "我饿了" (Wǒ è le) mean?',
      options: ['I am tired', 'I am happy', 'I am hungry', 'I am cold'],
      correctIndex: 2,
      difficulty: QuizDifficulty.elementary,
    ),
    const QuizQuestion(
      question: 'Complete: "我___中文" (Wǒ ___ Zhōngwén)',
      options: ['说 (shuō)', '吃 (chī)', '喝 (hē)', '看 (kàn)'],
      correctIndex: 0,
      difficulty: QuizDifficulty.elementary,
    ),
    const QuizQuestion(
      question: 'What does "了" (le) indicate after a verb?',
      options: [
        'Future tense',
        'Completed action',
        'Continuous action',
        'Question'
      ],
      correctIndex: 1,
      difficulty: QuizDifficulty.intermediate,
    ),
    const QuizQuestion(
      question: '"我在学习" expresses:',
      options: [
        'I will study',
        'I am studying',
        'I studied',
        'I want to study'
      ],
      correctIndex: 1,
      difficulty: QuizDifficulty.intermediate,
    ),
    const QuizQuestion(
      question: 'What does "马马虎虎" (Mǎmǎhūhū) mean?',
      options: ['Horses and tigers', 'So-so/Not bad', 'Very good', 'Very bad'],
      correctIndex: 1,
      difficulty: QuizDifficulty.upperIntermediate,
    ),
    const QuizQuestion(
      question: 'Which measure word is used for books?',
      options: ['个 (gè)', '本 (běn)', '只 (zhī)', '张 (zhāng)'],
      correctIndex: 1,
      difficulty: QuizDifficulty.upperIntermediate,
    ),
    const QuizQuestion(
      question: 'What does "一石二鸟" mean?',
      options: [
        'One stone',
        'Two birds',
        'Kill two birds with one stone',
        'Hard work'
      ],
      correctIndex: 2,
      difficulty: QuizDifficulty.advanced,
    ),
    const QuizQuestion(
      question: '"对牛弹琴" is similar to:',
      options: [
        'Music for cows',
        'Teaching music',
        'Casting pearls before swine',
        'Playing guitar'
      ],
      correctIndex: 2,
      difficulty: QuizDifficulty.advanced,
    ),
  ];
}

enum QuizDifficulty {
  beginner,
  elementary,
  intermediate,
  upperIntermediate,
  advanced,
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final QuizDifficulty difficulty;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.difficulty,
  });
}
