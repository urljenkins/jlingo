import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_sprint/models/course_manifest.dart';
import 'package:lingua_sprint/models/exercise.dart';
import 'package:lingua_sprint/models/flashcard.dart';
import 'package:lingua_sprint/models/word_of_day.dart';
import 'package:lingua_sprint/models/skill.dart';
import 'package:yaml/yaml.dart';

/// Guards the bundled course content against the failure modes that silently
/// break lessons at runtime: assets that are not declared in pubspec.yaml (and
/// so are never packaged), manifest entries with no skill file, skill files
/// that no manifest lists, exercise types the model cannot decode, and audio
/// paths that point at files which do not exist.

const _coursesDir = 'assets/courses';

List<String> _languages() => Directory(_coursesDir)
    .listSync()
    .whereType<Directory>()
    .map((d) => d.path.split(Platform.pathSeparator).last)
    .toList()
  ..sort();

CourseManifest _manifest(String language) => CourseManifest.fromJson(
      jsonDecode(
              File('$_coursesDir/$language/manifest.json').readAsStringSync())
          as Map<String, dynamic>,
    );

/// The skill files a manifest points at, keyed by skill id.
Map<String, String> _manifestSkillPaths(String language) {
  final raw = jsonDecode(
      File('$_coursesDir/$language/manifest.json').readAsStringSync());
  final skills = (raw as Map<String, dynamic>)['skills'] as List<dynamic>;
  return {
    for (final s in skills.cast<Map<String, dynamic>>())
      s['id'] as String:
          '$_coursesDir/$language/${s['path'] as String? ?? 'skills/${s['id']}.json'}',
  };
}

