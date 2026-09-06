import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/cefr_level.dart';
import '../models/course_manifest.dart';
import '../models/skill.dart';
import '../models/user_profile.dart';

/// Shared with [OnboardingProvider], which needs the studied language to
/// migrate legacy single-level profiles.
const selectedLanguageKey = 'selected_language';

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
    return prefs.getString(selectedLanguageKey);
  }

  Future<void> loadCourse(String languageCode) async {
    try {
      _currentLanguageCode = languageCode;
      final jsonString = await rootBundle
          .loadString('assets/courses/$languageCode/manifest.json');
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      _currentManifest = CourseManifest.fromJson(jsonData);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(selectedLanguageKey, languageCode);

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
    await prefs.remove(selectedLanguageKey);
    _currentManifest = null;
    _currentLanguageCode = null;
    _loadedSkills.clear();
    notifyListeners();
  }

  /// Index of the first unfinished skill — where "Continue" resumes.
  ///
  /// A learner who entered above A1 resumes at their entry level rather than
  /// at the very first skill, so the course opens where they actually are.
  /// Earlier material stays unlocked and reachable by scrolling up.
  int getCurrentSkillIndex(
    Set<String> completedSkills, {
    LanguageLevel? entryLevel,
    CourseManifest? manifest,
  }) {
    final target = manifest ?? _currentManifest;
    if (target == null) return 0;

    final skills = target.skills;
    // Clamp to content the course actually has, so a sparse course does not
    // drop the learner into a tier above the one they picked.
    final startLevel = CefrLevel.effectiveStartLevel(
      entryLevel,
      skills.map((s) => s.level).toList(),
    );

    // Prefer the first unfinished skill at or above the entry level.
    for (int i = 0; i < skills.length; i++) {
      if (skills[i].level >= startLevel &&
          !completedSkills.contains(skills[i].id)) {
        return i;
      }
    }

    // Entry level fully completed — fall back to anything left below it.
    for (int i = 0; i < skills.length; i++) {
      if (!completedSkills.contains(skills[i].id)) {
        return i;
      }
    }

    return skills.length - 1;
  }
}
