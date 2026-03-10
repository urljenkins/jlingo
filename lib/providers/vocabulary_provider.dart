import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/word_of_day.dart';
import '../models/picture_dictionary.dart';

class VocabularyProvider extends ChangeNotifier {
  // Word of the Day
  WordOfDay? _todaysWord;
  List<WordOfDay> _wordArchive = [];
  WordOfDayHistory? _wordHistory;

  // Picture Dictionary
  PictureDictionary? _pictureDictionary;
  PictureDictionaryProgress? _pictureProgress;
  PictureDictionaryTopic? _currentTopic;
  String _searchQuery = '';

  // Getters
  WordOfDay? get todaysWord => _todaysWord;
  List<WordOfDay> get wordArchive => _wordArchive;
  WordOfDayHistory? get wordHistory => _wordHistory;
  PictureDictionary? get pictureDictionary => _pictureDictionary;
  PictureDictionaryProgress? get pictureProgress => _pictureProgress;
  PictureDictionaryTopic? get currentTopic => _currentTopic;
  String get searchQuery => _searchQuery;

  List<PictureDictionaryEntry> get searchResults {
    if (_searchQuery.isEmpty || _pictureDictionary == null) return [];
    return _pictureDictionary!.searchEntries(_searchQuery);
  }

  Future<void> loadVocabularyData(String courseId) async {
    await Future.wait([
      _loadWordOfDay(courseId),
      _loadPictureDictionary(courseId),
    ]);
    notifyListeners();
  }

  // ==================== Word of the Day ====================

  Future<void> _loadWordOfDay(String courseId) async {
    final prefs = await SharedPreferences.getInstance();

    // Load word archive
    final archiveJson = prefs.getString('word_archive_$courseId');
    if (archiveJson != null) {
      final List<dynamic> decoded = jsonDecode(archiveJson) as List<dynamic>;
      _wordArchive = decoded
          .map((w) => WordOfDay.fromJson(w as Map<String, dynamic>))
          .toList();
    } else {
      _wordArchive = _sampleWordArchive;
      await _saveWordArchive(courseId);
    }

    // Load word history
    final historyJson = prefs.getString('word_history_$courseId');
    if (historyJson != null) {
      _wordHistory = WordOfDayHistory.fromJson(
          jsonDecode(historyJson) as Map<String, dynamic>);
    } else {
      _wordHistory = WordOfDayHistory(courseId: courseId);
    }

    // Get today's word
    _todaysWord = _getWordForToday();
  }

