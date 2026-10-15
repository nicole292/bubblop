import 'dart:ui';

import 'package:flutter/material.dart';

import '../game/palette.dart';
import 'type.dart';

/// Round result, with an immediate way to play again.
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
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 16 * (1 - t)), child: child),
      ),
      child: ColoredBox(
        color: const Color(0x8C060918),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                width: 290,
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
                decoration: BoxDecoration(
                  color: Palette.panel,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Palette.panelBorder),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Round over', style: PopType.panelTitle),
                    const SizedBox(height: 10),
                    Text('$score', style: PopType.panelScore),
                    const SizedBox(height: 8),
                    Text(
                      isBest ? 'New best!' : 'Best $best',
                      style: PopType.of(14, isBest ? 700 : 500,
                          color: isBest ? Palette.orbs[1] : Palette.textDim),
                    ),
                    const SizedBox(height: 24),
                    _PrimaryButton(label: 'Play again', onPressed: onPlayAgain),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(27),
          gradient: LinearGradient(colors: [Palette.orbs[1], Palette.orbs[0]]),
          boxShadow: [
            BoxShadow(color: Palette.orbs[0].withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 6)),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            autofocus: true,
            borderRadius: BorderRadius.circular(27),
            onTap: onPressed,
            child: Center(child: Text(label, style: PopType.button)),
          ),
        ),
      ),
    );
  }
}
