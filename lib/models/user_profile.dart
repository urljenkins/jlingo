import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_profile.g.dart';

enum LanguageLevel {
  beginner,
  elementary,
  intermediate,
  upperIntermediate,
  advanced,
  proficient,
}

enum LearningGoal {
  travel,
  work,
  education,
  culture,
  family,
  immigration,
  hobby,
}

@JsonSerializable()
class UserProfile {
  final bool onboardingComplete;

  /// Entry level per course, keyed by language code (e.g. 'spanish_latam').
  ///
  /// Proficiency does not carry across languages — someone can be B1 in
  /// Spanish and A1 in Japanese — so each course holds its own level.
  final Map<String, LanguageLevel> assessedLevels;
  final List<LearningGoal> goals;
  final int? dailyGoalMinutes;
  final DateTime? createdAt;
  final int quizScore;
  final int quizTotal;

  UserProfile({
    this.onboardingComplete = false,
    this.assessedLevels = const {},
    this.goals = const [],
    this.dailyGoalMinutes,
    this.createdAt,
    this.quizScore = 0,
    this.quizTotal = 0,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Migration: levels used to be a single scalar shared across every course.
    // Fold a stored legacy value into the map under the language it was set
    // for, so an existing learner keeps their place instead of being reset.
    if (json['assessedLevel'] != null && json['assessedLevels'] == null) {
      final legacyLanguage = json['legacyLevelLanguage'] as String?;
      json = {
        ...json,
        'assessedLevels': legacyLanguage == null
            ? <String, dynamic>{}
            : <String, dynamic>{legacyLanguage: json['assessedLevel']},
      };
    }
    return _$UserProfileFromJson(json);
  }
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  UserProfile copyWith({
    bool? onboardingComplete,
    Map<String, LanguageLevel>? assessedLevels,
    List<LearningGoal>? goals,
    int? dailyGoalMinutes,
    DateTime? createdAt,
    int? quizScore,
    int? quizTotal,
  }) {
    return UserProfile(
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      assessedLevels: assessedLevels ?? this.assessedLevels,
      goals: goals ?? this.goals,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      createdAt: createdAt ?? this.createdAt,
      quizScore: quizScore ?? this.quizScore,
      quizTotal: quizTotal ?? this.quizTotal,
    );
  }

  /// The level recorded for [language], or null if that course has none yet.
  LanguageLevel? levelFor(String? language) =>
      language == null ? null : assessedLevels[language];

  /// Returns a copy with [language] set to [level], leaving other courses be.
  UserProfile withLevelFor(String language, LanguageLevel level) =>
      copyWith(assessedLevels: {...assessedLevels, language: level});

  String levelDisplayNameFor(String? language) {
    switch (levelFor(language)) {
      case LanguageLevel.beginner:
        return 'Beginner (A1)';
      case LanguageLevel.elementary:
        return 'Elementary (A2)';
      case LanguageLevel.intermediate:
        return 'Intermediate (B1)';
      case LanguageLevel.upperIntermediate:
        return 'Upper Intermediate (B2)';
      case LanguageLevel.advanced:
        return 'Advanced (C1)';
      case LanguageLevel.proficient:
        return 'Proficient (C2)';
      case null:
        return 'Not assessed';
    }
  }

  static String goalDisplayName(LearningGoal goal) {
    switch (goal) {
      case LearningGoal.travel:
        return 'Travel';
      case LearningGoal.work:
        return 'Career & Work';
      case LearningGoal.education:
        return 'School & Education';
      case LearningGoal.culture:
        return 'Culture & Entertainment';
      case LearningGoal.family:
        return 'Family & Friends';
      case LearningGoal.immigration:
        return 'Immigration';
      case LearningGoal.hobby:
        return 'Personal Interest';
    }
  }

  static String goalDescription(LearningGoal goal) {
    switch (goal) {
      case LearningGoal.travel:
        return 'Navigate foreign countries with confidence';
      case LearningGoal.work:
        return 'Advance your career with language skills';
      case LearningGoal.education:
        return 'Prepare for exams or study abroad';
      case LearningGoal.culture:
        return 'Enjoy movies, music, and books';
      case LearningGoal.family:
        return 'Connect with loved ones in their language';
      case LearningGoal.immigration:
        return 'Prepare for living in a new country';
      case LearningGoal.hobby:
        return 'Learn for the joy of learning';
    }
  }

  static IconData goalIcon(LearningGoal goal) {
    switch (goal) {
      case LearningGoal.travel:
        return Icons.flight_takeoff;
      case LearningGoal.work:
        return Icons.business_center;
      case LearningGoal.education:
        return Icons.school;
      case LearningGoal.culture:
        return Icons.movie;
      case LearningGoal.family:
        return Icons.family_restroom;
      case LearningGoal.immigration:
        return Icons.home;
      case LearningGoal.hobby:
        return Icons.favorite;
    }
  }
}
