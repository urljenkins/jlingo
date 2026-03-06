import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/skill.dart';
import '../models/exercise.dart';
import '../providers/progress_provider.dart';
import '../widgets/exercises/translate_this_widget.dart';
import '../widgets/exercises/match_pairs_widget.dart';
import '../widgets/exercises/multiple_choice_widget.dart';
import '../widgets/exercises/listening_widget.dart';
import 'package:flutter/services.dart';
import '../widgets/exercises/speak_this_widget.dart';
import '../widgets/exercises/fill_blank_widget.dart';
import '../widgets/responsive/responsive_layout.dart';
import '../widgets/responsive/desktop_scaffold.dart';
import '../widgets/responsive/mobile_scaffold.dart';

class LessonScreen extends StatefulWidget {
  final Skill skill;
  final ExerciseType? filterType;

  const LessonScreen({
    super.key,
    required this.skill,
    this.filterType,
  });

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  int _currentExerciseIndex = 0;
  int _correctAnswers = 0;
  int _totalAnswers = 0;
  List<Exercise> _exercises = [];

  @override
  void initState() {
    super.initState();
    _prepareExercises();
  }

  void _prepareExercises() {
    if (widget.filterType != null) {
      _exercises = widget.skill.exercises
          .where((e) => e.type == widget.filterType)
          .toList();
    } else {
      _exercises = List.from(widget.skill.exercises)..shuffle();
    }
  }

  void _onAnswer(bool isCorrect) {
    setState(() {
      _totalAnswers++;
      if (isCorrect) {
        _correctAnswers++;

        // Award points
        final points = 10; // Base points
        context.read<ProgressProvider>().addPoints(points);

        // Update exercise stats
        context.read<ProgressProvider>().incrementExerciseStat(
              _exercises[_currentExerciseIndex].type.toString(),
            );
      }

      // Move to next exercise
      if (_currentExerciseIndex < _exercises.length - 1) {
        _currentExerciseIndex++;
      } else {
        _finishLesson();
      }
    });
  }

  void _finishLesson() {
    final progressProvider = context.read<ProgressProvider>();

    // Update skill mastery
    final masteryGain = (_correctAnswers / _totalAnswers) * 20; // Up to 20% per session
    final currentMastery = progressProvider.progress?.skillMastery[widget.skill.id] ?? 0.0;
    final newMastery = (currentMastery + masteryGain).clamp(0.0, 100.0);

    progressProvider.updateSkillMastery(widget.skill.id, newMastery);
    progressProvider.updateStreak();
    progressProvider.checkAndUnlockAchievements();

    // Show completion dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildCompletionDialog(),
    );
  }

  Widget _buildCompletionDialog() {
    final accuracy = (_correctAnswers / _totalAnswers * 100).round();

    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF00FF85), size: 64),
            const SizedBox(height: 16),
            const Text(
              'Lesson Complete!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Text(
              '$_correctAnswers / $_totalAnswers correct',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              '$accuracy% accuracy',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: Focus(
                autofocus: true,
                onKeyEvent: (node, event) {
                  if (event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey == LogicalKeyboardKey.numpadEnter) {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                    return KeyEventResult.handled;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.escape) {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Return to home
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D9FF),
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('CONTINUE'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_exercises.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: Text('No exercises available for this filter'),
        ),
      );
    }

    final exercise = _exercises[_currentExerciseIndex];
    final progress = _currentExerciseIndex / _exercises.length;

    final topBar = AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: LinearProgressIndicator(
        value: progress,
        backgroundColor: const Color(0xFF3A3A3A),
        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00D9FF)),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            '${_currentExerciseIndex + 1}/${_exercises.length}',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );

    return ResponsiveLayout(
      mobileScaffold: MobileScaffold(
        topBar: topBar,
        body: _buildExerciseWidget(exercise),
      ),
      desktopScaffold: DesktopScaffold(
        topBar: topBar,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: _buildExerciseWidget(exercise),
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseWidget(Exercise exercise) {
    switch (exercise.type) {
      case ExerciseType.translateThis:
        return TranslateThisWidget(
          exercise: exercise,
          onAnswer: _onAnswer,
        );
      case ExerciseType.matchPairs:
        return MatchPairsWidget(
          exercise: exercise,
          onAnswer: _onAnswer,
        );
      case ExerciseType.multipleChoice:
        return MultipleChoiceWidget(
          exercise: exercise,
          onAnswer: _onAnswer,
        );
      case ExerciseType.listeningComprehension:
        return ListeningWidget(
          exercise: exercise,
          onAnswer: _onAnswer,
        );
      case ExerciseType.speakThis:
        return SpeakThisWidget(
          exercise: exercise,
          onAnswer: _onAnswer,
        );
      case ExerciseType.fillInBlank:
        return FillBlankWidget(
          exercise: exercise,
          onAnswer: _onAnswer,
        );
    }
  }
}
