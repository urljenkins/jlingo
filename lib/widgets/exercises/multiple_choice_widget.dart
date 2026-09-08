import 'package:flutter/material.dart';
import '../../models/exercise.dart';
import '../hover_card.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class MultipleChoiceWidget extends StatefulWidget {
  final Exercise exercise;
  final void Function(bool) onAnswer;

  const MultipleChoiceWidget({
    super.key,
    required this.exercise,
    required this.onAnswer,
  });

  @override
  State<MultipleChoiceWidget> createState() => _MultipleChoiceWidgetState();
}

class _MultipleChoiceWidgetState extends State<MultipleChoiceWidget> {
  String? _selectedAnswer;
  bool _showFeedback = false;

  void _selectAnswer(String answer) {
    if (_showFeedback) return;

    setState(() {
      _selectedAnswer = answer;
      _showFeedback = true;
    });

    final isCorrect = answer == widget.exercise.correctAnswer;

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        widget.onAnswer(isCorrect);
      }
    });
  }

  Color _getOptionColor(String option) {
    if (!_showFeedback) return AppColors.surfaceRaised;

    if (option == widget.exercise.correctAnswer) {
      return AppColors.correct.withValues(alpha: 0.2);
    }

    if (option == _selectedAnswer && option != widget.exercise.correctAnswer) {
      return AppColors.incorrect.withValues(alpha: 0.2);
    }

    return AppColors.surfaceRaised;
  }

  Color _getBorderColor(String option) {
    // An untouched option still needs an edge: surfaceRaised on background is
    // nearly invisible, which is what made these read as empty bars.
    if (!_showFeedback) return AppColors.border;

    if (option == widget.exercise.correctAnswer) {
      return AppColors.correct;
    }

    if (option == _selectedAnswer && option != widget.exercise.correctAnswer) {
      return AppColors.incorrect;
    }

    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.exercise.options;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenInset,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Choose the correct answer',
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            widget.exercise.question,
            textAlign: TextAlign.left,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xxl),
          if (_useGrid(options))
            _buildGrid(options)
          else
            ...options.map(_buildListOption),
        ],
      ),
    );
  }

  /// Four short options tile into a 2x2 of squares, which is far easier to
  /// scan than four near-identical bars. Anything longer would clip inside a
  /// square, so those keep the full-width list.
  static bool _useGrid(List<String> options) {
    return options.length == 4 &&
        options.every((o) => o.characters.length <= _gridLabelLimit);
  }

  static const int _gridLabelLimit = 24;

  Widget _buildGrid(List<String> options) {
    return Align(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxOptionsWidth),
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          children: options.map(_buildOptionCard).toList(),
        ),
      ),
    );
  }

  static const double _maxOptionsWidth = 420;

  /// A square tile for the 2x2 grid. The label is centred because a square
  /// has no strong reading edge to align to.
  Widget _buildOptionCard(String option) {
    return _optionSurface(
      option,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            option,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          if (_feedbackIcon(option) case final icon?) ...[
            const SizedBox(height: AppSpacing.sm),
            icon,
          ],
        ],
      ),
    );
  }

  /// The full-width row, for option sets a square would not fit.
  Widget _buildListOption(String option) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: _optionSurface(
        option,
        constraints: const BoxConstraints(minHeight: 56),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            if (_feedbackIcon(option) case final icon?) icon,
          ],
        ),
      ),
    );
  }

  /// The tappable, outlined ground shared by both option shapes.
  Widget _optionSurface(
    String option, {
    required Widget child,
    Alignment? alignment,
    BoxConstraints? constraints,
  }) {
    return Align(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _maxOptionsWidth),
        child: HoverCard(
          baseColor: _getOptionColor(option),
          hoverColor:
              _showFeedback ? _getOptionColor(option) : AppColors.surfaceRaised,
          onTap: () => _selectAnswer(option),
          child: Container(
            alignment: alignment,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: _getBorderColor(option),
                width: 2,
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            constraints: constraints,
            child: child,
          ),
        ),
      ),
    );
  }

  Widget? _feedbackIcon(String option) {
    if (!_showFeedback) return null;
    if (option == widget.exercise.correctAnswer) {
      return const Icon(Icons.check_circle, color: AppColors.correct);
    }
    if (option == _selectedAnswer) {
      return const Icon(Icons.cancel, color: AppColors.incorrect);
    }
    return null;
  }
}
