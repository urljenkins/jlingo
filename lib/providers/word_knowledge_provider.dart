import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/word_knowledge.dart';

/// Tracks which words the learner already knows, per course.
///
/// Kept apart from `ProgressProvider` on purpose: progress is about skills
/// and streaks, this is about individual vocabulary, and the drills need to
/// ask "is this word known?" thousands of times per session without walking
/// a skill tree to find out.
class WordKnowledgeProvider extends ChangeNotifier {
  final Map<String, WordKnowledge> _words = {};
  String? _courseId;

  /// Writes are debounced: a rapid drill can answer several times a second,
  /// and each one would otherwise re-encode and re-write the whole map.
  Timer? _saveTimer;
  static const Duration _saveDebounce = Duration(milliseconds: 600);

  String? get courseId => _courseId;

  /// Every tracked word, including ones still being learned.
  Map<String, WordKnowledge> get words => Map.unmodifiable(_words);

  int get knownCount => _words.values.where((w) => w.isKnown).length;
  int get learningCount => _words.values
      .where((w) => w.confidence == WordConfidence.learning)
      .length;

  static String _keyFor(String courseId) => 'word_knowledge_$courseId';

  Future<void> load(String courseId) async {
    _courseId = courseId;
    _words.clear();

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(courseId));
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          _words[entry.key] =
              WordKnowledge.fromJson(entry.value as Map<String, dynamic>);
        }
      } catch (e) {
        // Corrupt data must not brick a lesson — start the course over
        // rather than refusing to open it.
        debugPrint('Error loading word knowledge for $courseId: $e');
        _words.clear();
      }
    }
    notifyListeners();
  }

  WordKnowledge knowledgeOf(String word) {
    final key = WordKnowledge.normaliseWord(word);
    return _words[key] ?? WordKnowledge(word: key);
  }

  bool isKnown(String word) => knowledgeOf(word).isKnown;

  /// True when the word has never been presented. This is what a lesson
  /// should consult before testing a word — see the teach-before-test rule
  /// in the drill builders.
  bool isUnseen(String word) =>
      knowledgeOf(word).confidence == WordConfidence.unseen;

  /// Records one answer. [elapsed] is how long the learner took; passing it
  /// is what allows a fast answer to retire a word early.
  Future<void> recordAnswer(
    String word, {
    required bool correct,
    Duration? elapsed,
  }) async {
    final key = WordKnowledge.normaliseWord(word);
    if (key.isEmpty) return;

    final current = _words[key] ?? WordKnowledge(word: key);
    _words[key] = current.afterAnswer(correct: correct, elapsed: elapsed);
    notifyListeners();
    _scheduleSave();
  }

  /// Marks a word known outright — the explicit "I know this" gesture.
  Future<void> declareKnown(String word) async {
    final key = WordKnowledge.normaliseWord(word);
    if (key.isEmpty) return;

    final current = _words[key] ?? WordKnowledge(word: key);
    _words[key] = current.asDeclaredKnown();
    notifyListeners();
    _scheduleSave();
  }

  /// Puts a word the learner had marked known back into rotation.
  Future<void> declareUnknown(String word) async {
    final key = WordKnowledge.normaliseWord(word);
    final current = _words[key];
    if (current == null) return;

    _words[key] = current.asUnknown();
    notifyListeners();
    _scheduleSave();
  }

  /// Marks many words at once — the bulk gesture a higher-level learner uses
  /// to clear vocabulary they arrived already knowing.
  Future<void> declareAllKnown(Iterable<String> words) async {
    var changed = false;
    for (final word in words) {
      final key = WordKnowledge.normaliseWord(word);
      if (key.isEmpty) continue;
      final current = _words[key] ?? WordKnowledge(word: key);
      if (current.isKnown && current.declaredKnown) continue;
      _words[key] = current.asDeclaredKnown();
      changed = true;
    }
    if (!changed) return;
    notifyListeners();
    _scheduleSave();
  }

  /// Clears all knowledge for the loaded course.
  Future<void> reset() async {
    _words.clear();
    notifyListeners();
    await _flush();
  }

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDebounce, () => unawaited(_flush()));
  }

  Future<void> _flush() async {
    final courseId = _courseId;
    if (courseId == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyFor(courseId),
      jsonEncode({
        for (final entry in _words.entries) entry.key: entry.value.toJson(),
      }),
    );
  }

  /// Persists immediately, for when a drill ends and the debounce would
  /// otherwise lose the last few answers.
  Future<void> flushPending() async {
    _saveTimer?.cancel();
    await _flush();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}
