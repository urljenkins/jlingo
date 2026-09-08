import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/exercise.dart';

/// How many word bubbles the bubble-match drill keeps on screen.
enum BubbleFieldSize {
  /// Eight pairs — dense but readable on a phone.
  cosy('Cosy', 8, false, '16 bubbles'),

  /// Twelve pairs — small text, tight packing, the busy end of the range.
  packed('Packed', 12, false, '24 bubbles'),

  /// Starts at eight pairs and tops back up as pairs clear, like the
  /// waterfall drill — the field never empties until the pool does.
  endless('Endless', 8, true, 'Refills as you clear');

  const BubbleFieldSize(this.label, this.pairCount, this.refills, this.blurb);

  final String label;
  final int pairCount;
  final bool refills;
  final String blurb;
}

/// Provider for managing application settings
class SettingsProvider extends ChangeNotifier {
  /// Gates every form of progress tracking: streaks, XP, levels, daily
  /// targets and mastery percentages. Off by default — the app is a library
  /// first, and scoring is opt-in.
  static const String _progressTrackingEnabledKey =
      'settings_progress_tracking_enabled';

  /// Superseded by [_progressTrackingEnabledKey]. Read once so existing
  /// users who had opted into streaks keep tracking switched on.
  static const String _legacyStreakMonitoringEnabledKey =
      'settings_streak_monitoring_enabled';
  static const String _notificationsEnabledKey = 'wod_notifications_enabled';
  static const String _speechRateKey = 'settings_tts_speech_rate';

  /// Exercise types switched off everywhere, stored as a JSON list of enum
  /// names. Names rather than indices, so reordering the enum cannot silently
  /// disable the wrong exercise.
  static const String _disabledTypesKey = 'settings_disabled_exercise_types';

  /// Per-course overrides: `{languageCode: [enum names]}`. A course present
  /// here replaces the global set outright rather than adding to it, so a
  /// learner can, say, keep speaking off globally but on for Spanish.
  static const String _languageDisabledTypesKey =
      'settings_disabled_exercise_types_by_language';

  /// Per-topic overrides: `{skillId: [enum names]}`. Set by long-pressing a
  /// topic on the Learn tab. A skill present here replaces whatever the
  /// language/global set would have given for that one topic only; tapping the
  /// topic (rather than long-pressing) leaves it on the default and never
  /// creates an entry here.
  static const String _skillDisabledTypesKey =
      'settings_disabled_exercise_types_by_skill';

  /// Per-topic drill length overrides: `{skillId: int}`. Set by long-pressing
  /// a topic on the Learn tab to customize how many exercises to drill (up to 100).
  static const String _skillDrillLengthKey = 'settings_drill_length_by_skill';

  /// Default drill length if not explicitly customized.
  static const int defaultDrillLength = 12;

  /// Whether the learner has seen the walkthrough of the exercise catalogue.
  static const String _exerciseTourSeenKey = 'settings_exercise_tour_seen';

  /// How the bubble-match drill sizes its field, stored as an enum name.
  static const String _bubbleFieldSizeKey = 'settings_bubble_field_size';

  bool _progressTrackingEnabled = false;
  bool _notificationsEnabled = true;
  double _speechRate = 0.5;
  Set<ExerciseType> _disabledTypes = {};
  Map<String, Set<ExerciseType>> _disabledTypesByLanguage = {};
  Map<String, Set<ExerciseType>> _disabledTypesBySkill = {};
  Map<String, int> _drillLengthBySkill = {};
  bool _exerciseTourSeen = false;
  BubbleFieldSize _bubbleFieldSize = BubbleFieldSize.cosy;
  bool _isLoading = true;

  bool get progressTrackingEnabled => _progressTrackingEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  double get speechRate => _speechRate;
  bool get isLoading => _isLoading;

  /// Types switched off for every course.
  Set<ExerciseType> get disabledTypes => Set.unmodifiable(_disabledTypes);

  /// Courses that have their own list, and what it is.
  Map<String, Set<ExerciseType>> get disabledTypesByLanguage =>
      Map.unmodifiable(_disabledTypesByLanguage);

  /// Topics that carry their own list, and what it is.
  Map<String, Set<ExerciseType>> get disabledTypesBySkill =>
      Map.unmodifiable(_disabledTypesBySkill);