  WordOfDay _getWordForToday() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year)).inDays;

    // Use day of year to cycle through archive
    final index = dayOfYear % _wordArchive.length;
    return _wordArchive[index].copyWith(date: now);
  }

  Future<void> _saveWordArchive(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'word_archive_$courseId',
      jsonEncode(_wordArchive.map((w) => w.toJson()).toList()),
    );
  }

  Future<void> _saveWordHistory(String courseId) async {
    if (_wordHistory == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'word_history_$courseId',
      jsonEncode(_wordHistory!.toJson()),
    );
  }

  Future<void> markWordAsViewed(String courseId, String wordId) async {
    if (_wordHistory == null) return;

    if (!_wordHistory!.hasViewedWord(wordId)) {
      _wordHistory = _wordHistory!.copyWith(
        viewedWordIds: [..._wordHistory!.viewedWordIds, wordId],
        lastViewedDate: DateTime.now(),
      );
      await _saveWordHistory(courseId);
      notifyListeners();
    }
  }

  Future<void> toggleSaveWord(String courseId, String wordId) async {
    if (_wordHistory == null) return;

    List<String> newSavedIds;
    if (_wordHistory!.hasSavedWord(wordId)) {
      newSavedIds =
          _wordHistory!.savedWordIds.where((id) => id != wordId).toList();
    } else {
      newSavedIds = [..._wordHistory!.savedWordIds, wordId];
    }

    _wordHistory = _wordHistory!.copyWith(savedWordIds: newSavedIds);
    await _saveWordHistory(courseId);
    notifyListeners();
  }

  List<WordOfDay> get savedWords {
    if (_wordHistory == null) return [];
    return _wordArchive.where((w) => _wordHistory!.hasSavedWord(w.id)).toList();
  }

  // ==================== Picture Dictionary ====================

  Future<void> _loadPictureDictionary(String courseId) async {
    final prefs = await SharedPreferences.getInstance();

    // Load dictionary (or use sample data)
    final dictJson = prefs.getString('picture_dict_$courseId');
    if (dictJson != null) {
      _pictureDictionary = PictureDictionary.fromJson(
          jsonDecode(dictJson) as Map<String, dynamic>);
    } else {
      _pictureDictionary = _samplePictureDictionary;
      await _savePictureDictionary(courseId);
    }

    // Load progress
    final progressJson = prefs.getString('picture_progress_$courseId');
    if (progressJson != null) {
      _pictureProgress = PictureDictionaryProgress.fromJson(
          jsonDecode(progressJson) as Map<String, dynamic>);
    } else {
      _pictureProgress = PictureDictionaryProgress(courseId: courseId);
    }
  }

  Future<void> _savePictureDictionary(String courseId) async {
    if (_pictureDictionary == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'picture_dict_$courseId',
      jsonEncode(_pictureDictionary!.toJson()),
    );
  }

  Future<void> _savePictureProgress(String courseId) async {
    if (_pictureProgress == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'picture_progress_$courseId',
      jsonEncode(_pictureProgress!.toJson()),
    );
  }

  void selectTopic(String topicId) {
    if (_pictureDictionary == null) return;
    _currentTopic = _pictureDictionary!.topics.firstWhere(
      (t) => t.id == topicId,
      orElse: () => _pictureDictionary!.topics.first,
    );
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> markWordAsLearned(
      String courseId, String topicId, String wordId) async {
    if (_pictureProgress == null) return;

    if (!_pictureProgress!.hasLearnedWord(wordId)) {
      final newProgress =
          Map<String, int>.from(_pictureProgress!.topicProgress);
      newProgress[topicId] = (newProgress[topicId] ?? 0) + 1;

      _pictureProgress = _pictureProgress!.copyWith(
        topicProgress: newProgress,
        masteredWords: [..._pictureProgress!.masteredWords, wordId],
        lastStudiedDate: DateTime.now(),
      );

      await _savePictureProgress(courseId);
      notifyListeners();
    }
  }

  // ==================== Sample Data ====================

  List<WordOfDay> get _sampleWordArchive => [
        WordOfDay(
          id: 'wod_1',
          word: 'Papillon',
          translation: 'Butterfly',
          pronunciation: '/pa.pi.jɔ̃/',
          partOfSpeech: 'noun (masculine)',
          exampleSentence: 'Le papillon vole de fleur en fleur.',
          exampleTranslation: 'The butterfly flies from flower to flower.',
          etymology: 'From Latin "papilionem"',
          funFact: 'France has over 250 species of butterflies!',
          category: 'Nature',
          date: DateTime.now(),
          difficulty: 2,
        ),
        WordOfDay(
          id: 'wod_2',
          word: 'Étoile',
          translation: 'Star',
          pronunciation: '/e.twal/',
          partOfSpeech: 'noun (feminine)',
          exampleSentence: 'Les étoiles brillent dans le ciel.',
          exampleTranslation: 'The stars shine in the sky.',
          etymology: 'From Latin "stella"',
          funFact: 'The French flag was once decorated with stars!',
          category: 'Space',
          date: DateTime.now().subtract(const Duration(days: 1)),
        ),
        WordOfDay(
          id: 'wod_3',
          word: 'Bibliothèque',
          translation: 'Library',
          pronunciation: '/bi.bli.ɔ.tɛk/',
          partOfSpeech: 'noun (feminine)',
          exampleSentence: 'Je vais à la bibliothèque tous les samedis.',
          exampleTranslation: 'I go to the library every Saturday.',
          etymology: 'From Greek "bibliothēkē" (book repository)',
          category: 'Education',
          date: DateTime.now().subtract(const Duration(days: 2)),
          difficulty: 3,
        ),
        WordOfDay(
          id: 'wod_4',
          word: 'Parapluie',
          translation: 'Umbrella',
          pronunciation: '/pa.ʁa.plɥi/',
          partOfSpeech: 'noun (masculine)',
          exampleSentence: 'N\'oublie pas ton parapluie, il va pleuvoir.',
          exampleTranslation:
              'Don\'t forget your umbrella, it\'s going to rain.',
          etymology: 'From Italian "para pioggia" (protect from rain)',
          category: 'Weather',
          date: DateTime.now().subtract(const Duration(days: 3)),
          difficulty: 2,
        ),
        WordOfDay(
          id: 'wod_5',
          word: 'Croissant',
          translation: 'Crescent / Croissant',
          pronunciation: '/kʁwa.sɑ̃/',
          partOfSpeech: 'noun (masculine)',
          exampleSentence:
              'Je prends un croissant et un café au petit-déjeuner.',
          exampleTranslation: 'I have a croissant and a coffee for breakfast.',
          etymology:
              'From "croître" (to grow/increase), referring to the crescent moon shape',
          funFact:
              'While associated with France, the croissant originated in Austria!',
          category: 'Food',
          date: DateTime.now().subtract(const Duration(days: 4)),
        ),
        WordOfDay(
          id: 'wod_6',
          word: 'Soleil',
          translation: 'Sun',
          pronunciation: '/sɔ.lɛj/',
          partOfSpeech: 'noun (masculine)',
          exampleSentence: 'Le soleil se lève à l\'est.',
          exampleTranslation: 'The sun rises in the east.',
          category: 'Nature',
          date: DateTime.now().subtract(const Duration(days: 5)),
        ),
        WordOfDay(
          id: 'wod_7',
          word: 'Grenouille',
          translation: 'Frog',
          pronunciation: '/ɡʁə.nuj/',
          partOfSpeech: 'noun (feminine)',
          exampleSentence: 'La grenouille saute dans l\'étang.',
          exampleTranslation: 'The frog jumps into the pond.',
          funFact:
              'The French are sometimes called "frogs" (les grenouilles) by the British!',
          category: 'Animals',
          date: DateTime.now().subtract(const Duration(days: 6)),
          difficulty: 3,
        ),
      ];

  PictureDictionary get _samplePictureDictionary => PictureDictionary(
        id: 'pd_french',
        name: 'French Picture Dictionary',
        targetLanguage: 'fr-FR',
        nativeLanguage: 'en-US',
        topics: [
          PictureDictionaryTopic(
            id: 'topic_kitchen',
            name: 'In the Kitchen',
            description: 'Learn vocabulary for kitchen items and cooking',
            iconName: 'kitchen',
            coverImageUrl: 'assets/images/topics/kitchen.png',
            entries: [
              PictureDictionaryEntry(
                id: 'kitchen_1',
                word: 'couteau',
                translation: 'knife',
                pronunciation: '/ku.to/',
                imageUrl: 'assets/images/kitchen/knife.png',
                article: 'le',
                pluralForm: 'les couteaux',
                relatedWords: ['fourchette', 'cuillère'],
              ),
              PictureDictionaryEntry(
                id: 'kitchen_2',
                word: 'fourchette',
                translation: 'fork',
                pronunciation: '/fuʁ.ʃɛt/',
                imageUrl: 'assets/images/kitchen/fork.png',
                article: 'la',
                pluralForm: 'les fourchettes',
                relatedWords: ['couteau', 'cuillère'],
              ),
              PictureDictionaryEntry(
                id: 'kitchen_3',
                word: 'cuillère',
                translation: 'spoon',
                pronunciation: '/kɥi.jɛʁ/',
                imageUrl: 'assets/images/kitchen/spoon.png',
                article: 'la',
                pluralForm: 'les cuillères',
              ),
              PictureDictionaryEntry(
                id: 'kitchen_4',
                word: 'assiette',
                translation: 'plate',
                pronunciation: '/a.sjɛt/',
                imageUrl: 'assets/images/kitchen/plate.png',
                article: 'une',
                pluralForm: 'les assiettes',
              ),
              PictureDictionaryEntry(
                id: 'kitchen_5',
                word: 'casserole',
                translation: 'saucepan',
                pronunciation: '/kas.ʁɔl/',
                imageUrl: 'assets/images/kitchen/saucepan.png',
                article: 'la',
              ),
              PictureDictionaryEntry(
                id: 'kitchen_6',
                word: 'réfrigérateur',
                translation: 'refrigerator',
                pronunciation: '/ʁe.fʁi.ʒe.ʁa.tœʁ/',
                imageUrl: 'assets/images/kitchen/fridge.png',
                article: 'le',
                usageNote: 'Often shortened to "frigo" in casual speech',
              ),
            ],
          ),
          PictureDictionaryTopic(
            id: 'topic_home',
            name: 'At Home',
            description: 'Furniture and household items',
            iconName: 'home',
            coverImageUrl: 'assets/images/topics/home.png',
            entries: [
              PictureDictionaryEntry(
                id: 'home_1',
                word: 'chaise',
                translation: 'chair',
                pronunciation: '/ʃɛz/',
                imageUrl: 'assets/images/home/chair.png',
                article: 'la',
                pluralForm: 'les chaises',
              ),
              PictureDictionaryEntry(
                id: 'home_2',
                word: 'table',
                translation: 'table',
                pronunciation: '/tabl/',
                imageUrl: 'assets/images/home/table.png',
                article: 'la',
              ),
              PictureDictionaryEntry(
                id: 'home_3',
                word: 'lit',
                translation: 'bed',
                pronunciation: '/li/',
                imageUrl: 'assets/images/home/bed.png',
                article: 'le',
                pluralForm: 'les lits',
              ),
              PictureDictionaryEntry(
                id: 'home_4',
                word: 'fenêtre',
                translation: 'window',
                pronunciation: '/fə.nɛtʁ/',
                imageUrl: 'assets/images/home/window.png',
                article: 'la',
              ),
              PictureDictionaryEntry(
                id: 'home_5',
                word: 'porte',
                translation: 'door',
                pronunciation: '/pɔʁt/',
                imageUrl: 'assets/images/home/door.png',
                article: 'la',
              ),
            ],
          ),
          PictureDictionaryTopic(
            id: 'topic_food',
            name: 'Food & Drinks',
            description: 'Common foods, beverages, and meals',
            iconName: 'restaurant',
            coverImageUrl: 'assets/images/topics/food.png',
            entries: [
              PictureDictionaryEntry(
                id: 'food_1',
                word: 'pain',
                translation: 'bread',
                pronunciation: '/pɛ̃/',
                imageUrl: 'assets/images/food/bread.png',
                article: 'le',
              ),
              PictureDictionaryEntry(
                id: 'food_2',
                word: 'fromage',
                translation: 'cheese',
                pronunciation: '/fʁɔ.maʒ/',
                imageUrl: 'assets/images/food/cheese.png',
                article: 'le',
              ),
              PictureDictionaryEntry(
                id: 'food_3',
                word: 'pomme',
                translation: 'apple',
                pronunciation: '/pɔm/',
                imageUrl: 'assets/images/food/apple.png',
                article: 'la',
              ),
              PictureDictionaryEntry(
                id: 'food_4',
                word: 'eau',
                translation: 'water',
                pronunciation: '/o/',
                imageUrl: 'assets/images/food/water.png',
                article: 'l\'',
              ),
              PictureDictionaryEntry(
                id: 'food_5',
                word: 'café',
                translation: 'coffee',
                pronunciation: '/ka.fe/',
                imageUrl: 'assets/images/food/coffee.png',
                article: 'le',
              ),
            ],
          ),
          PictureDictionaryTopic(
            id: 'topic_transport',
            name: 'Transportation',
            description: 'Vehicles and travel vocabulary',
            iconName: 'directions_car',
            coverImageUrl: 'assets/images/topics/transport.png',
            difficulty: 2,
            entries: [
              PictureDictionaryEntry(
                id: 'trans_1',
                word: 'voiture',
                translation: 'car',
                pronunciation: '/vwa.tyʁ/',
                imageUrl: 'assets/images/transport/car.png',
                article: 'la',
              ),
              PictureDictionaryEntry(
                id: 'trans_2',
                word: 'train',
                translation: 'train',
                pronunciation: '/tʁɛ̃/',
                imageUrl: 'assets/images/transport/train.png',
                article: 'le',
              ),
              PictureDictionaryEntry(
                id: 'trans_3',
                word: 'avion',
                translation: 'airplane',
                pronunciation: '/a.vjɔ̃/',
                imageUrl: 'assets/images/transport/plane.png',
                article: 'l\'',
              ),
              PictureDictionaryEntry(
                id: 'trans_4',
                word: 'vélo',
                translation: 'bicycle',
                pronunciation: '/ve.lo/',
                imageUrl: 'assets/images/transport/bicycle.png',
                article: 'le',
              ),
            ],
          ),
          PictureDictionaryTopic(
            id: 'topic_body',
            name: 'Human Body',
            description: 'Body parts and physical features',
            iconName: 'accessibility_new',
            coverImageUrl: 'assets/images/topics/body.png',
            difficulty: 2,
            entries: [
              PictureDictionaryEntry(
                id: 'body_1',
                word: 'tête',
                translation: 'head',
                pronunciation: '/tɛt/',
                imageUrl: 'assets/images/body/head.png',
                article: 'la',
              ),
              PictureDictionaryEntry(
                id: 'body_2',
                word: 'main',
                translation: 'hand',
                pronunciation: '/mɛ̃/',
                imageUrl: 'assets/images/body/hand.png',
                article: 'la',
              ),
              PictureDictionaryEntry(
                id: 'body_3',
                word: 'pied',
                translation: 'foot',
                pronunciation: '/pje/',
                imageUrl: 'assets/images/body/foot.png',
                article: 'le',
              ),
              PictureDictionaryEntry(
                id: 'body_4',
                word: 'œil',
                translation: 'eye',
                pronunciation: '/œj/',
                imageUrl: 'assets/images/body/eye.png',
                article: 'l\'',
                pluralForm: 'les yeux',
                usageNote: 'Irregular plural: un œil → des yeux',
              ),
            ],
          ),
        ],
      );
}
