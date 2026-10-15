import 'dart:ui';

import 'package:flutter/material.dart';

import '../game/hud_state.dart';
import '../game/palette.dart';
import 'type.dart';

/// Round result, with an immediate way to play again.
class GameOverPanel extends StatelessWidget {
  const GameOverPanel({super.key, required this.hud, required this.onPlayAgain});

  final HudState hud;
  final VoidCallback onPlayAgain;

  @override
  Widget build(BuildContext context) {
    final isBest = hud.score > 0 && hud.score >= hud.best;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 20 * (1 - t)), child: child),
      ),
      child: ColoredBox(
        color: const Color(0x99040614),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                width: 300,
                padding: const EdgeInsets.fromLTRB(26, 28, 26, 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Palette.panelTop, Palette.panelBottom],
                  ),
                  border: Border.all(color: Palette.panelBorder),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('ROUND OVER', style: PopType.of(12, 700, color: Palette.textDim, spacing: 2.4)),
                    const SizedBox(height: 12),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: hud.score.toDouble()),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => Text('${v.round()}', style: PopType.panelScore),
                    ),
                    const SizedBox(height: 8),
                    if (isBest)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Palette.gold.withValues(alpha: 0.15),
                          border: Border.all(color: Palette.gold.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.emoji_events_rounded, size: 15, color: Palette.gold),
                            const SizedBox(width: 6),
                            Text('New best', style: PopType.of(13, 700, color: Palette.gold)),
                          ],
                        ),
                      )
                    else
                      Text('Best ${hud.best}', style: PopType.of(14, 500, color: Palette.textDim)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _Stat(label: 'BEST CHAIN', value: hud.longestChain > 1 ? '×${hud.longestChain}' : '—')),
                        Container(width: 1, height: 30, color: Palette.panelBorder),
                        Expanded(child: _Stat(label: 'MOVES', value: '${hud.moves}')),
                      ],
                    ),
                    const SizedBox(height: 22),
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

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(label, style: PopType.label),
          const SizedBox(height: 4),
          Text(value, style: PopType.of(18, 700, numbers: true)),
        ],
      );
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(colors: [Palette.orbs[1], Palette.orbs[0]]),
          boxShadow: [
            BoxShadow(color: Palette.orbs[0].withValues(alpha: 0.45), blurRadius: 22, offset: const Offset(0, 8)),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            autofocus: true,
            borderRadius: BorderRadius.circular(28),
            onTap: onPressed,
            child: Stack(
              children: [
                // Gloss on the upper half of the button.
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: 26,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.white.withValues(alpha: 0.35), Colors.white.withValues(alpha: 0.0)],
                      ),
                    ),
                  ),
                ),
                Center(child: Text(label, style: PopType.button)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
