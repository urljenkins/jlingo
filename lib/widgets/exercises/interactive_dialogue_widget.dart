import 'package:flutter/material.dart';
import '../../models/exercise.dart';
import '../../theme/app_colors.dart';

/// Interactive Dialogue Widget
/// Displays short conversations on various topics where users
/// participate by selecting the appropriate response.
///
/// Metadata structure:
/// {
///   "dialogue": [
///     {"speaker": "A", "text": "Hola, ¿cómo estás?", "isNative": true},
///     {"speaker": "B", "text": "___", "isUserTurn": true, "options": ["Bien, gracias", "Adiós", "No sé"]},
///     {"speaker": "A", "text": "¡Qué bueno!", "isNative": true}
///   ],
///   "topic": "Greetings"
/// }
class InteractiveDialogueWidget extends StatefulWidget {
  final Exercise exercise;
  final void Function(bool) onAnswer;

  const InteractiveDialogueWidget({
    super.key,
    required this.exercise,
    required this.onAnswer,
  });

  @override
  State<InteractiveDialogueWidget> createState() =>
      _InteractiveDialogueWidgetState();
}

class _InteractiveDialogueWidgetState extends State<InteractiveDialogueWidget> {
  int _currentLineIndex = 0;
  String? _selectedResponse;
  bool _showFeedback = false;
  bool _isCorrect = false;
  List<Map<String, dynamic>> _dialogue = [];
  final List<Map<String, dynamic>> _displayedLines = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadDialogue();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadDialogue() {
    final metadata = widget.exercise.metadata;
    if (metadata != null && metadata['dialogue'] != null) {
      _dialogue = List<Map<String, dynamic>>.from(
        (metadata['dialogue'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map)),
      );
      _advanceDialogue();
    }
  }

  void _advanceDialogue() {
    while (_currentLineIndex < _dialogue.length) {
      final line = _dialogue[_currentLineIndex];
      if (line['isUserTurn'] == true) {
        // Stop at user turn
        break;
      }
      _displayedLines.add(line);
      _currentLineIndex++;
    }
    setState(() {});
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _selectResponse(String response) {
    if (_showFeedback) return;

    setState(() {
      _selectedResponse = response;
    });
  }

  void _submitResponse() {
    if (_selectedResponse == null || _showFeedback) return;

    final correctAnswer = widget.exercise.correctAnswer;

    setState(() {
      _isCorrect = _selectedResponse == correctAnswer;
      _showFeedback = true;
      // Add user's response to displayed lines
      _displayedLines.add({
        'speaker': 'You',
        'text': _selectedResponse,
        'isUserResponse': true,
        'isCorrect': _isCorrect,
      });
    });

    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        if (_isCorrect) {
          // Continue dialogue after correct answer
          _currentLineIndex++;
          if (_currentLineIndex < _dialogue.length) {
            _advanceDialogue();
            // Check if there's another user turn
            if (_currentLineIndex < _dialogue.length &&
                _dialogue[_currentLineIndex]['isUserTurn'] == true) {
              setState(() {
                _showFeedback = false;
                _selectedResponse = null;
              });
              return;
            }
          }
        }
        widget.onAnswer(_isCorrect);
      }
    });
  }

  List<String> get _currentOptions {
    if (_currentLineIndex < _dialogue.length) {
      final line = _dialogue[_currentLineIndex];
      if (line['options'] != null) {
        return List<String>.from(line['options'] as List);
      }
    }
    return widget.exercise.options;
  }

  @override
  Widget build(BuildContext context) {
    final topic = widget.exercise.metadata?['topic'] ?? 'Conversation';

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline,
                  color: AppColors.textPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Interactive Dialogue: $topic',
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dialogue display
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceRaised),
              ),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _displayedLines.length,
                itemBuilder: (context, index) {
                  final line = _displayedLines[index];
                  return _buildDialogueBubble(line);
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Response options
          if (_currentLineIndex < _dialogue.length &&
              _dialogue[_currentLineIndex]['isUserTurn'] == true) ...[
            const Text(
              'Choose your response:',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _currentOptions.map((option) {
                final isSelected = _selectedResponse == option;
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
                  backgroundColor =
                      AppColors.textPrimary.withValues(alpha: 0.2);
                  borderColor = AppColors.textPrimary;
                }

                return Material(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () => _selectResponse(option),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor, width: 2),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Text(option, style: const TextStyle(fontSize: 14)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _selectedResponse != null && !_showFeedback
                    ? _submitResponse
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: AppColors.surfaceRaised,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Respond',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDialogueBubble(Map<String, dynamic> line) {
    final isUserResponse = line['isUserResponse'] == true;
    final isCorrect = line['isCorrect'] == true;
    final speaker = line['speaker'] ?? '';
    final text = line['text'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUserResponse ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUserResponse)
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.textPrimary.withValues(alpha: 0.2),
              child: Text(
                speaker as String,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textPrimary),
              ),
            ),
          if (!isUserResponse) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUserResponse
                    ? (isCorrect
                        ? AppColors.correct.withValues(alpha: 0.2)
                        : AppColors.incorrect.withValues(alpha: 0.2))
                    : AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(16),
                border: isUserResponse
                    ? Border.all(
                        color:
                            isCorrect ? AppColors.correct : AppColors.incorrect,
                      )
                    : null,
              ),
              child: Text(
                text as String,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          if (isUserResponse) const SizedBox(width: 8),
          if (isUserResponse)
            Icon(
              isCorrect ? Icons.check_circle : Icons.cancel,
              color: isCorrect ? AppColors.correct : AppColors.incorrect,
              size: 20,
            ),
        ],
      ),
    );
  }
}