void main() {
  final languages = _languages();

  test('there is at least one bundled course', () {
    expect(languages, isNotEmpty);
  });

  group('pubspec asset declarations', () {
    late List<String> declared;

    setUp(() {
      final pubspec = loadYaml(File('pubspec.yaml').readAsStringSync());
      declared = ((pubspec['flutter'] as YamlMap)['assets'] as YamlList)
          .cast<String>()
          .toList();
    });

    test('every course directory is declared', () {
      for (final language in languages) {
        expect(declared, contains('$_coursesDir/$language/'),
            reason: '$language course dir is not declared in pubspec.yaml');
      }
    });

    // Flutter asset directories are NOT recursive: declaring
    // assets/courses/<lang>/ does not bundle assets/courses/<lang>/skills/.
    test('every skills subdirectory is declared', () {
      for (final language in languages) {
        if (!Directory('$_coursesDir/$language/skills').existsSync()) continue;
        expect(declared, contains('$_coursesDir/$language/skills/'),
            reason: '$language skills dir is not declared in pubspec.yaml, so '
                'its lessons would never be bundled');
      }
    });
  });

  group('manifests', () {
    test('every manifest parses', () {
      for (final language in languages) {
        expect(() => _manifest(language), returnsNormally,
            reason: '$language manifest.json failed to parse');
      }
    });

    test('every listed skill has a content file', () {
      for (final language in languages) {
        _manifestSkillPaths(language).forEach((id, path) {
          expect(File(path).existsSync(), isTrue,
              reason: '$language lists skill "$id" but $path does not exist');
        });
      }
    });

    test('every skill file is listed in its manifest', () {
      for (final language in languages) {
        final dir = Directory('$_coursesDir/$language/skills');
        if (!dir.existsSync()) continue;
        final listed = _manifestSkillPaths(language).keys.toSet();
        for (final file in dir.listSync().whereType<File>()) {
          final id = file.path
              .split(Platform.pathSeparator)
              .last
              .replaceAll('.json', '');
          expect(listed, contains(id),
              reason: '$language ships skills/$id.json but the manifest does '
                  'not list it, so it is unreachable');
        }
      }
    });
  });

  group('bundled vocabulary assets', () {
    /// Mirrors what the providers do at runtime: decode each bundled file
    /// through its model, so a schema drift fails here instead of silently
    /// leaving a learner with an empty deck or word list.
    Iterable<File> vocabularyFiles(String prefix) {
      final dir = Directory('assets/vocabulary');
      if (!dir.existsSync()) return const [];
      return dir.listSync().whereType<File>().where(
          (f) => f.path.split(Platform.pathSeparator).last.startsWith(prefix));
    }

    test('every bundled flashcard deck decodes', () {
      for (final file in vocabularyFiles('flashcards_')) {
        final json =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        // The provider stamps createdAt on first load; assets omit it.
        json.putIfAbsent('createdAt', () => DateTime.now().toIso8601String());
        expect(() => FlashcardDeck.fromJson(json), returnsNormally,
            reason: '${file.path} failed to decode as a FlashcardDeck');
        expect(FlashcardDeck.fromJson(json).cards, isNotEmpty,
            reason: '${file.path} has no cards');
      }
    });

    test('every bundled word list decodes', () {
      for (final file in vocabularyFiles('word_of_day_')) {
        final json =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final words = json['words'] as List<dynamic>?;
        expect(words, isNotNull, reason: '${file.path} has no "words" list');
        expect(words, isNotEmpty, reason: '${file.path} has no words');
        for (final w in words!.cast<Map<String, dynamic>>()) {
          // The provider stamps date when serving a word; assets omit it.
          w.putIfAbsent('date',
              () => DateTime.fromMillisecondsSinceEpoch(0).toIso8601String());
          expect(() => WordOfDay.fromJson(w), returnsNormally,
              reason: '${file.path} has an entry that is not a WordOfDay');
        }
      }
    });

    test('vocabulary assets are named for a real course', () {
      final courseIds = {
        for (final language in languages) _manifest(language).id,
      };
      for (final prefix in ['flashcards_', 'word_of_day_']) {
        for (final file in vocabularyFiles(prefix)) {
          final name = file.path.split(Platform.pathSeparator).last;
          final courseId =
              name.substring(prefix.length, name.length - '.json'.length);
          expect(courseIds, contains(courseId),
              reason: '$name is keyed to "$courseId", which is not a course '
                  'id, so no provider will ever load it');
        }
      }
    });
  });

  group('skills', () {
    /// Every skill file in the repo, as (language, id, file) triples.
    List<(String, String, File)> allSkillFiles() {
      final out = <(String, String, File)>[];
      for (final language in languages) {
        final dir = Directory('$_coursesDir/$language/skills');
        if (!dir.existsSync()) continue;
        for (final file in dir.listSync().whereType<File>()) {
          final id = file.path
              .split(Platform.pathSeparator)
              .last
              .replaceAll('.json', '');
          out.add((language, id, file));
        }
      }
      return out;
    }

    test('every skill decodes, including its exercise types', () {
      for (final (language, id, file) in allSkillFiles()) {
        expect(
          () => Skill.fromJson(
              jsonDecode(file.readAsStringSync()) as Map<String, dynamic>),
          returnsNormally,
          reason: '$language/$id.json failed to decode - usually an exercise '
              '"type" that is not in the ExerciseType enum',
        );
      }
    });

    // matchPairs carries its answer as metadata['pairs'] rather than a single
    // correctAnswer string, so it is checked separately below.
    test('every exercise has an id, and an answer unless it is matchPairs', () {
      for (final (language, id, file) in allSkillFiles()) {
        final skill = Skill.fromJson(
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>);
        for (final exercise in skill.exercises) {
          expect(exercise.id, isNotEmpty,
              reason: 'an exercise in $language/$id.json has an empty id');
          if (exercise.type == ExerciseType.matchPairs) continue;
          expect(exercise.correctAnswer, isNotEmpty,
              reason: '${exercise.id} in $language/$id.json has no '
                  'correctAnswer');
        }
      }
    });

    test('every matchPairs exercise has usable pairs', () {
      for (final (language, id, file) in allSkillFiles()) {
        final skill = Skill.fromJson(
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>);
        for (final exercise in skill.exercises) {
          if (exercise.type != ExerciseType.matchPairs) continue;
          final pairs = exercise.metadata?['pairs'] as List<dynamic>?;
          expect(pairs, isNotNull,
              reason: '${exercise.id} in $language/$id.json is matchPairs but '
                  'has no metadata["pairs"]');
          expect(pairs, isNotEmpty,
              reason: '${exercise.id} in $language/$id.json has an empty '
                  'pairs list');
          for (final pair in pairs!.cast<Map<String, dynamic>>()) {
            expect(pair['target'] as String?, isNotEmpty,
                reason: '${exercise.id} in $language/$id.json has a pair with '
                    'no target');
            expect(pair['native'] as String?, isNotEmpty,
                reason: '${exercise.id} in $language/$id.json has a pair with '
                    'no native');
          }
        }
      }
    });

    // A path to a file that is not bundled leaves the exercise stuck: the
    // widget only falls back to TTS when audioPath is null or empty.
    test('every audioPath points at a file that exists', () {
      for (final (language, id, file) in allSkillFiles()) {
        final skill = Skill.fromJson(
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>);
        for (final exercise in skill.exercises) {
          final path = exercise.audioPath;
          if (path == null || path.isEmpty) continue;
          expect(File('assets/$path').existsSync(), isTrue,
              reason: '${exercise.id} in $language/$id.json references '
                  'assets/$path, which does not exist');
        }
      }
    });
  });
}
