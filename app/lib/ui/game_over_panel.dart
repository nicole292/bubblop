import 'package:flutter/material.dart';

import '../game/hud_state.dart';
import '../game/palette.dart';
import 'buttons.dart';
import 'type.dart';

/// Round result on a white card that bounces in, with a big Play again.
class GameOverPanel extends StatelessWidget {
  const GameOverPanel({super.key, required this.hud, required this.onPlayAgain, required this.onHome});

  final HudState hud;
  final VoidCallback onPlayAgain;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final isBest = hud.newBest;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      builder: (context, t, child) => ColoredBox(
        color: Palette.ink.withValues(alpha: 0.35 * t.clamp(0.0, 1.0)),
        child: Center(
          child: Transform.scale(
            scale: Curves.easeOutBack.transform(t),
            child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
          ),
        ),
      ),
      child: Container(
        width: 300,
        padding: const EdgeInsets.fromLTRB(26, 26, 26, 24),
        decoration: BoxDecoration(
          color: Palette.card,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [BoxShadow(color: Color(0x663A2D9E), blurRadius: 30, offset: Offset(0, 12))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ROUND OVER', style: PopType.panelTitle),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: hud.score.toDouble()),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => Text('${v.round()}', style: PopType.panelScore),
            ),
            const SizedBox(height: 8),
            if (isBest)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: Palette.gold, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events_rounded, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text('New best!', style: PopType.of(14, 900, color: Colors.white)),
                  ],
                ),
              )
            else
              Text('Best ${hud.best}', style: PopType.of(15, 800, color: Palette.inkSoft)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: Palette.well, borderRadius: BorderRadius.circular(18)),
              child: Row(
                children: [
                  Expanded(
                      child: _Stat(label: 'BEST CHAIN', value: hud.longestChain > 1 ? '×${hud.longestChain}' : '—')),
                  Container(width: 1.5, height: 30, color: Palette.laneAlt),
                  Expanded(child: _Stat(label: 'MOVES', value: '${hud.moves}')),
                ],
              ),
            ),
            const SizedBox(height: 22),
            BigButton(label: 'Play again', icon: Icons.replay_rounded, onPressed: onPlayAgain),
            const SizedBox(height: 10),
            SoftButton(label: 'Home', icon: Icons.home_rounded, onPressed: onHome),
          ],
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
          Text(value, style: PopType.of(20, 900, numbers: true)),
        ],
      );
}
