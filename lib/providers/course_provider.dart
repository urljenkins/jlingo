import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/course_manifest.dart';
import '../models/skill.dart';

const _selectedLanguageKey = 'selected_language';

class CourseProvider extends ChangeNotifier {
  CourseManifest? _currentManifest;
  CourseManifest? get currentManifest => _currentManifest;

  // Cache for loaded skills
  final Map<String, Skill> _loadedSkills = {};
  Map<String, Skill> get loadedSkills => _loadedSkills;

  List<String> _availableLanguages = [];
  List<String> get availableLanguages => _availableLanguages;

  String? _currentLanguageCode;
  String? get currentLanguageCode => _currentLanguageCode;

  Future<void> loadAvailableLanguages() async {
    _availableLanguages = [
      'spanish',
      'spanish_latam',
      'french',
      'dutch',
      'portuguese',
      'japanese',
      'chinese'
    ];
    notifyListeners();
  }

  Future<String?> getSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedLanguageKey);
  }

  Future<void> loadCourse(String languageCode) async {
    try {
      _currentLanguageCode = languageCode;
      final jsonString = await rootBundle
          .loadString('assets/courses/$languageCode/manifest.json');
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      _currentManifest = CourseManifest.fromJson(jsonData);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_selectedLanguageKey, languageCode);

      _loadedSkills.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading course manifest: $e');
    }
  }

  Future<Skill?> loadSkill(String skillId) async {
    if (_loadedSkills.containsKey(skillId)) {
      return _loadedSkills[skillId];
    }

    if (_currentLanguageCode == null) return null;

    try {
      final jsonString = await rootBundle.loadString(
          'assets/courses/$_currentLanguageCode/skills/$skillId.json');
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final skill = Skill.fromJson(jsonData);
      _loadedSkills[skillId] = skill;
      notifyListeners();
      return skill;
    } catch (e) {
      debugPrint('Error loading skill $skillId: $e');
      return null;
    }
  }

  Future<void> clearSelectedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedLanguageKey);
    _currentManifest = null;
    _currentLanguageCode = null;
    _loadedSkills.clear();
    notifyListeners();
  }

  /// Index of the first unfinished skill — where "Continue" resumes.
  int getCurrentSkillIndex(Set<String> completedSkills) {
    if (_currentManifest == null) return 0;

    for (int i = 0; i < _currentManifest!.skills.length; i++) {
      if (!completedSkills.contains(_currentManifest!.skills[i].id)) {
        return i;
      }
    }

    return _currentManifest!.skills.length - 1;
  }
}