  /// True when [skillId] keeps its own list or custom drill length rather than
  /// following the language/global one. Drives the "configured" mark on the topic row
  /// and the "Reset to default" action in the per-topic sheet.
  bool hasSkillOverride(String skillId) =>
      _disabledTypesBySkill.containsKey(skillId) ||
      _drillLengthBySkill.containsKey(skillId);

  /// Target number of exercises to drill for [skillId] (clamped 5..100).
  int drillLengthForSkill(String skillId) =>
      _drillLengthBySkill[skillId] ?? defaultDrillLength;

  /// Sets the custom drill length for [skillId] (up to 100 exercises).
  Future<void> setDrillLengthForSkill(String skillId, int count) async {
    final clamped = count.clamp(5, 100);
    if (_drillLengthBySkill[skillId] == clamped) return;
    _drillLengthBySkill[skillId] = clamped;
    notifyListeners();
    await _persistSkillDrillLengths();
  }

  /// The set in force for one topic: its own list if it has been configured,
  /// otherwise whatever [disabledTypesFor] gives for the course. This is what
  /// a lesson started from that topic should consult.
  Set<ExerciseType> disabledTypesForSkill(String skillId, {String? language}) {
    final override = _disabledTypesBySkill[skillId];
    if (override != null) return Set.unmodifiable(override);
    return disabledTypesFor(language);
  }

  bool get exerciseTourSeen => _exerciseTourSeen;

  BubbleFieldSize get bubbleFieldSize => _bubbleFieldSize;

  /// True when [language] keeps its own list instead of following the global
  /// one. Drives the "Use the global setting" toggle on the course tab.
  bool hasLanguageOverride(String? language) =>
      language != null && _disabledTypesByLanguage.containsKey(language);

  /// The set in force for [language] — its own if it has one, otherwise the
  /// global set. This, not [disabledTypes], is what lessons should consult.
  Set<ExerciseType> disabledTypesFor(String? language) {
    if (language != null) {
      final override = _disabledTypesByLanguage[language];
      if (override != null) return Set.unmodifiable(override);
    }
    return Set.unmodifiable(_disabledTypes);
  }

  bool isTypeEnabled(ExerciseType type, {String? language}) =>
      !disabledTypesFor(language).contains(type);

  /// Every type still switched on for [language], in catalogue order.
  List<ExerciseType> enabledTypesFor(String? language) {
    final disabled = disabledTypesFor(language);
    return ExerciseType.values
        .where((type) => !disabled.contains(type))
        .toList();
  }

  Future<void> loadSettings() async {
    _isLoading = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _progressTrackingEnabled = prefs.getBool(_progressTrackingEnabledKey) ??
          await _migrateLegacyStreakSetting(prefs);
      _notificationsEnabled = prefs.getBool(_notificationsEnabledKey) ?? true;
      _speechRate = prefs.getDouble(_speechRateKey) ?? 0.5;
      _disabledTypes = _decodeTypes(prefs.getString(_disabledTypesKey));
      _disabledTypesByLanguage =
          _decodeTypesByLanguage(prefs.getString(_languageDisabledTypesKey));
      _disabledTypesBySkill =
          _decodeTypesByLanguage(prefs.getString(_skillDisabledTypesKey));
      _drillLengthBySkill =
          _decodeSkillDrillLengths(prefs.getString(_skillDrillLengthKey));
      _exerciseTourSeen = prefs.getBool(_exerciseTourSeenKey) ?? false;
      _bubbleFieldSize = _decodeBubbleFieldSize(
        prefs.getString(_bubbleFieldSizeKey),
      );
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Carries a pre-existing streak preference over to the new key, so the
  /// rename does not silently flip tracking off for someone who wanted it.
  /// Absent that preference, tracking starts off.
  Future<bool> _migrateLegacyStreakSetting(SharedPreferences prefs) async {
    final legacy = prefs.getBool(_legacyStreakMonitoringEnabledKey);
    if (legacy == null) return false;

    await prefs.setBool(_progressTrackingEnabledKey, legacy);
    await prefs.remove(_legacyStreakMonitoringEnabledKey);
    return legacy;
  }

  Future<void> setProgressTrackingEnabled(bool enabled) async {
    if (_progressTrackingEnabled == enabled) return;
    _progressTrackingEnabled = enabled;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_progressTrackingEnabledKey, enabled);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    if (_notificationsEnabled == enabled) return;
    _notificationsEnabled = enabled;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
  }

