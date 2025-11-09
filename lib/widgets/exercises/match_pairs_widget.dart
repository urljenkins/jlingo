import 'package:flutter/material.dart';
import 'dart:convert';
import '../../models/exercise.dart';

class MatchPairsWidget extends StatefulWidget {
  final Exercise exercise;
  final Function(bool) onAnswer;

  const MatchPairsWidget({
    super.key,
    required this.exercise,
    required this.onAnswer,
  });

  @override
  State<MatchPairsWidget> createState() => _MatchPairsWidgetState();
}

class _MatchPairsWidgetState extends State<MatchPairsWidget> {
  final List<String> _selectedTiles = [];
  final Map<String, String> _matchedPairs = {};
  late List<MatchPair> _pairs;
  late List<String> _allTiles;

  @override
  void initState() {
    super.initState();
    _initializePairs();
  }

  void _initializePairs() {
    // Parse pairs from metadata
    final pairsData = widget.exercise.metadata?['pairs'] as List<dynamic>? ?? [];
    _pairs = pairsData.map((p) => MatchPair.fromJson(p as Map<String, dynamic>)).toList();

    // Create shuffled list of all tiles
    _allTiles = [];
    for (final pair in _pairs) {
      _allTiles.add('target:${pair.target}');
      _allTiles.add('native:${pair.native}');
    }
    _allTiles.shuffle();
  }

  void _onTileTap(String tile) {
    if (_matchedPairs.containsKey(tile)) return;
    if (_selectedTiles.contains(tile)) {
      setState(() => _selectedTiles.remove(tile));
      return;
    }

    setState(() {
      _selectedTiles.add(tile);

      if (_selectedTiles.length == 2) {
        _checkMatch();
      }
    });
  }

  void _checkMatch() {
    final tile1 = _selectedTiles[0];
    final tile2 = _selectedTiles[1];

    final parts1 = tile1.split(':');
    final parts2 = tile2.split(':');

    final type1 = parts1[0];
    final value1 = parts1[1];
    final type2 = parts2[0];
    final value2 = parts2[1];

    // Check if they're different types and form a valid pair
    if (type1 != type2) {
      final isMatch = _pairs.any((pair) =>
          (pair.target == value1 && pair.native == value2) ||
          (pair.target == value2 && pair.native == value1));

      if (isMatch) {
        setState(() {
          _matchedPairs[tile1] = tile2;
          _matchedPairs[tile2] = tile1;
          _selectedTiles.clear();

          // Check if all pairs are matched
          if (_matchedPairs.length == _allTiles.length) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) widget.onAnswer(true);
            });
          }
        });
      } else {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() => _selectedTiles.clear());
          }
        });
      }
    } else {
      setState(() => _selectedTiles.clear());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Match the pairs',
            style: TextStyle(fontSize: 14, color: Colors.white60),
          ),
          const SizedBox(height: 16),
          Text(
            widget.exercise.question,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2,
              ),
              itemCount: _allTiles.length,
              itemBuilder: (context, index) => _buildTile(_allTiles[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(String tile) {
    final isSelected = _selectedTiles.contains(tile);
    final isMatched = _matchedPairs.containsKey(tile);
    final value = tile.split(':')[1];

    Color backgroundColor = const Color(0xFF2A2A2A);
    Color borderColor = Colors.transparent;

    if (isMatched) {
      backgroundColor = const Color(0xFF00FF85).withOpacity(0.2);
      borderColor = const Color(0xFF00FF85);
    } else if (isSelected) {
      backgroundColor = const Color(0xFF00D9FF).withOpacity(0.2);
      borderColor = const Color(0xFF00D9FF);
    }

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => _onTileTap(tile),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Center(
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
