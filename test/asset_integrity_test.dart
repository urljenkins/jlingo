import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_sprint/models/book.dart';
import 'package:lingua_sprint/models/course_manifest.dart';
import 'package:lingua_sprint/models/exercise.dart';
import 'package:lingua_sprint/models/flashcard.dart';
import 'package:lingua_sprint/models/picture_dictionary.dart';
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

    test('flashcard ids and prompts are unique within a deck', () {
      // A duplicate id collides in the SRS merge and in saved review state; a
      // duplicate front shows the learner the same prompt twice.
      for (final file in vocabularyFiles('flashcards_')) {
        final json =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        json.putIfAbsent('createdAt', () => DateTime.now().toIso8601String());
        final cards = FlashcardDeck.fromJson(json).cards;

        final ids = cards.map((c) => c.id).toList();
        expect(ids.toSet().length, ids.length,
            reason: '${file.path} has duplicate card ids');

        final fronts = cards.map((c) => c.front).toList();
        expect(fronts.toSet().length, fronts.length,
            reason: '${file.path} shows the same prompt twice');
      }
    });

    test('every flashcard carries the fields the study screen renders', () {
      for (final file in vocabularyFiles('flashcards_')) {
        final json =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        json.putIfAbsent('createdAt', () => DateTime.now().toIso8601String());

        for (final card in FlashcardDeck.fromJson(json).cards) {
          final where = '${file.path} card ${card.id}';
          expect(card.front.trim(), isNotEmpty, reason: '$where has no front');
          expect(card.back.trim(), isNotEmpty, reason: '$where has no back');
          expect(card.category.trim(), isNotEmpty,
              reason: '$where has no category');
          // An example without its translation renders as an untranslated
          // sentence, which is worse than showing none at all.
          if (card.exampleSentence != null) {
            expect(card.exampleTranslation?.trim(), isNotEmpty,
                reason: '$where has an example with no translation');
          }
        }
      }
    });

    test('bundled cards ship with no review state baked in', () {
      // Review state is per learner. A card authored with a non-default ease
      // factor or a nextReviewDate would start everyone mid-schedule.
      for (final file in vocabularyFiles('flashcards_')) {
        final json =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        json.putIfAbsent('createdAt', () => DateTime.now().toIso8601String());

        for (final card in FlashcardDeck.fromJson(json).cards) {
          expect(card.isNew, isTrue,
              reason: '${file.path} card ${card.id} ships pre-reviewed');
          expect(card.easeFactor, 2.5,
              reason: '${file.path} card ${card.id} has a custom ease factor');
        }
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

    test('every bundled picture dictionary decodes', () {
      for (final file in vocabularyFiles('picture_dictionary_')) {
        final json =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        expect(() => PictureDictionary.fromJson(json), returnsNormally,
            reason: '${file.path} failed to decode as a PictureDictionary');
        final dict = PictureDictionary.fromJson(json);
        expect(dict.topics, isNotEmpty, reason: '${file.path} has no topics');
      }
    });

    test('vocabulary assets are named for a real course', () {
      final courseIds = {
        for (final language in languages) _manifest(language).id,
      };
      for (final prefix in [
        'flashcards_',
        'word_of_day_',
        'picture_dictionary_',
      ]) {
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

  group('bilingual books', () {
    test('books manifest decodes and has books', () {
      final manifestFile = File('assets/books/manifest.json');
      expect(manifestFile.existsSync(), isTrue);
      final json =
          jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      final books = json['books'] as List<dynamic>?;
      expect(books, isNotNull);
      expect(books, isNotEmpty);
      for (final b in books!.cast<Map<String, dynamic>>()) {
        expect(() => BookManifestEntry.fromJson(b), returnsNormally);
      }
    });

    test('every book in manifest has a corresponding valid book file', () {
      final manifestFile = File('assets/books/manifest.json');
      final json =
          jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
      final books = json['books'] as List<dynamic>;
      for (final b in books.cast<Map<String, dynamic>>()) {
        final id = b['id'] as String;
        final file = File('assets/books/$id.json');
        expect(file.existsSync(), isTrue,
            reason:
                'Book $id is in manifest but assets/books/$id.json is missing');
        final bookJson =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        expect(() => BilingualBook.fromJson(bookJson), returnsNormally,
            reason: 'assets/books/$id.json failed to decode as BilingualBook');
        final book = BilingualBook.fromJson(bookJson);
        expect(book.chapters, isNotEmpty, reason: '$id has no chapters');
        for (final chapter in book.chapters) {
          expect(chapter.paragraphs, isNotEmpty,
              reason: 'Chapter ${chapter.id} in $id has no paragraphs');
          for (final p in chapter.paragraphs) {
            expect(p.originalText, isNotEmpty,
                reason: 'Paragraph ${p.id} in $id has empty originalText');
            expect(p.translatedText, isNotEmpty,
                reason: 'Paragraph ${p.id} in $id has empty translatedText');
          }
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

    test('every skill has at least one exercise', () {
      for (final (language, id, file) in allSkillFiles()) {
        final skill = Skill.fromJson(
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>);
        expect(skill.exercises, isNotEmpty,
            reason: '$language/$id.json has no exercises');
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
