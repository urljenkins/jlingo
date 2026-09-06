import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingua_sprint/models/course_manifest.dart';
import 'package:lingua_sprint/models/exercise.dart';
import 'package:lingua_sprint/models/skill.dart';

/// Helper: load a local asset file relative to the repo root during tests.
String _loadAsset(String relativePath) {
  final file = File(relativePath);
  return file.readAsStringSync();
}

void main() {
  group('French course manifest', () {
    late CourseManifest manifest;

    setUp(() {
      final json =
          jsonDecode(_loadAsset('assets/courses/french/manifest.json'));
      manifest = CourseManifest.fromJson(json as Map<String, dynamic>);
    });

    test('parses without error', () {
      expect(manifest, isNotNull);
    });

    test('has correct id and languages', () {
      expect(manifest.id, 'french_en');
      expect(manifest.targetLanguage, 'fr-FR');
      expect(manifest.nativeLanguage, 'en-US');
    });

    test('contains expected skills', () {
      final ids = manifest.skills.map((s) => s.id).toList();
      expect(ids, containsAll(['basics_1', 'basics_2', 'travel_1']));
    });

    test('skill levels are set correctly', () {
      final b1 = manifest.skills.firstWhere((s) => s.id == 'basics_1');
      final b2 = manifest.skills.firstWhere((s) => s.id == 'basics_2');
      final t1 = manifest.skills.firstWhere((s) => s.id == 'travel_1');
      expect(b1.level, 1);
      expect(b2.level, 2);
      expect(t1.level, 2);
    });
  });

  group('French skill: basics_1', () {
    late Skill skill;

    setUp(() {
      final json =
          jsonDecode(_loadAsset('assets/courses/french/skills/basics_1.json'));
      skill = Skill.fromJson(json as Map<String, dynamic>);
    });

    test('parses without error', () {
      expect(skill, isNotNull);
    });

    test('has correct id and description', () {
      expect(skill.id, 'basics_1');
      expect(skill.description, isNotEmpty);
    });

    test('has 10 exercises', () {
      expect(skill.exercises.length, 10);
    });

    test('first exercise is translateThis type', () {
      expect(skill.exercises.first.type, ExerciseType.translateThis);
      expect(skill.exercises.first.question, 'Bonjour');
      expect(skill.exercises.first.correctAnswer, 'Hello');
    });

    test('matchPairs exercise uses metadata.pairs with target/native', () {
      final matchEx = skill.exercises.firstWhere(
        (e) => e.type == ExerciseType.matchPairs,
      );
      expect(matchEx.metadata, isNotNull);
      final pairsRaw = matchEx.metadata!['pairs'] as List<dynamic>;
      expect(pairsRaw.length, 4);

      final pairs = pairsRaw
          .map((p) => MatchPair.fromJson(p as Map<String, dynamic>))
          .toList();
      expect(pairs.map((p) => p.target),
          containsAll(['pomme', 'banane', 'orange', 'poire']));
      expect(pairs.map((p) => p.native),
          containsAll(['Apple', 'Banana', 'Orange', 'Pear']));
    });

    test('all exercises have non-empty ids', () {
      for (final ex in skill.exercises) {
        expect(ex.id, isNotEmpty, reason: 'Exercise id should not be empty');
      }
    });

    test('multipleChoice exercises have exactly 4 options', () {
      final mcExercises = skill.exercises
          .where((e) => e.type == ExerciseType.multipleChoice)
          .toList();
      expect(mcExercises, isNotEmpty);
      for (final ex in mcExercises) {
        expect(ex.options.length, 4,
            reason: 'Exercise ${ex.id} should have 4 options');
      }
    });
  });

  group('French skill: basics_2', () {
    late Skill skill;

    setUp(() {
      final json =
          jsonDecode(_loadAsset('assets/courses/french/skills/basics_2.json'));
      skill = Skill.fromJson(json as Map<String, dynamic>);
    });

    test('parses without error', () {
      expect(skill, isNotNull);
    });

    test('has correct id and level', () {
      expect(skill.id, 'basics_2');
      expect(skill.level, 2);
    });

    test('contains 8 exercises', () {
      expect(skill.exercises.length, 8);
    });

    test('matchPairs exercise has 4 French verb pairs', () {
      final matchEx = skill.exercises.firstWhere(
        (e) => e.type == ExerciseType.matchPairs,
      );
      final pairsRaw = matchEx.metadata!['pairs'] as List<dynamic>;
      expect(pairsRaw.length, 4);
      final targets = pairsRaw.map((p) => (p as Map)['target']).toList();
      expect(targets, containsAll(['manger', 'boire', 'parler', 'écrire']));
    });
  });

  group('French skill: travel_1', () {
    late Skill skill;

    setUp(() {
      final json =
          jsonDecode(_loadAsset('assets/courses/french/skills/travel_1.json'));
      skill = Skill.fromJson(json as Map<String, dynamic>);
    });

    test('parses without error', () {
      expect(skill, isNotNull);
    });

    test('has correct id and level', () {
      expect(skill.id, 'travel_1');
      expect(skill.level, 2);
    });

    test('contains 10 exercises', () {
      expect(skill.exercises.length, 10);
    });

    test('matchPairs exercise has travel vocabulary pairs', () {
      final matchEx = skill.exercises.firstWhere(
        (e) => e.type == ExerciseType.matchPairs,
      );
      final pairsRaw = matchEx.metadata!['pairs'] as List<dynamic>;
      expect(pairsRaw.length, 4);
      final targets = pairsRaw.map((p) => (p as Map)['target']).toList();
      expect(targets, containsAll(['gare', 'aéroport', 'billet', 'hôtel']));
    });

    test('all translationExercise items have non-empty correctAnswer', () {
      final translations = skill.exercises
          .where((e) => e.type == ExerciseType.translationExercise)
          .toList();
      for (final ex in translations) {
        expect(ex.correctAnswer, isNotEmpty,
            reason: 'Exercise ${ex.id} should have a correctAnswer');
      }
    });
  });
}
