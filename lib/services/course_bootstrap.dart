import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../providers/course_provider.dart';
import '../providers/flashcard_provider.dart';
import '../providers/gamification_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/vocabulary_provider.dart';

/// Loads every per-course provider for a single course.
///
/// All of this state is keyed by course id, so it has to be loaded together
/// and re-loaded as a set whenever the active course changes. Keeping that in
/// one place stops screens from each remembering their own subset — the bug
/// that left several of them reading a hardcoded `'default_course'` key while
/// the rest of the app used the real one.
class CourseBootstrap {
  const CourseBootstrap._();

  /// Loads the per-course providers for [courseId].
  ///
  /// The four loads are independent, so they run concurrently.
  static Future<void> loadCourseData(
    BuildContext context,
    String courseId,
  ) async {
    final progress = context.read<ProgressProvider>();
    final gamification = context.read<GamificationProvider>();
    final flashcards = context.read<FlashcardProvider>();
    final vocabulary = context.read<VocabularyProvider>();

    await Future.wait([
      progress.loadProgress(courseId),
      gamification.loadGamificationData(courseId),
      flashcards.loadDecks(courseId),
      vocabulary.loadVocabularyData(courseId),
    ]);
  }

  /// Switches to [languageCode] and loads all of its course data.
  ///
  /// Returns false when the course manifest could not be loaded.
  static Future<bool> selectLanguage(
    BuildContext context,
    String languageCode,
  ) async {
    final courseProvider = context.read<CourseProvider>();
    await courseProvider.loadCourse(languageCode);

    final manifest = courseProvider.currentManifest;
    if (manifest == null) return false;

    if (!context.mounted) return true;
    await loadCourseData(context, manifest.id);
    return true;
  }

  /// Restores the previously selected course, if there is one.
  ///
  /// Returns false when no course is active, meaning the caller should send
  /// the user to onboarding or language selection.
  static Future<bool> restoreSavedCourse(BuildContext context) async {
    final courseProvider = context.read<CourseProvider>();
    if (courseProvider.currentManifest != null) return true;

    final savedLanguage = await courseProvider.getSavedLanguage();
    if (savedLanguage == null) return false;

    if (!context.mounted) return false;
    return selectLanguage(context, savedLanguage);
  }
}
