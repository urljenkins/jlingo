import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/course.dart';

class CourseProvider extends ChangeNotifier {
  Course? _currentCourse;
  Course? get currentCourse => _currentCourse;

  List<String> _availableLanguages = [];
  List<String> get availableLanguages => _availableLanguages;

  Future<void> loadAvailableLanguages() async {
    // In a real app, this would scan the assets directory
    // For now, we'll hardcode available languages
    _availableLanguages = ['spanish', 'french', 'german', 'dutch', 'portuguese', 'japanese', 'chinese'];
    notifyListeners();
  }

  Future<void> loadCourse(String languageCode) async {
    try {
      final jsonString = await rootBundle.loadString('assets/courses/$languageCode.json');
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      _currentCourse = Course.fromJson(jsonData);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading course: $e');
    }
  }

  int getCurrentSkillIndex(Map<String, double> skillMastery) {
    if (_currentCourse == null) return 0;

    for (int i = 0; i < _currentCourse!.skills.length; i++) {
      final skill = _currentCourse!.skills[i];
      final mastery = skillMastery[skill.id] ?? 0.0;
      if (mastery < 100.0) {
        return i;
      }
    }

    return _currentCourse!.skills.length - 1;
  }
}
