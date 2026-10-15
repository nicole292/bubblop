import 'package:flutter/material.dart';

import '../game/palette.dart';

class GameOverPanel extends StatelessWidget {
  const GameOverPanel({
    super.key,
    required this.score,
    required this.best,
    required this.onPlayAgain,
  });

  final int score;
  final int best;
  final VoidCallback onPlayAgain;

  @override
  Widget build(BuildContext context) {
    final isBest = score > 0 && score >= best;
    return ColoredBox(
      color: const Color(0xAA0E1226),
      child: Center(
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Palette.board,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Palette.laneB, width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Round over',
                  style: TextStyle(fontSize: 16, color: Palette.textDim)),
              const SizedBox(height: 8),
              Text('$score',
                  style: const TextStyle(
                      fontSize: 44, fontWeight: FontWeight.w800, color: Palette.text)),
              Text(isBest ? 'New best!' : 'Best $best',
                  style: TextStyle(
                      fontSize: 14,
                      color: isBest ? Palette.orbs[1] : Palette.textDim)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  autofocus: true,
                  onPressed: onPlayAgain,
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Play again', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
