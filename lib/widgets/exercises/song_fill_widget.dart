import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../models/exercise.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Widget for song-fill exercises
/// Listen to a song and fill in the missing lyrics
class SongFillWidget extends StatefulWidget {
  final Exercise exercise;
  final void Function(bool) onAnswer;

  const SongFillWidget({
    super.key,
    required this.exercise,
    required this.onAnswer,
  });

  @override
  State<SongFillWidget> createState() => _SongFillWidgetState();
}

class _SongFillWidgetState extends State<SongFillWidget>
    with TickerProviderStateMixin {
  final _tts = FlutterTts();
  final _audioPlayer = AudioPlayer();
  final _scrollController = ScrollController();

  bool _isPlaying = false;
  bool _showFeedback = false;
  bool _isCorrect = false;
  int _playCount = 0;
  double _progress = 0.0;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  // Parsed from metadata
  String _songTitle = '';
  String _artist = '';
  List<_LyricLine> _lyrics = [];
  List<_BlankWord> _blanks = [];
  final Map<int, TextEditingController> _controllers = {};
  int _currentLineIndex = 0;

  late AnimationController _progressController;

  bool get _hasNativeAudio =>
      widget.exercise.audioPath != null &&
      widget.exercise.audioPath!.isNotEmpty;

  double _speechRate = 0.5;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
    _parseMetadata();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  Future<void> _initialize() async {
    await _tts.setLanguage(widget.exercise.targetLanguage ?? 'es-ES');
    await _tts.setSpeechRate(_speechRate);
    await _tts.setVolume(1.0);

    if (_hasNativeAudio) {
      _audioPlayer.onDurationChanged.listen((duration) {
        if (mounted) setState(() => _duration = duration);
      });
      _audioPlayer.onPositionChanged.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
            _progress = _duration.inMilliseconds > 0
                ? position.inMilliseconds / _duration.inMilliseconds
                : 0.0;
            _updateCurrentLine();
          });
        }
      });
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _isPlaying = false;
          });
        }
      });
    }
  }

  Future<void> _changeSpeechRate(double rate) async {
    setState(() => _speechRate = rate);
    if (_hasNativeAudio) {
      await _audioPlayer.setPlaybackRate(rate * 2);
    } else {
      await _tts.setSpeechRate(rate);
    }
  }

  void _parseMetadata() {
    final metadata = widget.exercise.metadata ?? {};

    _songTitle = metadata['songTitle'] as String? ?? 'Song';
    _artist = metadata['artist'] as String? ?? 'Unknown Artist';

    // Parse lyrics with timestamps
    final lyricsData = metadata['lyrics'] as List<dynamic>? ?? [];
    _lyrics = lyricsData.map((line) {
      if (line is Map<String, dynamic>) {
        return _LyricLine(
          text: line['text'] as String? ?? '',
          timestamp: Duration(milliseconds: line['timestamp'] as int? ?? 0),
          translation: line['translation'] as String?,
        );
      }
      return _LyricLine(
        text: line.toString(),
        timestamp: Duration.zero,
      );
    }).toList();

    // If no lyrics in metadata, use question as single line
    if (_lyrics.isEmpty) {
      // Split the question into lines by newlines or sentences
      final lines = widget.exercise.question
          .split(RegExp(r'[\n|.]+'))
          .where((l) => l.trim().isNotEmpty)
          .toList();
      _lyrics = lines
          .map((line) => _LyricLine(
                text: line.trim(),
                timestamp: Duration.zero,
              ))
          .toList();
    }

    // Parse blanks (words to fill in)
    final blanksData = metadata['blanks'] as List<dynamic>? ?? [];
    _blanks = blanksData.asMap().entries.map((entry) {
      final index = entry.key;
      final blank = entry.value;
      if (blank is Map<String, dynamic>) {
        return _BlankWord(
          lineIndex: blank['lineIndex'] as int? ?? 0,
          wordIndex: blank['wordIndex'] as int? ?? 0,
          correctWord: blank['correctWord'] as String? ?? '',
          hint: blank['hint'] as String?,
          options: (blank['options'] as List<dynamic>?)
              ?.map((o) => o.toString())
              .toList(),
        );
      }
      return _BlankWord(
        lineIndex: 0,
        wordIndex: index,
        correctWord: blank.toString(),
      );
    }).toList();

    // If no blanks defined, extract from correctAnswer
    if (_blanks.isEmpty && widget.exercise.correctAnswer.isNotEmpty) {
      final answers = widget.exercise.correctAnswer.split(',');
      for (int i = 0; i < answers.length; i++) {
        _blanks.add(_BlankWord(
          lineIndex: i < _lyrics.length ? i : 0,
          wordIndex: 0,
          correctWord: answers[i].trim(),
        ));
      }
    }

    // Initialize controllers for each blank
    for (int i = 0; i < _blanks.length; i++) {
      _controllers[i] = TextEditingController();
    }
  }

  void _updateCurrentLine() {
    for (int i = _lyrics.length - 1; i >= 0; i--) {
      if (_position >= _lyrics[i].timestamp) {
        if (_currentLineIndex != i) {
          setState(() => _currentLineIndex = i);
          _scrollToCurrentLine();
        }
        break;
      }
    }
  }

  void _scrollToCurrentLine() {
    if (_currentLineIndex < _lyrics.length) {
      final offset = _currentLineIndex * 80.0; // Approximate line height
      _scrollController.animateTo(
        offset.clamp(0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _playPause() async {
    if (_isPlaying) {
      await _pause();
    } else {
      await _play();
    }
  }

  Future<void> _play() async {
    setState(() {
      _isPlaying = true;
      _playCount++;
    });

    if (_hasNativeAudio) {
      await _audioPlayer.resume();
    } else {
      // TTS fallback - read lyrics
      for (int i = _currentLineIndex; i < _lyrics.length && _isPlaying; i++) {
        setState(() => _currentLineIndex = i);
        await _tts.speak(_lyrics[i].text);
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
      setState(() => _isPlaying = false);
    }
  }

  Future<void> _pause() async {
    if (_hasNativeAudio) {
      await _audioPlayer.pause();
    } else {
      await _tts.stop();
    }
    setState(() => _isPlaying = false);
  }

  Future<void> _restart() async {
    if (_hasNativeAudio) {
      try {
        await _audioPlayer.seek(Duration.zero);
        await _audioPlayer.play(AssetSource(widget.exercise.audioPath!));
      } catch (e) {
        debugPrint('Song audio failed for ${widget.exercise.id}: $e');
        if (mounted) setState(() => _isPlaying = false);
        return;
      }
    } else {
      setState(() => _currentLineIndex = 0);
    }
    setState(() {
      _isPlaying = true;
      _playCount++;
    });
  }

  void _checkAnswers() {
    int correctCount = 0;

    for (int i = 0; i < _blanks.length; i++) {
      final userAnswer = _controllers[i]?.text.trim().toLowerCase() ?? '';
      final correctAnswer = _blanks[i].correctWord.toLowerCase();

      if (userAnswer == correctAnswer) {
        correctCount++;
        _blanks[i].isCorrect = true;
      } else {
        _blanks[i].isCorrect = false;
      }
    }

    setState(() {
      _isCorrect = correctCount == _blanks.length;
      _showFeedback = true;
    });

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        widget.onAnswer(_isCorrect);
      }
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _tts.stop();
    _audioPlayer.dispose();
    _scrollController.dispose();
    _progressController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenInset,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.music_note,
                  color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Song Fill Exercise',
                  style:
                      TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_playCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.replay,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '$_playCount',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Song info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.textSecondary.withValues(alpha: 0.2),
                  AppColors.textSecondary.withValues(alpha: 0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.textSecondary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.textSecondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.album,
                        color: AppColors.textSecondary,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _songTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _artist,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Progress bar
                if (_hasNativeAudio) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Expanded(
                        child: Slider(
                          value: _progress,
                          onChanged: (value) async {
                            final position = Duration(
                              milliseconds:
                                  (value * _duration.inMilliseconds).toInt(),
                            );
                            await _audioPlayer.seek(position);
                          },
                          activeColor: AppColors.textSecondary,
                          inactiveColor: AppColors.border,
                        ),
                      ),
                      Text(
                        _formatDuration(_duration),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],

                // Playback controls
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _restart,
                      icon: const Icon(Icons.replay,
                          color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: _playPause,
                      icon: Icon(
                        _isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        color: AppColors.textSecondary,
                        size: 52,
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.skip_next,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Speed:',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      _SongSpeedButton(
                        label: '0.25x',
                        isSelected: _speechRate == 0.125,
                        onTap: () => _changeSpeechRate(0.125),
                      ),
                      _SongSpeedButton(
                        label: '0.5x',
                        isSelected: _speechRate == 0.25,
                        onTap: () => _changeSpeechRate(0.25),
                      ),
                      _SongSpeedButton(
                        label: '0.75x',
                        isSelected: _speechRate == 0.5,
                        onTap: () => _changeSpeechRate(0.5),
                      ),
                      _SongSpeedButton(
                        label: '1x',
                        isSelected: _speechRate == 0.75,
                        onTap: () => _changeSpeechRate(0.75),
                      ),
                      _SongSpeedButton(
                        label: '1.5x',
                        isSelected: _speechRate == 1.0,
                        onTap: () => _changeSpeechRate(1.0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Instructions
          Text(
            'Fill in the missing words in the lyrics below:',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),

          // Lyrics with blanks
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _lyrics.length,
                itemBuilder: (context, lineIndex) {
                  final line = _lyrics[lineIndex];
                  final isCurrentLine =
                      _isPlaying && lineIndex == _currentLineIndex;
                  final blanksInLine =
                      _blanks.where((b) => b.lineIndex == lineIndex).toList();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCurrentLine
                          ? AppColors.textSecondary.withValues(alpha: 0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isCurrentLine
                          ? Border.all(color: AppColors.textSecondary)
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLyricLine(line.text, blanksInLine),
                        if (line.translation != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            line.translation!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textDisabled,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Feedback and check button
          if (_showFeedback)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: _isCorrect
                    ? AppColors.correct.withValues(alpha: 0.1)
                    : AppColors.incorrect.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isCorrect ? AppColors.correct : AppColors.incorrect,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isCorrect ? Icons.check_circle : Icons.close,
                    color: _isCorrect ? AppColors.correct : AppColors.incorrect,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isCorrect
                          ? 'All correct! Great job!'
                          : 'Some answers are incorrect. Check the highlighted words.',
                      style: TextStyle(
                        color: _isCorrect
                            ? AppColors.correct
                            : AppColors.incorrect,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _showFeedback ? null : _checkAnswers,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textSecondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledBackgroundColor: AppColors.border,
              ),
              child: const Text(
                'Check Answers',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricLine(String text, List<_BlankWord> blanksInLine) {
    if (blanksInLine.isEmpty) {
      return Text(
        text,
        style: const TextStyle(fontSize: 16),
      );
    }

    // Build line with inline text fields for blanks
    final words = text.split(' ');
    final widgets = <Widget>[];
    for (int i = 0; i < words.length; i++) {
      final word = words[i];

      // Check if this word position has a blank
      final blank = blanksInLine.firstWhere(
        (b) => b.wordIndex == i,
        orElse: () => _BlankWord(lineIndex: -1, wordIndex: -1, correctWord: ''),
      );

      if (blank.lineIndex != -1) {
        // This is a blank
        final blankIndex = _blanks.indexWhere((b) => b == blank);
        final controller = _controllers[blankIndex];
        final isCorrectAnswer = blank.isCorrect;
        final showFeedbackForBlank = _showFeedback && blank.isCorrect != null;

        widgets.add(
          Container(
            width: 100,
            height: 32,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: blank.hint ?? '____',
                hintStyle: const TextStyle(color: AppColors.textDisabled),
                filled: true,
                fillColor: showFeedbackForBlank
                    ? (isCorrectAnswer == true
                        ? AppColors.correct.withValues(alpha: 0.2)
                        : AppColors.incorrect.withValues(alpha: 0.2))
                    : AppColors.surfaceRaised,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(
                    color: showFeedbackForBlank
                        ? (isCorrectAnswer == true
                            ? AppColors.correct
                            : AppColors.incorrect)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(
                    color: AppColors.textSecondary,
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                suffixIcon: showFeedbackForBlank && isCorrectAnswer == false
                    ? Tooltip(
                        message: 'Correct: ${blank.correctWord}',
                        child: const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.incorrect,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        );
      } else {
        // Regular word
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              word,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        );
      }
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: widgets,
    );
  }
}

class _LyricLine {
  final String text;
  final Duration timestamp;
  final String? translation;

  _LyricLine({
    required this.text,
    required this.timestamp,
    this.translation,
  });
}

class _BlankWord {
  final int lineIndex;
  final int wordIndex;
  final String correctWord;
  final String? hint;
  final List<String>? options;
  bool? isCorrect;

  _BlankWord({
    required this.lineIndex,
    required this.wordIndex,
    required this.correctWord,
    this.hint,
    this.options,
  });
}

class _SongSpeedButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SongSpeedButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textSecondary : AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
