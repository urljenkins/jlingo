import 'package:flutter/material.dart';
import '../../models/exercise.dart';
import '../../theme/app_colors.dart';

/// Story Lesson Widget
/// Displays graded readers (stories written for specific language levels)
/// with comprehension questions and vocabulary highlights.
///
/// Metadata structure:
/// {
///   "story": "El niño caminaba por el parque cuando vio un perro grande...",
///   "title": "El Perro del Parque",
///   "level": "A1",
///   "vocabulary": [
///     {"word": "caminaba", "translation": "was walking", "highlight": true},
///     {"word": "perro", "translation": "dog", "highlight": true}
///   ],
///   "question": "¿Qué vio el niño en el parque?"
/// }
class StoryLessonWidget extends StatefulWidget {
  final Exercise exercise;
  final void Function(bool) onAnswer;

  const StoryLessonWidget({
    super.key,
    required this.exercise,
    required this.onAnswer,
  });

  @override
  State<StoryLessonWidget> createState() => _StoryLessonWidgetState();
}

class _StoryLessonWidgetState extends State<StoryLessonWidget> {
  String? _selectedAnswer;
  bool _showFeedback = false;
  bool _isCorrect = false;
  bool _showVocabulary = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String get _story =>
      (widget.exercise.metadata?['story'] as String?) ??
      widget.exercise.question;

  String get _title =>
      (widget.exercise.metadata?['title'] as String?) ?? 'Reading Exercise';

  String get _level => (widget.exercise.metadata?['level'] as String?) ?? '';

  String get _question =>
      (widget.exercise.metadata?['question'] as String?) ??
      widget.exercise.question;

  List<Map<String, dynamic>> get _vocabulary {
    final vocab = widget.exercise.metadata?['vocabulary'];
    if (vocab != null) {
      return List<Map<String, dynamic>>.from(
        (vocab as List).map((e) => Map<String, dynamic>.from(e as Map)),
      );
    }
    return [];
  }

  void _selectAnswer(String answer) {
    if (_showFeedback) return;
    setState(() {
      _selectedAnswer = answer;
    });
  }

  void _checkAnswer() {
    if (_selectedAnswer == null || _showFeedback) return;

    setState(() {
      _isCorrect = _selectedAnswer == widget.exercise.correctAnswer;
      _showFeedback = true;
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        widget.onAnswer(_isCorrect);
      }
    });
  }

  Widget _buildHighlightedStory() {
    if (_vocabulary.isEmpty) {
      return Text(
        _story,
        style: const TextStyle(fontSize: 18, height: 1.6),
      );
    }

    // Build highlighted text with tappable vocabulary words
    String remainingText = _story;
    final List<InlineSpan> spans = [];

    for (final vocab in _vocabulary) {
      final word = vocab['word'] as String;
      final translation = vocab['translation'] as String;
      final shouldHighlight = vocab['highlight'] == true;

      if (!shouldHighlight) continue;

      final index = remainingText.toLowerCase().indexOf(word.toLowerCase());
      if (index == -1) continue;

      // Add text before the word
      if (index > 0) {
        spans.add(TextSpan(
          text: remainingText.substring(0, index),
          style: const TextStyle(fontSize: 18, height: 1.6),
        ));
      }

      // Add highlighted word
      final actualWord = remainingText.substring(index, index + word.length);
      spans.add(WidgetSpan(
        child: Tooltip(
          message: translation,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.textPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppColors.textPrimary.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              actualWord,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ));

      remainingText = remainingText.substring(index + word.length);
    }

    // Add remaining text
    if (remainingText.isNotEmpty) {
      spans.add(TextSpan(
        text: remainingText,
        style: const TextStyle(fontSize: 18, height: 1.6),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.menu_book,
                  color: AppColors.textPrimary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_level.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.correct.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _level,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.correct,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Vocabulary toggle
          if (_vocabulary.isNotEmpty) ...[
            TextButton.icon(
              onPressed: () =>
                  setState(() => _showVocabulary = !_showVocabulary),
              icon: Icon(
                _showVocabulary ? Icons.visibility_off : Icons.visibility,
                size: 18,
              ),
              label: Text(
                _showVocabulary ? 'Hide Vocabulary' : 'Show Vocabulary',
                style: const TextStyle(fontSize: 12),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
              ),
            ),
            if (_showVocabulary) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: _vocabulary.map((vocab) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceRaised,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: vocab['word'] as String?,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const TextSpan(text: ' - '),
                            TextSpan(
                              text: vocab['translation'] as String?,
                              style: const TextStyle(
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],

          // Story content
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceRaised),
              ),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: _buildHighlightedStory(),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Comprehension question
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Comprehension Question:',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  _question,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Answer options
          ...widget.exercise.options.map((option) {
            final isSelected = _selectedAnswer == option;
            final isCorrectOption = option == widget.exercise.correctAnswer;

            Color backgroundColor = AppColors.surfaceRaised;
            Color borderColor = Colors.transparent;

            if (_showFeedback && isCorrectOption) {
              backgroundColor = AppColors.correct.withValues(alpha: 0.2);
              borderColor = AppColors.correct;
            } else if (_showFeedback && isSelected && !_isCorrect) {
              backgroundColor = AppColors.incorrect.withValues(alpha: 0.2);
              borderColor = AppColors.incorrect;
            } else if (isSelected) {
              backgroundColor = AppColors.textPrimary.withValues(alpha: 0.2);
              borderColor = AppColors.textPrimary;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () => _selectAnswer(option),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor, width: 2),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(option,
                              style: const TextStyle(fontSize: 14)),
                        ),
                        if (_showFeedback && isCorrectOption)
                          const Icon(Icons.check_circle,
                              color: AppColors.correct, size: 20),
                        if (_showFeedback && isSelected && !_isCorrect)
                          const Icon(Icons.cancel,
                              color: AppColors.incorrect, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 8),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _selectedAnswer != null && !_showFeedback
                  ? _checkAnswer
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textPrimary,
                foregroundColor: Colors.black,
                disabledBackgroundColor: AppColors.surfaceRaised,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('CHECK ANSWER',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
