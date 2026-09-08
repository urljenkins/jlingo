import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../models/exercise.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// "Select the correct image": a word is shown or spoken, and the learner
/// picks the picture it names.
///
/// Pictures degrade in three steps, because the course has no artwork on disk
/// yet and this should not block the exercise type existing:
///
///  1. a real image, when the author supplied an `imageUrl`;
///  2. an emoji glyph, when one is given for the option;
///  3. a labelled wireframe placeholder otherwise.
///
/// Every tier keeps the option's word visible underneath, so the exercise is
/// answerable — and therefore testable — at any tier.
class SelectImageWidget extends StatefulWidget {
  const SelectImageWidget({
    super.key,
    required this.exercise,
    required this.onAnswer,
  });

  final Exercise exercise;
  final void Function(bool) onAnswer;

  @override
  State<SelectImageWidget> createState() => _SelectImageWidgetState();
}

class _SelectImageWidgetState extends State<SelectImageWidget> {
  final _tts = FlutterTts();
  String? _selected;
  bool _showFeedback = false;

  /// Per-option artwork, keyed by the option text.
  ///
  /// `images` holds asset paths or URLs; `emoji` holds a single glyph. Both
  /// are optional, and an option missing from both falls back to a wireframe.
  Map<String, String> get _images =>
      _mapFrom(widget.exercise.metadata?['images']);
  Map<String, String> get _emoji =>
      _mapFrom(widget.exercise.metadata?['emoji']);

  static Map<String, String> _mapFrom(dynamic raw) {
    if (raw is! Map) return const {};
    return {
      for (final entry in raw.entries)
        entry.key.toString(): entry.value.toString(),
    };
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _play() async {
    await _tts.setLanguage(widget.exercise.targetLanguage ?? 'es-ES');
    await _tts.setSpeechRate(0.5);
    await _tts.speak(widget.exercise.question);
  }

  void _select(String option) {
    if (_showFeedback) return;
    setState(() {
      _selected = option;
      _showFeedback = true;
    });

    final isCorrect = option == widget.exercise.correctAnswer;
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) widget.onAnswer(isCorrect);
    });
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
          const Text(
            'Select the correct image',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                onPressed: _play,
                icon: const Icon(Icons.volume_up),
                color: AppColors.textPrimary,
                tooltip: 'Play',
              ),
              const SizedBox(width: 4),
              Text(
                widget.exercise.question,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: widget.exercise.options.length,
              itemBuilder: (context, index) =>
                  _buildOption(widget.exercise.options[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(String option) {
    final isAnswer = option == widget.exercise.correctAnswer;
    final isSelected = option == _selected;

    Color background = AppColors.surfaceRaised;
    Color border = AppColors.border;

    if (_showFeedback) {
      // Always reveal the right picture, not just mark the wrong choice —
      // a missed word teaches nothing if the answer stays hidden.
      if (isAnswer) {
        background = AppColors.correct.withValues(alpha: 0.18);
        border = AppColors.correct;
      } else if (isSelected) {
        background = AppColors.incorrect.withValues(alpha: 0.18);
        border = AppColors.incorrect;
      }
    }

    return GestureDetector(
      onTap: () => _select(option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 1.5),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(child: Center(child: _buildArtwork(option))),
            const SizedBox(height: 8),
            Text(
              option,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtwork(String option) {
    final image = _images[option];
    if (image != null && image.isNotEmpty) {
      return Image.asset(
        image,
        fit: BoxFit.contain,
        // A missing asset must not blank the exercise — fall through to the
        // placeholder rather than throwing in the grid.
        errorBuilder: (_, __, ___) => _buildPlaceholder(option),
      );
    }

    final glyph = _emoji[option];
    if (glyph != null && glyph.isNotEmpty) {
      return Text(glyph, style: const TextStyle(fontSize: 56));
    }

    return _buildPlaceholder(option);
  }

  /// The wireframe tier: an explicit "no artwork yet" frame rather than an
  /// empty box, so a content gap is visible to whoever is authoring.
  Widget _buildPlaceholder(String option) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide.clamp(32.0, 72.0);
        return DottedFrame(size: size);
      },
    );
  }
}

/// A dashed square standing in for artwork that does not exist yet.
class DottedFrame extends StatelessWidget {
  const DottedFrame({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _DashedBoxPainter()),
    );
  }
}

class _DashedBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textDisabled
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dash = 5.0;
    const gap = 4.0;
    final rect = Offset.zero & size;

    for (var x = rect.left; x < rect.right; x += dash + gap) {
      final end = (x + dash).clamp(rect.left, rect.right);
      canvas
        ..drawLine(Offset(x, rect.top), Offset(end, rect.top), paint)
        ..drawLine(Offset(x, rect.bottom), Offset(end, rect.bottom), paint);
    }
    for (var y = rect.top; y < rect.bottom; y += dash + gap) {
      final end = (y + dash).clamp(rect.top, rect.bottom);
      canvas
        ..drawLine(Offset(rect.left, y), Offset(rect.left, end), paint)
        ..drawLine(Offset(rect.right, y), Offset(rect.right, end), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
