import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../models/exercise.dart';

/// Widget for playing audio from native speakers
/// Supports both pre-recorded audio files and TTS fallback
class NativeAudioWidget extends StatefulWidget {
  final Exercise exercise;
  final void Function(bool) onAnswer;

  const NativeAudioWidget({
    super.key,
    required this.exercise,
    required this.onAnswer,
  });

  @override
  State<NativeAudioWidget> createState() => _NativeAudioWidgetState();
}

class _NativeAudioWidgetState extends State<NativeAudioWidget> {
  final _controller = TextEditingController();
  final _tts = FlutterTts();
  final _audioPlayer = AudioPlayer();

  bool _showFeedback = false;
  bool _isCorrect = false;
  bool _isPlaying = false;
  bool _hasPlayedOnce = false;
  double _speechRate = 0.5;
  double _progress = 0.0;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  bool get _hasNativeAudio =>
      widget.exercise.audioPath != null &&
      widget.exercise.audioPath!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    // Setup TTS as fallback
    await _tts.setLanguage(widget.exercise.targetLanguage ?? 'es-ES');
    await _tts.setSpeechRate(_speechRate);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    // Setup audio player listeners if we have native audio
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
          });
        }
      });
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlaying = false);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _tts.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    setState(() {
      _isPlaying = true;
      _hasPlayedOnce = true;
    });

    if (_hasNativeAudio) {
      // Play pre-recorded native speaker audio
      await _audioPlayer.play(AssetSource(widget.exercise.audioPath!));
    } else {
      // Fallback to TTS
      await _tts.speak(widget.exercise.question);
      setState(() => _isPlaying = false);
    }
  }

  Future<void> _pauseAudio() async {
    if (_hasNativeAudio) {
      await _audioPlayer.pause();
    } else {
      await _tts.stop();
    }
    setState(() => _isPlaying = false);
  }

  Future<void> _changeSpeechRate(double rate) async {
    setState(() => _speechRate = rate);
    if (_hasNativeAudio) {
      await _audioPlayer.setPlaybackRate(rate * 2); // 0.5 -> 1x, 1.0 -> 2x
    } else {
      await _tts.setSpeechRate(rate);
    }
  }

  void _checkAnswer() {
    final userAnswer = _controller.text.trim().toLowerCase();
    final correctAnswer = widget.exercise.correctAnswer.toLowerCase();

    setState(() {
      _isCorrect = userAnswer == correctAnswer;
      _showFeedback = true;
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) widget.onAnswer(_isCorrect);
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _hasNativeAudio ? Icons.record_voice_over : Icons.volume_up,
                color: const Color(0xFF00D9FF),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _hasNativeAudio ? 'Native Speaker Audio' : 'Listening Exercise',
                style: const TextStyle(fontSize: 14, color: Colors.white60),
              ),
              if (_hasNativeAudio) ...[
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FF85).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, color: Color(0xFF00FF85), size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Native',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF00FF85)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Listen carefully and type what you hear',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 24),

          // Audio Player Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2A2A2A),
                  const Color(0xFF1A1A1A).withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF00D9FF).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                // Waveform visualization (decorative)
                if (_isPlaying)
                  Container(
                    height: 40,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        20,
                        (index) => _WaveBar(
                          isPlaying: _isPlaying,
                          index: index,
                        ),
                      ),
                    ),
                  ),

                // Play button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _isPlaying ? _pauseAudio : _playAudio,
                      icon: Icon(
                        _isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        size: 64,
                        color: const Color(0xFF00D9FF),
                      ),
                    ),
                  ],
                ),

                // Progress bar for native audio
                if (_hasNativeAudio && _hasPlayedOnce) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white60),
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
                          activeColor: const Color(0xFF00D9FF),
                          inactiveColor: Colors.white24,
                        ),
                      ),
                      Text(
                        _formatDuration(_duration),
                        style: const TextStyle(
                            fontSize: 12, color: Colors.white60),
                      ),
                    ],
                  ),
                ],

                // Speed control
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Speed:',
                      style: TextStyle(fontSize: 12, color: Colors.white60),
                    ),
                    const SizedBox(width: 8),
                    _SpeedButton(
                      label: '0.5x',
                      isSelected: _speechRate == 0.25,
                      onTap: () => _changeSpeechRate(0.25),
                    ),
                    _SpeedButton(
                      label: '0.75x',
                      isSelected: _speechRate == 0.5,
                      onTap: () => _changeSpeechRate(0.5),
                    ),
                    _SpeedButton(
                      label: '1x',
                      isSelected: _speechRate == 0.75,
                      onTap: () => _changeSpeechRate(0.75),
                    ),
                    _SpeedButton(
                      label: '1.5x',
                      isSelected: _speechRate == 1.0,
                      onTap: () => _changeSpeechRate(1.0),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Text input
          TextField(
            controller: _controller,
            style: const TextStyle(fontSize: 18),
            decoration: InputDecoration(
              hintText: 'Type what you hear',
              filled: true,
              fillColor: _showFeedback
                  ? (_isCorrect
                      ? const Color(0xFF00FF85).withValues(alpha: 0.1)
                      : const Color(0xFFFF4757).withValues(alpha: 0.1))
                  : const Color(0xFF2A2A2A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _showFeedback
                      ? (_isCorrect
                          ? const Color(0xFF00FF85)
                          : const Color(0xFFFF4757))
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _showFeedback
                      ? (_isCorrect
                          ? const Color(0xFF00FF85)
                          : const Color(0xFFFF4757))
                      : const Color(0xFF00D9FF),
                  width: 2,
                ),
              ),
            ),
            onSubmitted: (_) => _checkAnswer(),
          ),

          if (_showFeedback) ...[
            const SizedBox(height: 16),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isCorrect ? 'Perfect!' : 'Not quite',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _isCorrect
                                ? const Color(0xFF00FF85)
                                : const Color(0xFFFF4757),
                          ),
                        ),
                        if (!_isCorrect) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Correct answer: ${widget.exercise.correctAnswer}',
                            style: const TextStyle(
                                fontSize: 14, color: Colors.white70),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Spacer(),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _hasPlayedOnce && !_showFeedback ? _checkAnswer : null,
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
}

class _SpeedButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SpeedButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00D9FF) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.black : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _WaveBar extends StatefulWidget {
  final bool isPlaying;
  final int index;

  const _WaveBar({
    required this.isPlaying,
    required this.index,
  });

  @override
  State<_WaveBar> createState() => _WaveBarState();
}

class _WaveBarState extends State<_WaveBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300 + (widget.index * 50) % 400),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    if (widget.isPlaying) {
      unawaited(_controller.repeat(reverse: true));
    }
  }

  @override
  void didUpdateWidget(_WaveBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.isAnimating) {
      unawaited(_controller.repeat(reverse: true));
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 3,
          height: 20 * _animation.value,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF00D9FF),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }
}
