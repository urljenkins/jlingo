import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Per-course state (progress, XP, flashcard reviews, saved words) is stored in
/// SharedPreferences under keys built from the active course id. Screens that
/// pass a placeholder instead write under a key nothing else reads, so the work
/// silently disappears. These are source-level guards against that regressing.

const _libDir = 'lib';

Iterable<File> _dartFiles() sync* {
  for (final entity in Directory(_libDir).listSync(recursive: true)) {
    if (entity is File &&
        entity.path.endsWith('.dart') &&
        !entity.path.endsWith('.g.dart')) {
      yield entity;
    }
  }
}

/// Files allowed to mention a placeholder, e.g. documentation explaining it.
bool _isAllowed(File file) => file.path
    .endsWith('services${Platform.pathSeparator}course_bootstrap.dart');

void main() {
  test('no screen keys per-course state to a placeholder course id', () {
    final offenders = <String>[];
    for (final file in _dartFiles()) {
      if (_isAllowed(file)) continue;
      final source = file.readAsStringSync();
      if (source.contains("'default_course'")) {
        offenders.add(file.path);
      }
    }
    expect(offenders, isEmpty,
        reason: 'these files pass a hardcoded course id, so their reads and '
            'writes will not match the rest of the app: $offenders');
  });

  test('flashcard decks are not created with placeholder language codes', () {
    final offenders = <String>[];
    for (final file in _dartFiles()) {
      final source = file.readAsStringSync();
      if (source.contains("targetLanguage: 'target'") ||
          source.contains("nativeLanguage: 'native'")) {
        offenders.add(file.path);
      }
    }
    expect(offenders, isEmpty,
        reason: 'language codes should come from the course manifest, not a '
            'placeholder: $offenders');
  });

  test('per-course loads go through CourseBootstrap', () {
    // Screens should not re-implement the multi-provider load sequence; that
    // is how several of them ended up loading only a subset.
    const perCourseLoads = [
      'loadGamificationData(',
      'loadVocabularyData(',
    ];
    final offenders = <String>[];
    for (final file in _dartFiles()) {
      if (_isAllowed(file)) continue;
      if (!file.path.contains(
          '${Platform.pathSeparator}screens${Platform.pathSeparator}')) {
        continue;
      }
      final source = file.readAsStringSync();
      final hits = perCourseLoads.where(source.contains).toList();
      // A screen may lazily load the one provider it renders, but calling
      // several at once means it is duplicating the bootstrap sequence.
      if (hits.length > 1) {
        offenders.add('${file.path} -> $hits');
      }
    }
    expect(offenders, isEmpty,
        reason: 'use CourseBootstrap.loadCourseData instead: $offenders');
  });
}