  Future<void> setSpeechRate(double rate) async {
    final clamped = rate.clamp(0.2, 1.0);
    if (_speechRate == clamped) return;
    _speechRate = clamped;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_speechRateKey, clamped);
  }

  // -------------------------------------------------------------------
  // Exercise types
  // -------------------------------------------------------------------

  /// Switches a type on or off globally.
  ///
  /// Refuses to leave the learner with nothing to practise: the last enabled
  /// type cannot be switched off, and the call returns false so the UI can
  /// explain why instead of the switch silently springing back.
  Future<bool> setTypeEnabled(ExerciseType type, bool enabled) async {
    if (!enabled && _wouldDisableEverything(_disabledTypes, type)) {
      return false;
    }

    final changed =
        enabled ? _disabledTypes.remove(type) : _disabledTypes.add(type);
    if (!changed) return true;

    notifyListeners();
    await _persistDisabledTypes();
    return true;
  }

  /// Switches a type on or off for one course only.
  ///
  /// The first call for a course seeds its list from the global one, so
  /// flipping a single type does not quietly re-enable everything else.
  Future<bool> setTypeEnabledForLanguage(
    String language,
    ExerciseType type,
    bool enabled,
  ) async {
    final current = _disabledTypesByLanguage[language] ?? {..._disabledTypes};

    if (!enabled && _wouldDisableEverything(current, type)) {
      return false;
    }

    if (enabled) {
      current.remove(type);
    } else {
      current.add(type);
    }
    _disabledTypesByLanguage[language] = current;

    notifyListeners();
    await _persistLanguageDisabledTypes();
    return true;
  }

  /// Switches every type in [types] on or off at once — how a whole category
  /// is toggled. Applies as far as it can and stops short of emptying the
  /// set, returning false when it had to hold something back.
  Future<bool> setTypesEnabled(
    Iterable<ExerciseType> types,
    bool enabled, {
    String? language,
  }) async {
    final target = language != null
        ? (_disabledTypesByLanguage[language] ?? {..._disabledTypes})
        : _disabledTypes;

    var complete = true;
    for (final type in types) {
      if (enabled) {
        target.remove(type);
      } else if (_wouldDisableEverything(target, type)) {
        complete = false;
      } else {
        target.add(type);
      }
    }

    if (language != null) {
      _disabledTypesByLanguage[language] = target;
      notifyListeners();
      await _persistLanguageDisabledTypes();
    } else {
      notifyListeners();
      await _persistDisabledTypes();
    }
    return complete;
  }

  /// Drops a course's own list so it follows the global setting again.
  Future<void> clearLanguageOverride(String language) async {
    if (_disabledTypesByLanguage.remove(language) == null) return;
    notifyListeners();
    await _persistLanguageDisabledTypes();
  }

  /// Starts a course's list as a copy of the global one, ready to diverge.
  Future<void> createLanguageOverride(String language) async {
    if (_disabledTypesByLanguage.containsKey(language)) return;
    _disabledTypesByLanguage[language] = {..._disabledTypes};
    notifyListeners();
    await _persistLanguageDisabledTypes();
  }

  // -------------------------------------------------------------------
  // Per-topic overrides
  // -------------------------------------------------------------------

  /// Switches a type on or off for one topic only.
  ///
  /// The first call for a topic seeds its list from whatever the course would
  /// otherwise use, so flipping a single type does not quietly re-enable
  /// everything else. Returns false, changing nothing, if this would leave the
  /// topic with no type to draw from.
  Future<bool> setTypeEnabledForSkill(
    String skillId,
    ExerciseType type,
    bool enabled, {
    String? language,
  }) async {
    final current =
        _disabledTypesBySkill[skillId] ?? {...disabledTypesFor(language)};

    if (!enabled && _wouldDisableEverything(current, type)) {
      return false;
    }

    if (enabled) {
      current.remove(type);
    } else {
      current.add(type);
    }
    _disabledTypesBySkill[skillId] = current;

    notifyListeners();
    await _persistSkillDisabledTypes();
    return true;
  }

  /// Drops a topic's own list and custom drill length so it follows the course default again — the
  /// "tap for default" side of the long-press config.
  Future<void> clearSkillOverride(String skillId) async {
    final removedTypes = _disabledTypesBySkill.remove(skillId) != null;
    final removedDrillLength = _drillLengthBySkill.remove(skillId) != null;
    if (!removedTypes && !removedDrillLength) return;
    notifyListeners();
    if (removedTypes) await _persistSkillDisabledTypes();
    if (removedDrillLength) await _persistSkillDrillLengths();
  }

  /// Turns everything back on, globally and for every course and topic.
  Future<void> resetExerciseTypes() async {
    _disabledTypes = {};
    _disabledTypesByLanguage = {};
    _disabledTypesBySkill = {};
    _drillLengthBySkill = {};
    notifyListeners();
    await _persistDisabledTypes();
    await _persistLanguageDisabledTypes();
    await _persistSkillDisabledTypes();
    await _persistSkillDrillLengths();
  }

  Future<void> setBubbleFieldSize(BubbleFieldSize size) async {
    if (_bubbleFieldSize == size) return;
    _bubbleFieldSize = size;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_bubbleFieldSizeKey, size.name);
  }

  static BubbleFieldSize _decodeBubbleFieldSize(String? raw) {
    for (final size in BubbleFieldSize.values) {
      if (size.name == raw) return size;
    }
    return BubbleFieldSize.cosy;
  }

  Future<void> setExerciseTourSeen(bool seen) async {
    if (_exerciseTourSeen == seen) return;
    _exerciseTourSeen = seen;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_exerciseTourSeenKey, seen);
  }

  /// True when disabling [type] would leave [disabled] covering every type.
  bool _wouldDisableEverything(Set<ExerciseType> disabled, ExerciseType type) =>
      !disabled.contains(type) &&
      disabled.length + 1 >= ExerciseType.values.length;

  Future<void> _persistDisabledTypes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_disabledTypesKey, _encodeTypes(_disabledTypes));
  }

  Future<void> _persistLanguageDisabledTypes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _languageDisabledTypesKey,
      jsonEncode({
        for (final entry in _disabledTypesByLanguage.entries)
          entry.key: entry.value.map((t) => t.name).toList(),
      }),
    );
  }

  Future<void> _persistSkillDisabledTypes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _skillDisabledTypesKey,
      jsonEncode({
        for (final entry in _disabledTypesBySkill.entries)
          entry.key: entry.value.map((t) => t.name).toList(),
      }),
    );
  }

  Future<void> _persistSkillDrillLengths() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _skillDrillLengthKey,
      jsonEncode(_drillLengthBySkill),
    );
  }

  static Map<String, int> _decodeSkillDrillLengths(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return {
        for (final entry in decoded.entries)
          if (entry.value is int)
            entry.key as String: (entry.value as int).clamp(5, 100),
      };
    } catch (e) {
      debugPrint('Error decoding skill drill lengths: $e');
      return {};
    }
  }

  static String _encodeTypes(Set<ExerciseType> types) =>
      jsonEncode(types.map((t) => t.name).toList());

  /// Decodes a stored list, dropping names that no longer exist — a type
  /// removed from the app must not block loading the rest of the settings.
  static Set<ExerciseType> _decodeTypes(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return {};
      return decoded
          .whereType<String>()
          .map(_typeFromName)
          .whereType<ExerciseType>()
          .toSet();
    } catch (e) {
      debugPrint('Error decoding disabled exercise types: $e');
      return {};
    }
  }

  static Map<String, Set<ExerciseType>> _decodeTypesByLanguage(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return {
        for (final entry in decoded.entries)
          if (entry.value is List)
            entry.key as String: (entry.value as List)
                .whereType<String>()
                .map(_typeFromName)
                .whereType<ExerciseType>()
                .toSet(),
      };
    } catch (e) {
      debugPrint('Error decoding per-language exercise types: $e');
      return {};
    }
  }

  static ExerciseType? _typeFromName(String name) {
    for (final type in ExerciseType.values) {
      if (type.name == name) return type;
    }
    return null;
  }
}
