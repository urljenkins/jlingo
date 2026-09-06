import 'package:flutter/material.dart';
import '../../models/exercise.dart';
import '../../theme/app_colors.dart';

/// Cloze Test (Fill-in-the-blank) Widget
/// Displays sentences or paragraphs with multiple blanks to fill in.
/// Uses ___ placeholders in the text for blanks.
///
/// Metadata structure:
/// {
///   "blanks": [
///     {"index": 0, "answer": "gato", "options": ["gato", "perro", "pájaro"]},
///     {"index": 1, "answer": "leche", "options": ["agua", "leche", "café"]}
///   ],
///   "context": "Optional hint or context about the passage"
/// }
class ClozeTestWidget extends StatefulWidget {
  final Exercise exercise;
  final void Function(bool) onAnswer;

  const ClozeTestWidget({
    super.key,
    required this.exercise,
    required this.onAnswer,
  });

  @override
  State<ClozeTestWidget> createState() => _ClozeTestWidgetState();
}

class _ClozeTestWidgetState extends State<ClozeTestWidget> {
  final Map<int, String> _selectedAnswers = {};
  final Map<int, bool> _blankResults = {};
  bool _showFeedback = false;
  bool _isCorrect = false;
  int _currentBlankIndex = 0;

  List<Map<String, dynamic>> get _blanks {
    final blanks = widget.exercise.metadata?['blanks'];
    if (blanks != null) {
      return List<Map<String, dynamic>>.from(
        (blanks as List).map((e) => Map<String, dynamic>.from(e as Map)),
      );
    }
    // Fallback to single blank using exercise options/correctAnswer
    return [
      {
        'index': 0,
        'answer': widget.exercise.correctAnswer,
        'options': widget.exercise.options,
      }
    ];
  }

  String get _context =>
      (widget.exercise.metadata?['context'] as String?) ?? '';

  void _selectAnswer(int blankIndex, String answer) {
    if (_showFeedback) return;

    setState(() {
      _selectedAnswers[blankIndex] = answer;
    });
  }

  void _checkAnswers() {
    if (_showFeedback) return;

    int correctCount = 0;

    for (int i = 0; i < _blanks.length; i++) {
      final blank = _blanks[i];
      final userAnswer = _selectedAnswers[i]?.toLowerCase().trim();
      final correctAnswer = (blank['answer'] as String).toLowerCase().trim();
      final isCorrect = userAnswer == correctAnswer;

      _blankResults[i] = isCorrect;
      if (isCorrect) correctCount++;
    }

    setState(() {
      _isCorrect = correctCount == _blanks.length;
      _showFeedback = true;
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        widget.onAnswer(_isCorrect);
      }
    });
  }

  bool get _allBlanksFilled => _selectedAnswers.length == _blanks.length;

  List<Widget> _buildTextWithBlanks() {
    final text = widget.exercise.question;
    final parts = text.split('___');
    final List<Widget> widgets = [];

    for (int i = 0; i < parts.length; i++) {
      // Add text part
      if (parts[i].isNotEmpty) {
        widgets.add(
          Text(
            parts[i],
            style: const TextStyle(fontSize: 18, height: 1.6),
          ),
        );
      }

      // Add blank if not the last part
      if (i < parts.length - 1 && i < _blanks.length) {
        widgets.add(_buildBlank(i));
      }
    }

    return widgets;
  }

  Widget _buildBlank(int index) {
    final selectedAnswer = _selectedAnswers[index];
    final isCurrentBlank = index == _currentBlankIndex && !_showFeedback;

    Color backgroundColor = AppColors.surfaceRaised;
    Color borderColor =
        isCurrentBlank ? AppColors.textPrimary : Colors.transparent;

    if (_showFeedback && _blankResults.containsKey(index)) {
      final isCorrect = _blankResults[index]!;
      backgroundColor = isCorrect
          ? AppColors.correct.withValues(alpha: 0.2)
          : AppColors.incorrect.withValues(alpha: 0.2);
      borderColor = isCorrect ? AppColors.correct : AppColors.incorrect;
    }

    return GestureDetector(
      onTap: () {
        if (!_showFeedback) {
          setState(() {
            _currentBlankIndex = index;
          });
        }
      },
      child: Container(
        constraints: const BoxConstraints(minWidth: 80),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedAnswer ?? '____',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: selectedAnswer != null
                    ? Colors.white
                    : AppColors.textDisabled,
              ),
            ),
            if (_showFeedback && _blankResults.containsKey(index)) ...[
              const SizedBox(width: 6),
              Icon(
                _blankResults[index]! ? Icons.check_circle : Icons.cancel,
                size: 16,
                color: _blankResults[index]!
                    ? AppColors.correct
                    : AppColors.incorrect,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentBlank = _currentBlankIndex < _blanks.length
        ? _blanks[_currentBlankIndex]
        : null;
    final currentOptions = currentBlank != null
        ? List<String>.from(
            currentBlank['options'] as Iterable? ?? widget.exercise.options)
        : <String>[];

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.text_fields,
                  color: AppColors.textPrimary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Fill in the Blanks',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${_selectedAnswers.length}/${_blanks.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          // Context hint
          if (_context.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.textPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.textPrimary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.textPrimary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _context,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Text with blanks
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceRaised),
              ),
              child: SingleChildScrollView(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: _buildTextWithBlanks(),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Current blank indicator
          if (!_showFeedback && currentBlank != null) ...[
            Text(
              'Select word for blank ${_currentBlankIndex + 1}:',
              style:
                  const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),

            // Word bank for current blank
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: currentOptions.map((option) {
                final isSelected =
                    _selectedAnswers[_currentBlankIndex] == option;
                final isUsed =
                    _selectedAnswers.values.contains(option) && !isSelected;

                return Material(
                  color: isSelected
                      ? AppColors.textPrimary.withValues(alpha: 0.2)
                      : isUsed
                          ? AppColors.surfaceRaised
                          : AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: isUsed
                        ? null
                        : () => _selectAnswer(_currentBlankIndex, option),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.textPrimary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 16,
                          color: isUsed ? AppColors.textDisabled : Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 12),

            // Navigation between blanks
            if (_blanks.length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _currentBlankIndex > 0
                        ? () => setState(() => _currentBlankIndex--)
                        : null,
                    icon: const Icon(Icons.arrow_back_ios, size: 18),
                    color: AppColors.textPrimary,
                    disabledColor: AppColors.textDisabled,
                  ),
                  Text(
                    'Blank ${_currentBlankIndex + 1} of ${_blanks.length}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  IconButton(
                    onPressed: _currentBlankIndex < _blanks.length - 1
                        ? () => setState(() => _currentBlankIndex++)
                        : null,
                    icon: const Icon(Icons.arrow_forward_ios, size: 18),
                    color: AppColors.textPrimary,
                    disabledColor: AppColors.textDisabled,
                  ),
                ],
              ),
          ],

          // Feedback for incorrect answers
          if (_showFeedback && !_isCorrect) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.incorrect.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Correct answers:',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: _blanks.asMap().entries.map((entry) {
                      final index = entry.key;
                      final blank = entry.value;
                      return Text(
                        '${index + 1}. ${blank['answer']}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.correct,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed:
                  _allBlanksFilled && !_showFeedback ? _checkAnswers : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textPrimary,
                foregroundColor: Colors.black,
                disabledBackgroundColor: AppColors.surfaceRaised,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _allBlanksFilled ? 'CHECK ANSWERS' : 'FILL ALL BLANKS',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
