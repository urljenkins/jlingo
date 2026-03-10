import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../models/exercise.dart';

/// Enhanced pronunciation practice widget with detailed feedback
/// Provides word-by-word analysis, accuracy scores, and suggestions
class PronunciationPracticeWidget extends StatefulWidget {
  final Exercise exercise;
  final void Function(bool) onAnswer;

  const PronunciationPracticeWidget({
    super.key,
    required this.exercise,
    required this.onAnswer,
  });

  @override
  State<PronunciationPracticeWidget> createState() =>
      _PronunciationPracticeWidgetState();
}

class _PronunciationPracticeWidgetState
    extends State<PronunciationPracticeWidget> with TickerProviderStateMixin {
  final _speech = SpeechToText();
  final _tts = FlutterTts();

  bool _isListening = false;
  bool _showFeedback = false;
  bool _isCorrect = false;
  String _recognizedText = '';
  double _confidence = 0.0;
  List<_WordAnalysis> _wordAnalysis = [];
  int _attempts = 0;
  double _overallScore = 0.0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    unawaited(_initializeSpeech());
    unawaited(_initializeTts());
    _setupAnimations();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  Future<void> _initializeSpeech() async {
    await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' && _isListening) {
          _stopListening();
        }
      },
    );
  }

  Future<void> _initializeTts() async {
    await _tts.setLanguage(widget.exercise.targetLanguage ?? 'es-ES');
    await _tts.setSpeechRate(0.4);
    await _tts.setVolume(1.0);
  }

  Future<void> _playReference() async {
    await _tts.speak(widget.exercise.question);
  }

  Future<void> _startListening() async {
    if (!_speech.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
      return;
    }

    setState(() {
      _isListening = true;
      _recognizedText = '';
      _wordAnalysis = [];
      _showFeedback = false;
    });

    unawaited(_pulseController.repeat(reverse: true));

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _recognizedText = result.recognizedWords;
          _confidence = result.confidence;
        });
      },
      localeId: widget.exercise.targetLanguage ?? 'es-ES',
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
    );
  }

  Future<void> _stopListening() async {
    _pulseController.stop();
    _pulseController.reset();

    await _speech.stop();
    setState(() => _isListening = false);

    if (_recognizedText.isNotEmpty) {
      _analyzePronounciation();
    }
  }

  void _analyzePronounciation() {
    _attempts++;
    final targetWords = _normalizeText(widget.exercise.correctAnswer)
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    final spokenWords = _normalizeText(_recognizedText)
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();

    // Word-by-word analysis
    _wordAnalysis = [];
    int correctCount = 0;

    for (int i = 0; i < targetWords.length; i++) {
      final targetWord = targetWords[i];
      String? spokenWord;
      _WordStatus status;
      double similarity = 0.0;

      if (i < spokenWords.length) {
        spokenWord = spokenWords[i];
        similarity = _calculateSimilarity(targetWord, spokenWord);

        if (similarity >= 0.9) {
          status = _WordStatus.perfect;
          correctCount++;
        } else if (similarity >= 0.7) {
          status = _WordStatus.close;
          correctCount += 0.5.toInt();
        } else if (similarity >= 0.4) {
          status = _WordStatus.needsWork;
        } else {
          status = _WordStatus.missed;
        }
      } else {
        status = _WordStatus.missed;
      }

      _wordAnalysis.add(_WordAnalysis(
        targetWord: targetWord,
        spokenWord: spokenWord,
        status: status,
        similarity: similarity,
      ));
    }

    // Calculate overall score
    _overallScore = targetWords.isEmpty
        ? 0.0
        : (correctCount / targetWords.length * 100).clamp(0, 100);

    // Consider speech recognition confidence
    final confidenceAdjusted =
        _overallScore * (_confidence > 0 ? _confidence : 0.8);

    _isCorrect = confidenceAdjusted >= 70;

    setState(() => _showFeedback = true);

    // Auto-advance after delay if passed
    if (_isCorrect) {
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) {
          widget.onAnswer(true);
        }
      });
    }
  }

  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  double _calculateSimilarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;

    final distance = _levenshteinDistance(a, b);
    final maxLength = a.length > b.length ? a.length : b.length;
    return 1.0 - (distance / maxLength);
  }

  int _levenshteinDistance(String a, String b) {
    final matrix = List.generate(
      a.length + 1,
      (i) => List.filled(b.length + 1, 0),
    );

    for (var i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }
    for (var j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }

    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[a.length][b.length];
  }

  String _getFeedbackMessage() {
    if (_overallScore >= 90) return 'Excellent pronunciation!';
    if (_overallScore >= 80) return 'Great job! Almost perfect.';
    if (_overallScore >= 70) return 'Good! Keep practicing.';
    if (_overallScore >= 50) {
      return 'Getting there! Focus on the highlighted words.';
    }
    return 'Keep trying! Listen to the reference and try again.';
  }

  String _getTip() {
    final problematicWords = _wordAnalysis
        .where((w) =>
            w.status == _WordStatus.needsWork || w.status == _WordStatus.missed)
        .toList();

    if (problematicWords.isEmpty) {
      return 'Your pronunciation is excellent!';
    }

    final word = problematicWords.first.targetWord;
    return 'Tip: Practice saying "$word" slowly, breaking it into syllables.';
  }

  void _tryAgain() {
    setState(() {
      _showFeedback = false;
      _recognizedText = '';
      _wordAnalysis = [];
    });
  }

  void _skip() {
    widget.onAnswer(false);
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    _pulseController.dispose();
    _waveController.dispose();
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
              const Icon(Icons.mic, color: Color(0xFF00D9FF), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Pronunciation Practice',
                style: TextStyle(fontSize: 14, color: Colors.white60),
              ),
              const Spacer(),
              if (_attempts > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Attempt $_attempts',
                    style: const TextStyle(fontSize: 12, color: Colors.white60),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Target phrase
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Say this phrase:',
                      style: TextStyle(fontSize: 14, color: Colors.white60),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _playReference,
                      icon: const Icon(
                        Icons.volume_up,
                        color: Color(0xFF00D9FF),
                      ),
                      tooltip: 'Listen to reference',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.exercise.question,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Microphone button
          Center(
            child: GestureDetector(
              onTapDown: (_) => _startListening(),
              onTapUp: (_) => _stopListening(),
              onTapCancel: _stopListening,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isListening ? _pulseAnimation.value : 1.0,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: _isListening
                              ? [
                                  const Color(0xFFFF4757)
                                      .withValues(alpha: 0.3),
                                  const Color(0xFFFF4757)
                                      .withValues(alpha: 0.1),
                                ]
                              : [
                                  const Color(0xFF00D9FF)
                                      .withValues(alpha: 0.3),
                                  const Color(0xFF00D9FF)
                                      .withValues(alpha: 0.1),
                                ],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isListening
                              ? const Color(0xFFFF4757)
                              : const Color(0xFF00D9FF),
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        size: 60,
                        color: _isListening
                            ? const Color(0xFFFF4757)
                            : const Color(0xFF00D9FF),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _isListening ? 'Listening... Release to stop' : 'Hold to speak',
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ),

          // Live recognition text
          if (_isListening && _recognizedText.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFF4757), width: 2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hearing, color: Color(0xFFFF4757)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _recognizedText,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Feedback section
          if (_showFeedback) ...[
            const SizedBox(height: 24),
            _buildFeedbackSection(),
          ],

          const Spacer(),

          // Bottom actions
          if (_showFeedback && !_isCorrect)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _skip,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Skip'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _tryAgain,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D9FF),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Try Again',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isCorrect
            ? const Color(0xFF00FF85).withValues(alpha: 0.1)
            : const Color(0xFFFFAA00).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isCorrect ? const Color(0xFF00FF85) : const Color(0xFFFFAA00),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score header
          Row(
            children: [
              Icon(
                _isCorrect ? Icons.check_circle : Icons.info_outline,
                color: _isCorrect
                    ? const Color(0xFF00FF85)
                    : const Color(0xFFFFAA00),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getFeedbackMessage(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _isCorrect
                            ? const Color(0xFF00FF85)
                            : const Color(0xFFFFAA00),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Accuracy: ${_overallScore.toStringAsFixed(0)}%',
                      style:
                          const TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              // Circular score indicator
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: _overallScore / 100,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation(
                        _isCorrect
                            ? const Color(0xFF00FF85)
                            : const Color(0xFFFFAA00),
                      ),
                      strokeWidth: 6,
                    ),
                    Text(
                      _overallScore.toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),

          // Word-by-word analysis
          const Text(
            'Word Analysis:',
            style: TextStyle(fontSize: 14, color: Colors.white60),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _wordAnalysis.map((analysis) {
              return _WordChip(analysis: analysis);
            }).toList(),
          ),

          // Tip
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline,
                    color: Color(0xFFFFAA00), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _getTip(),
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _WordStatus { perfect, close, needsWork, missed }

class _WordAnalysis {
  final String targetWord;
  final String? spokenWord;
  final _WordStatus status;
  final double similarity;

  _WordAnalysis({
    required this.targetWord,
    this.spokenWord,
    required this.status,
    required this.similarity,
  });
}

class _WordChip extends StatelessWidget {
  final _WordAnalysis analysis;

  const _WordChip({required this.analysis});

  Color get _backgroundColor {
    switch (analysis.status) {
      case _WordStatus.perfect:
        return const Color(0xFF00FF85).withValues(alpha: 0.2);
      case _WordStatus.close:
        return const Color(0xFF00D9FF).withValues(alpha: 0.2);
      case _WordStatus.needsWork:
        return const Color(0xFFFFAA00).withValues(alpha: 0.2);
      case _WordStatus.missed:
        return const Color(0xFFFF4757).withValues(alpha: 0.2);
    }
  }

  Color get _borderColor {
    switch (analysis.status) {
      case _WordStatus.perfect:
        return const Color(0xFF00FF85);
      case _WordStatus.close:
        return const Color(0xFF00D9FF);
      case _WordStatus.needsWork:
        return const Color(0xFFFFAA00);
      case _WordStatus.missed:
        return const Color(0xFFFF4757);
    }
  }

  IconData get _icon {
    switch (analysis.status) {
      case _WordStatus.perfect:
        return Icons.check;
      case _WordStatus.close:
        return Icons.thumb_up_outlined;
      case _WordStatus.needsWork:
        return Icons.refresh;
      case _WordStatus.missed:
        return Icons.close;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: analysis.spokenWord != null
          ? 'You said: "${analysis.spokenWord}" (${(analysis.similarity * 100).toStringAsFixed(0)}% match)'
          : 'Word was not detected',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 16, color: _borderColor),
            const SizedBox(width: 6),
            Text(
              analysis.targetWord,
              style: TextStyle(
                color: _borderColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
