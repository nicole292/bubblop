import 'package:flutter/material.dart';

import '../game/hud_state.dart';
import '../game/palette.dart';
import '../render/orb_sprites.dart';
import 'orb_icon.dart';
import 'type.dart';

/// Score, next balls, level and the rising-row countdown on clean white
/// cards. Sizes itself to its content.
class HudBar extends StatelessWidget {
  const HudBar({super.key, required this.hud, required this.sprites, required this.onRestart});

  final HudState hud;
  final OrbSprites? sprites;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: WhiteCard(
                    padding: const EdgeInsets.fromLTRB(16, 10, 14, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text('SCORE', style: PopType.label),
                            const Spacer(),
                            const Icon(Icons.emoji_events_rounded, size: 15, color: Palette.gold),
                            const SizedBox(width: 3),
                            Text('${hud.best}', style: PopType.of(13, 900, color: Palette.gold, numbers: true)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        _CountingScore(value: hud.score),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                WhiteCard(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('NEXT', style: PopType.label),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          for (var i = 0; i < hud.queue.length; i++)
                            Padding(
                              padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
                              child: _Socket(sprites: sprites, color: hud.queue[i], size: i == 0 ? 42 : 28),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _LevelPill(level: hud.level),
              const SizedBox(width: 12),
              Text('RISE', style: PopType.onSky),
              const SizedBox(width: 8),
              _Pips(left: hud.pressure, max: hud.pressureMax),
              const Spacer(),
              _RoundButton(tooltip: 'Restart', onPressed: onRestart),
            ],
          ),
        ],
      ),
    );
  }
}

/// The shared card style: solid white, rounded, with a soft coloured shadow.
class WhiteCard extends StatelessWidget {
  const WhiteCard({super.key, required this.child, this.padding = const EdgeInsets.all(12), this.radius = 20});

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Palette.card,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [BoxShadow(color: Palette.cardShadow, blurRadius: 14, offset: Offset(0, 5))],
      ),
      child: child,
    );
  }
}

/// The score rolls up to its new value instead of jumping.
class _CountingScore extends StatelessWidget {
  const _CountingScore({required this.value});
  final int value;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.toDouble()),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text('${v.round()}', style: PopType.score),
    );
  }
}

/// A soft round socket holding a ball, matching the board's dock.
class _Socket extends StatelessWidget {
  const _Socket({required this.sprites, required this.color, required this.size});
  final OrbSprites? sprites;
  final int color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Palette.socket),
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutBack,
        transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
        child: OrbIcon(key: ValueKey('$color-$size'), sprites: sprites, color: color, size: size * 0.82),
      ),
    );
  }
}

class _LevelPill extends StatelessWidget {
  const _LevelPill({required this.level});
  final int level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Palette.accent,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x403A2D9E), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Text('LEVEL $level', style: PopType.onSky),
    );
  }
}

/// One capsule per drop until the next row rises; filled capsules are drops
/// left. They turn red for the last two.
class _Pips extends StatelessWidget {
  const _Pips({required this.left, required this.max});
  final int left;
  final int max;

  @override
  Widget build(BuildContext context) {
    final urgent = left <= 2;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < max; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutBack,
            width: i < left ? 13 : 9,
            height: 8,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: i < left ? (urgent ? Palette.danger : Colors.white) : const Color(0x59FFFFFF),
            ),
          ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.tooltip, required this.onPressed});
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Palette.card,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: const SizedBox(
            width: 38,
            height: 38,
            child: Icon(Icons.refresh_rounded, size: 22, color: Palette.ink),
          ),
        ),
      ),
    );
  }
}
