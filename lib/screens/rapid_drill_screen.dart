import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/skill.dart';
import '../models/word_pair.dart';
import '../providers/course_provider.dart';
import '../providers/flashcard_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/word_knowledge_provider.dart';
import '../services/word_pool.dart';
import '../theme/app_colors.dart';
import '../widgets/drills/bubble_match_drill.dart';
import '../widgets/drills/waterfall_match_drill.dart';
import '../widgets/drills/word_flash_drill.dart';

/// Which high-volume drill to run.
enum RapidDrillMode {
  /// One word flashes, tap its meaning. Closest to passive.
  flash('Flash', Icons.bolt_outlined,
      'Words flash one at a time — tap the meaning.'),

  /// A continuously refilling column of pairs to match.
  waterfall('Waterfall', Icons.waterfall_chart,
      'A scrolling list of pairs that refills as you clear it.'),

  /// The same pairs thrown across the screen as drifting bubbles to hunt for.
  bubbles('Bubbles', Icons.bubble_chart_outlined,
      'A field of drifting word bubbles — tap a word, then its match.');

  const RapidDrillMode(this.label, this.icon, this.blurb);

  final String label;
  final IconData icon;
  final String blurb;
}

/// Hosts the high-volume drills.
///
/// These are deliberately separate from `LessonScreen`: a lesson walks one
/// authored exercise at a time, whereas a drill runs on a merged pool of
/// words and is about clearing volume. Sharing a screen would mean bending
/// one of them out of shape.
class RapidDrillScreen extends StatefulWidget {
  const RapidDrillScreen({
    super.key,
    this.skill,
    this.mode = RapidDrillMode.flash,
  });

  /// Restricts the pool to one skill's words plus the deck. Null drills the
  /// whole course.
  final Skill? skill;

  final RapidDrillMode mode;

  @override
  State<RapidDrillScreen> createState() => _RapidDrillScreenState();
}

class _RapidDrillScreenState extends State<RapidDrillScreen> {
  late RapidDrillMode _mode;
  WordPool? _pool;
  int _sessionKey = 0;

  @override
  void initState() {
    super.initState();
    _mode = widget.mode;
    WidgetsBinding.instance.addPostFrameCallback((_) => _buildPool());
  }

  Future<void> _buildPool() async {
    final courseId = context.read<CourseProvider>().currentManifest?.id ?? '';
    final knowledge = context.read<WordKnowledgeProvider>();
    if (knowledge.courseId != courseId && courseId.isNotEmpty) {
      await knowledge.load(courseId);
    }

    final flashcards = context.read<FlashcardProvider>();
    if (flashcards.decks.isEmpty && courseId.isNotEmpty) {
      await flashcards.loadDecks(courseId);
    }

    if (!mounted) return;
    final deck = flashcards.decks.isEmpty ? null : flashcards.decks.first;
    setState(() {
      _pool = WordPool.build(deck: deck, skill: widget.skill);
    });
  }

  void _recordAnswer(WordPair pair, bool correct, Duration elapsed) {
    context
        .read<WordKnowledgeProvider>()
        .recordAnswer(pair.target, correct: correct, elapsed: elapsed);
  }

  void _declareKnown(WordPair pair) {
    context.read<WordKnowledgeProvider>().declareKnown(pair.target);
  }

  Future<void> _finish() async {
    await context.read<WordKnowledgeProvider>().flushPending();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final knowledge = context.watch<WordKnowledgeProvider>();
    final pool = _pool;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(widget.skill?.name ?? 'Rapid drill'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${knowledge.knownCount} known',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
      body: pool == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildModeSwitch(),
                Expanded(child: _buildDrill(pool, knowledge)),
              ],
            ),
    );
  }

  Widget _buildModeSwitch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: SegmentedButton<RapidDrillMode>(
        segments: [
          for (final mode in RapidDrillMode.values)
            ButtonSegment(
              value: mode,
              label: Text(mode.label),
              icon: Icon(mode.icon, size: 16),
            ),
        ],
        selected: {_mode},
        onSelectionChanged: (selection) => setState(() {
          _mode = selection.first;
          // A fresh key restarts the drill rather than reusing the previous
          // one's queue and progress.
          _sessionKey++;
        }),
      ),
    );
  }

  Widget _buildDrill(WordPool pool, WordKnowledgeProvider knowledge) {
    // Known words are dropped here rather than inside each drill, so both
    // drills honour the same rule and the pool is filtered once per session.
    final active = pool.excludingKnown(knowledge);

    if (active.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Nothing left to drill here.\n'
            'Every word in this pool is marked known.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
        ),
      );
    }

    final key = ValueKey('${_mode.name}_$_sessionKey');
    switch (_mode) {
      case RapidDrillMode.flash:
        return WordFlashDrill(
          key: key,
          pool: active,
          onAnswer: _recordAnswer,
          onDeclareKnown: _declareKnown,
          onFinished: _finish,
        );
      case RapidDrillMode.waterfall:
        return WaterfallMatchDrill(
          key: key,
          pool: active,
          onAnswer: _recordAnswer,
          onDeclareKnown: _declareKnown,
          onFinished: _finish,
        );
      case RapidDrillMode.bubbles:
        return BubbleMatchDrill(
          key: key,
          pool: active,
          fieldSize: context.watch<SettingsProvider>().bubbleFieldSize,
          onAnswer: _recordAnswer,
          onDeclareKnown: _declareKnown,
          onFinished: _finish,
        );
    }
  }
}
