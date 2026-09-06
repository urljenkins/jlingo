import 'user_profile.dart';

/// Maps CEFR proficiency tiers onto the internal skill levels used by the
/// course manifests.
///
/// Course content is authored against numeric `level` values (1..25). A
/// learner picks a CEFR tier instead, because that is the vocabulary people
/// already have for describing themselves. This is the single place that
/// translates between the two.
///
/// The mapping is deliberately expressed as a start level per tier rather than
/// a range: a tier owns everything from its start up to the next tier's start,
/// so adding a C tier later means appending one entry here and authoring
/// skills above the current ceiling — no other code changes.
class CefrLevel {
  const CefrLevel._();

  /// Internal skill level each tier begins at.
  ///
  /// Derived from the section boundaries in the course manifests:
  /// foundational 1-7, intermediate 8-16, advanced 17-25, mastery 26-27.
  static const Map<LanguageLevel, int> _startLevel = {
    LanguageLevel.beginner: 1, // A1 - foundational
    LanguageLevel.elementary: 5, // A2 - late foundational
    LanguageLevel.intermediate: 8, // B1 - intermediate section
    LanguageLevel.upperIntermediate: 14, // B2 - late intermediate
    LanguageLevel.advanced: 26, // C1 - mastery capstone
    LanguageLevel.proficient: 27, // C2 - rhetoric & literature
  };

  /// The internal skill level a learner at [level] starts from.
  ///
  /// Everything at or below this level is opened to them; this is an entry
  /// point, not a floor, so earlier material stays reachable.
  static int startLevelFor(LanguageLevel? level) =>
      _startLevel[level] ?? _startLevel[LanguageLevel.beginner]!;

  /// Short CEFR code, e.g. 'A1'. Used where space is tight.
  static String codeFor(LanguageLevel level) {
    switch (level) {
      case LanguageLevel.beginner:
        return 'A1';
      case LanguageLevel.elementary:
        return 'A2';
      case LanguageLevel.intermediate:
        return 'B1';
      case LanguageLevel.upperIntermediate:
        return 'B2';
      case LanguageLevel.advanced:
        return 'C1';
      case LanguageLevel.proficient:
        return 'C2';
    }
  }

  /// Plain-language name, without the CEFR code.
  static String nameFor(LanguageLevel level) {
    switch (level) {
      case LanguageLevel.beginner:
        return 'Beginner';
      case LanguageLevel.elementary:
        return 'Elementary';
      case LanguageLevel.intermediate:
        return 'Intermediate';
      case LanguageLevel.upperIntermediate:
        return 'Upper Intermediate';
      case LanguageLevel.advanced:
        return 'Advanced';
      case LanguageLevel.proficient:
        return 'Proficient';
    }
  }

  /// A description in terms of what the learner can do, phrased as ability
  /// rather than as a test result.
  static String descriptionFor(LanguageLevel level) {
    switch (level) {
      case LanguageLevel.beginner:
        return 'Starting from the beginning';
      case LanguageLevel.elementary:
        return 'I know some words and basic phrases';
      case LanguageLevel.intermediate:
        return 'I can hold a simple conversation';
      case LanguageLevel.upperIntermediate:
        return 'I can discuss most everyday topics';
      case LanguageLevel.advanced:
        return 'I am comfortable and want to refine';
      case LanguageLevel.proficient:
        return 'I want nuance, register and idiom';
    }
  }

  /// The entry level to actually use for a course, given the levels it ships.
  ///
  /// A sparse course can have a gap where a tier's start level falls — Japanese
  /// jumps from level 8 straight to 26, so a B2 learner would otherwise be
  /// dropped into C1/C2 material. Clamping to the highest shipped level at or
  /// below the requested start keeps the learner inside content that matches
  /// the tier they chose, and never above it.
  ///
  /// Returns the requested start unchanged when the course has content in the
  /// band the tier owns.
  static int effectiveStartLevel(
      LanguageLevel? level, List<int> courseSkillLevels) {
    final requested = startLevelFor(level);
    if (courseSkillLevels.isEmpty) return requested;

    // The band this tier owns runs from its start up to (but excluding) the
    // next tier's start. Content anywhere in that band means the tier is real
    // for this course and the requested start stands.
    final next = _nextStartAfter(requested);
    final hasOwnContent =
        courseSkillLevels.any((l) => l >= requested && l < next);
    if (hasOwnContent) return requested;

    // No content in this tier's own band. Fall back to the nearest content
    // below it: overshooting would drop the learner into a higher tier than
    // the one they picked, which is the opposite of a gentle entry point.
    final below = courseSkillLevels.where((l) => l < requested).toList()
      ..sort();
    return below.isEmpty ? requested : below.last;
  }

  /// The start level of the tier above [start], or a sentinel above every
  /// authored level when [start] is the top tier.
  static int _nextStartAfter(int start) {
    final higher = _startLevel.values.where((l) => l > start).toList()..sort();
    return higher.isEmpty ? 1 << 30 : higher.first;
  }

  /// Whether [course] actually ships skills at or above [level]'s entry point.
  ///
  /// Used to label tiers honestly in the picker. Tiers are never hidden or
  /// disabled on this basis — choosing one is always allowed; the learner is
  /// just told when there is nothing new there yet.
  static bool hasContentFor(LanguageLevel level, List<int> courseSkillLevels) {
    final start = startLevelFor(level);
    return courseSkillLevels.any((l) => l >= start);
  }

  /// The tier a numeric skill level belongs to.
  ///
  /// The inverse of [startLevelFor]: the highest tier whose start is at or
  /// below [skillLevel].
  static LanguageLevel tierForSkillLevel(int skillLevel) {
    var result = ordered.first;
    for (final level in ordered) {
      if (startLevelFor(level) <= skillLevel) result = level;
    }
    return result;
  }

  /// Heading for a group of skills at [skillLevel].
  ///
  /// Titles come from the CEFR tier rather than the raw number, because the
  /// numbers run 1-27 and naming each one individually left most of them
  /// rendering as a bare "Level 17". A tier name plus its code says where the
  /// learner is in terms they already understand.
  static String headingForSkillLevel(int skillLevel) {
    final tier = tierForSkillLevel(skillLevel);
    return '${nameFor(tier)} · ${codeFor(tier)}';
  }

  /// Tiers in order, for pickers.
  static const List<LanguageLevel> ordered = [
    LanguageLevel.beginner,
    LanguageLevel.elementary,
    LanguageLevel.intermediate,
    LanguageLevel.upperIntermediate,
    LanguageLevel.advanced,
    LanguageLevel.proficient,
  ];
}

/// Whether a skill is open to a learner who entered at [entryLevel].
///
/// A skill opens when it sits at or below the learner's chosen entry point, or
/// when the skill before it has been completed. The first branch is what makes
/// the level a starting point rather than a gate: choosing B1 opens the
/// foundational material too, so dropping back is always possible and never
/// requires re-earning anything.
bool isSkillUnlocked({
  required int skillLevel,
  required int position,
  required bool previousCompleted,
  required LanguageLevel? entryLevel,
  List<int> courseSkillLevels = const [],
}) {
  final start = CefrLevel.effectiveStartLevel(entryLevel, courseSkillLevels);
  if (skillLevel <= start) return true;
  return position == 0 || previousCompleted;
}
