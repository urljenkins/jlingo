import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../models/exercise.dart';

/// Widget for dialogue-based listening comprehension
/// Plays dialogues (news, stories, conversations) followed by comprehension questions
class DialogueListeningWidget extends StatefulWidget {
  final Exercise exercise;
  final void Function(bool) onAnswer;

  const DialogueListeningWidget({
    super.key,
    required this.exercise,
    required this.onAnswer,
  });

  @override
  State<DialogueListeningWidget> createState() =>
      _DialogueListeningWidgetState();
}

class _DialogueListeningWidgetState extends State<DialogueListeningWidget> {
  final _tts = FlutterTts();
  final _audioPlayer = AudioPlayer();

  bool _isPlaying = false;
  bool _hasListened = false;
  bool _showQuestion = false;
  int _selectedOption = -1;
  bool _showFeedback = false;
  bool _isCorrect = false;
  int _playCount = 0;
  int _currentLineIndex = 0;

  // Parsed from metadata
  List<_DialogueLine> _dialogueLines = [];
  String _question = '';
  List<String> _answerOptions = [];
  int _correctOptionIndex = 0;
  String? _context;
  String _dialogueType = 'dialogue';

  bool get _hasNativeAudio =>
      widget.exercise.audioPath != null &&
      widget.exercise.audioPath!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
    _parseMetadata();
  }

  Future<void> _initialize() async {
    await _tts.setLanguage(widget.exercise.targetLanguage ?? 'es-ES');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);

    _tts.setCompletionHandler(_playNextLine);

    if (_hasNativeAudio) {
      _audioPlayer.onPlayerComplete.listen((_) {
        setState(() {
          _isPlaying = false;
          _hasListened = true;
          _showQuestion = true;
        });
      });
    }
  }

  void _parseMetadata() {
    final metadata = widget.exercise.metadata ?? {};

    // Parse dialogue lines
    final lines = metadata['dialogue'] as List<dynamic>? ?? [];
    _dialogueLines = lines.map((line) {
      if (line is Map<String, dynamic>) {
        return _DialogueLine(
          speaker: line['speaker'] as String? ?? '',
          text: line['text'] as String? ?? '',
          translation: line['translation'] as String?,
        );
      }
      return _DialogueLine(speaker: '', text: line.toString());
    }).toList();

    // If no dialogue lines in metadata, use question as single line
    if (_dialogueLines.isEmpty) {
      _dialogueLines = [
        _DialogueLine(speaker: '', text: widget.exercise.question)
      ];
    }

    // Parse question and options
    _question =
        metadata['comprehensionQuestion'] as String? ?? 'What did you hear?';
    _answerOptions = (metadata['options'] as List<dynamic>?)
            ?.map((o) => o.toString())
            .toList() ??
        widget.exercise.options;
    _correctOptionIndex = metadata['correctOptionIndex'] as int? ?? 0;
    if (_correctOptionIndex >= _answerOptions.length &&
        _answerOptions.isNotEmpty) {
      _correctOptionIndex = 0;
    }

    // Parse context and type
    _context = metadata['context'] as String?;
    _dialogueType = metadata['type'] as String? ?? 'dialogue';
  }

  Future<void> _playDialogue() async {
    setState(() {
      _isPlaying = true;
      _playCount++;
      _currentLineIndex = 0;
    });

    if (_hasNativeAudio) {
      try {
        await _audioPlayer.play(AssetSource(widget.exercise.audioPath!));
      } catch (e) {
        // Asset missing or unplayable - fall back to line-by-line TTS.
        debugPrint('Dialogue audio failed for ${widget.exercise.id}: $e');
        await _playCurrentLine();
      }
    } else {
      await _playCurrentLine();
    }
  }

  Future<void> _playCurrentLine() async {
    if (_currentLineIndex < _dialogueLines.length) {
      final line = _dialogueLines[_currentLineIndex];
      setState(() {}); // Update UI to highlight current line
      await _tts.speak(line.text);
    } else {
      // Finished playing all lines
      setState(() {
        _isPlaying = false;
        _hasListened = true;
        _showQuestion = true;
      });
    }
  }

  void _playNextLine() {
    if (_isPlaying && _currentLineIndex < _dialogueLines.length - 1) {
      _currentLineIndex++;
      Future.delayed(const Duration(milliseconds: 500), _playCurrentLine);
    } else {
      setState(() {
        _isPlaying = false;
        _hasListened = true;
        _showQuestion = true;
      });
    }
  }

  Future<void> _stopPlayback() async {
    await _tts.stop();
    await _audioPlayer.stop();
    setState(() => _isPlaying = false);
  }

  void _selectOption(int index) {
    if (_showFeedback) return;
    setState(() => _selectedOption = index);
  }

  void _checkAnswer() {
    if (_selectedOption == -1) return;

    setState(() {
      _isCorrect = _selectedOption == _correctOptionIndex;
      _showFeedback = true;
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        widget.onAnswer(_isCorrect);
      }
    });
  }

  IconData get _dialogueIcon {
    switch (_dialogueType) {
      case 'news':
        return Icons.newspaper;
      case 'story':
        return Icons.auto_stories;
      case 'podcast':
        return Icons.podcasts;
      case 'announcement':
        return Icons.campaign;
      default:
        return Icons.chat_bubble_outline;
    }
  }

  String get _dialogueLabel {
    switch (_dialogueType) {
      case 'news':
        return 'News Report';
      case 'story':
        return 'Short Story';
      case 'podcast':
        return 'Podcast Clip';
      case 'announcement':
        return 'Announcement';
      default:
        return 'Dialogue';
    }
  }

  @override
  void dispose() {
    _tts.stop();
    _audioPlayer.dispose();
    super.dispose();
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
              Icon(_dialogueIcon, color: const Color(0xFF00D9FF), size: 20),
              const SizedBox(width: 8),
              Text(
                'Listening Comprehension - $_dialogueLabel',
                style: const TextStyle(fontSize: 14, color: Colors.white60),
              ),
              const Spacer(),
              if (_playCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.replay, size: 14, color: Colors.white60),
                      const SizedBox(width: 4),
                      Text(
                        '$_playCount',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white60),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Context if available
          if (_context != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00D9FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFF00D9FF).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Color(0xFF00D9FF), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _context!,
                      style:
                          const TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Dialogue display section
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  _showQuestion ? _buildQuestionView() : _buildDialogueView(),
            ),
          ),

          const SizedBox(height: 16),

          // Bottom action
          if (!_showQuestion)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isPlaying ? _stopPlayback : _playDialogue,
                icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
                label: Text(
                  _isPlaying
                      ? 'Stop'
                      : _playCount == 0
                          ? 'Play Dialogue'
                          : 'Play Again',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isPlaying
                      ? const Color(0xFFFF4757)
                      : const Color(0xFF00D9FF),
                  foregroundColor: _isPlaying ? Colors.white : Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            )
          else if (!_showFeedback)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedOption >= 0 ? _checkAnswer : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D9FF),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: Colors.white24,
                ),
                child: const Text(
                  'Check Answer',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDialogueView() {
    return Column(
      children: [
        const Text(
          'Listen to the dialogue carefully',
          style: TextStyle(fontSize: 16, color: Colors.white70),
        ),
        const SizedBox(height: 24),

        // Dialogue lines preview (hidden until played or shown as transcript)
        if (_hasListened)
          Expanded(
            child: ListView.builder(
              itemCount: _dialogueLines.length,
              itemBuilder: (context, index) {
                final line = _dialogueLines[index];
                final isCurrentLine = _isPlaying && index == _currentLineIndex;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCurrentLine
                        ? const Color(0xFF00D9FF).withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isCurrentLine
                        ? Border.all(color: const Color(0xFF00D9FF))
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (line.speaker.isNotEmpty) ...[
                        Text(
                          line.speaker,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF00D9FF),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        line.text,
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (line.translation != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          line.translation!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white54,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          )
        else
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isPlaying ? Icons.volume_up : Icons.headphones,
                    size: 64,
                    color:
                        _isPlaying ? const Color(0xFF00D9FF) : Colors.white38,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _isPlaying ? 'Playing...' : 'Press play to start listening',
                    style: const TextStyle(fontSize: 16, color: Colors.white60),
                  ),
                  if (_isPlaying && _dialogueLines.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Line ${_currentLineIndex + 1} of ${_dialogueLines.length}',
                      style:
                          const TextStyle(fontSize: 14, color: Colors.white38),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuestionView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question
        Row(
          children: [
            const Icon(Icons.help_outline, color: Color(0xFFFFAA00), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _question,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Replay button
            IconButton(
              onPressed: _isPlaying ? null : _playDialogue,
              icon: const Icon(Icons.replay),
              color: const Color(0xFF00D9FF),
              tooltip: 'Listen again',
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(color: Colors.white24),
        const SizedBox(height: 16),

        // Answer options
        Expanded(
          child: ListView.builder(
            itemCount: _answerOptions.length,
            itemBuilder: (context, index) {
              final isSelected = _selectedOption == index;
              final isCorrectAnswer = index == _correctOptionIndex;
              final showCorrect = _showFeedback && isCorrectAnswer;
              final showWrong = _showFeedback && isSelected && !isCorrectAnswer;

              Color backgroundColor;
              Color borderColor;

              if (showCorrect) {
                backgroundColor =
                    const Color(0xFF00FF85).withValues(alpha: 0.2);
                borderColor = const Color(0xFF00FF85);
              } else if (showWrong) {
                backgroundColor =
                    const Color(0xFFFF4757).withValues(alpha: 0.2);
                borderColor = const Color(0xFFFF4757);
              } else if (isSelected) {
                backgroundColor =
                    const Color(0xFF00D9FF).withValues(alpha: 0.2);
                borderColor = const Color(0xFF00D9FF);
              } else {
                backgroundColor = Colors.transparent;
                borderColor = Colors.white24;
              }

              return GestureDetector(
                onTap: () => _selectOption(index),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor, width: 2),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? const Color(0xFF00D9FF)
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF00D9FF)
                                : Colors.white38,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + index), // A, B, C, D
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _answerOptions[index],
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      if (showCorrect)
                        const Icon(Icons.check_circle, color: Color(0xFF00FF85))
                      else if (showWrong)
                        const Icon(Icons.cancel, color: Color(0xFFFF4757)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Feedback
        if (_showFeedback) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isCorrect
                  ? const Color(0xFF00FF85).withValues(alpha: 0.1)
                  : const Color(0xFFFF4757).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isCorrect
                    ? const Color(0xFF00FF85)
                    : const Color(0xFFFF4757),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isCorrect ? Icons.check_circle : Icons.cancel,
                  color: _isCorrect
                      ? const Color(0xFF00FF85)
                      : const Color(0xFFFF4757),
                ),
                const SizedBox(width: 12),
                Text(
                  _isCorrect
                      ? 'Correct! Great listening!'
                      : 'The correct answer was: ${_answerOptions.isNotEmpty && _correctOptionIndex < _answerOptions.length ? _answerOptions[_correctOptionIndex] : ""}',
                  style: TextStyle(
                    fontSize: 14,
                    color: _isCorrect
                        ? const Color(0xFF00FF85)
                        : const Color(0xFFFF4757),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _DialogueLine {
  final String speaker;
  final String text;
  final String? translation;

  _DialogueLine({
    required this.speaker,
    required this.text,
    this.translation,
  });
}
