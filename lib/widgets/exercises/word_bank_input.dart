import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';

/// Tap-to-assemble answer input: a bank of word tiles, and the answer line
/// they are placed onto.
///
/// This is the input mode most of the app was missing. Every translation and
/// listening exercise here asked the learner to type into a `TextField`,
/// which on a phone is a far harder task than the recall being tested — and
/// it punishes spelling and accents in exercises that are not about spelling.
/// Assembling from tiles keeps the exercise about word order and meaning.
///
/// Shared rather than reimplemented per exercise: translation and
/// listening both need it, and they should not drift apart.
class WordBankInput extends StatefulWidget {
  const WordBankInput({
    super.key,
    required this.correctAnswer,
    required this.onChanged,
    this.distractors = const [],
    this.enabled = true,
  });

  /// The target sentence. Tokenised on whitespace to build the tiles, so the
  /// bank always contains exactly what a correct answer needs.
  final String correctAnswer;

  /// Extra wrong tiles mixed into the bank. Duolingo always shows a few, so
  /// the tile count alone does not give the answer away.
  final List<String> distractors;

  /// Reports the assembled answer as it changes, so the host exercise can
  /// enable its Check button.
  final ValueChanged<String> onChanged;

  final bool enabled;

  /// Splits an answer into the tokens a learner assembles.
  ///
  /// Punctuation stays attached to its word: a tile reading "México." is what
  /// the sentence actually needs, and splitting it off would leave a stray
  /// tile nobody can place.
  static List<String> tokenise(String answer) => answer
      .trim()
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .toList();

  @override
  State<WordBankInput> createState() => _WordBankInputState();
}

/// A tile is identified by position in the bank, not by its text — a sentence
/// can legitimately repeat a word ("de" twice), and matching on text alone
/// would make the two copies indistinguishable.
class _Tile {
  const _Tile(this.index, this.text);

  final int index;
  final String text;
}

class _WordBankInputState extends State<WordBankInput> {
  late List<_Tile> _bank;
  final List<_Tile> _placed = [];

  @override
  void initState() {
    super.initState();
    _buildBank();
  }

  @override
  void didUpdateWidget(WordBankInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.correctAnswer != widget.correctAnswer) {
      setState(() {
        _placed.clear();
        _buildBank();
      });
    }
  }

  void _buildBank() {
    final tokens = [
      ...WordBankInput.tokenise(widget.correctAnswer),
      ...widget.distractors,
    ];
    _bank = [
      for (var i = 0; i < tokens.length; i++) _Tile(i, tokens[i]),
    ]..shuffle();
  }

  String get _answer => _placed.map((t) => t.text).join(' ');

  void _place(_Tile tile) {
    if (!widget.enabled) return;
    HapticFeedback.selectionClick();
    setState(() {
      _bank.removeWhere((t) => t.index == tile.index);
      _placed.add(tile);
    });
    widget.onChanged(_answer);
  }

  void _remove(_Tile tile) {
    if (!widget.enabled) return;
    HapticFeedback.selectionClick();
    setState(() {
      _placed.removeWhere((t) => t.index == tile.index);
      _bank.add(tile);
    });
    widget.onChanged(_answer);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildAnswerArea(),
        const SizedBox(height: 28),
        _buildBankArea(),
      ],
    );
  }

  /// The answer line. Ruled like a writing line even when empty, so the
  /// learner can see where the sentence is going to go.
  Widget _buildAnswerArea() {
    return Container(
      constraints: const BoxConstraints(minHeight: 96),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final tile in _placed)
            _TileChip(
              text: tile.text,
              onTap: () => _remove(tile),
              enabled: widget.enabled,
            ),
        ],
      ),
    );
  }

  Widget _buildBankArea() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tile in _bank)
          _TileChip(
            text: tile.text,
            onTap: () => _place(tile),
            enabled: widget.enabled,
          ),
      ],
    );
  }
}

class _TileChip extends StatelessWidget {
  const _TileChip({
    required this.text,
    required this.onTap,
    required this.enabled,
  });

  final String text;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            color: enabled ? AppColors.textPrimary : AppColors.textDisabled,
          ),
        ),
      ),
    );
  }
}
