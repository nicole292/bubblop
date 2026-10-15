import 'package:flutter/material.dart';

import '../game/hud_state.dart';
import '../game/palette.dart';
import '../render/orb_sprites.dart';
import 'orb_icon.dart';
import 'type.dart';

/// Score, upcoming orbs, level and the rising-row countdown, in glass panels
/// that match the board. Sizes itself to its content.
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
                  child: GlassPanel(
                    padding: const EdgeInsets.fromLTRB(16, 10, 14, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text('SCORE', style: PopType.label),
                            const Spacer(),
                            const Icon(Icons.emoji_events_rounded, size: 13, color: Palette.gold),
                            const SizedBox(width: 4),
                            Text('${hud.best}', style: PopType.of(12, 600, color: Palette.gold, numbers: true)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        _CountingScore(value: hud.score),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GlassPanel(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('NEXT', style: PopType.label),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
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
          const SizedBox(height: 8),
          Row(
            children: [
              _Chip(label: 'LEVEL ${hud.level}'),
              const SizedBox(width: 12),
              Text('RISE', style: PopType.label),
              const SizedBox(width: 8),
              _Pips(left: hud.pressure, max: hud.pressureMax),
              const Spacer(),
              _RoundButton(icon: Icons.refresh_rounded, tooltip: 'Restart', onPressed: onRestart),
            ],
          ),
        ],
      ),
    );
  }
}

/// A translucent glass panel with a lit top edge, used across the HUD.
class GlassPanel extends StatelessWidget {
  const GlassPanel({super.key, required this.child, this.padding = const EdgeInsets.all(12), this.radius = 18});

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.panelTop, Palette.panelBottom],
        ),
        border: Border.all(color: Palette.panelBorder),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Stack(
        children: [
          // Lit top edge.
          Positioned(
            left: radius * 0.6,
            right: radius * 0.6,
            top: 0,
            height: 1.2,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Color(0x00FFFFFF),
                  Color(0x80DDE3FF),
                  Color(0x00FFFFFF),
                ]),
              ),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

/// White fading to pale lavender, drawn by the text itself (no extra layer).
final _scoreStyle = TextStyle(
  fontFamily: 'Sora',
  fontSize: PopType.score.fontSize,
  fontVariations: PopType.score.fontVariations,
  fontFeatures: PopType.score.fontFeatures,
  height: PopType.score.height,
  foreground: Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFFFFFFF), Color(0xFFC7CFFF)],
    ).createShader(const Rect.fromLTWH(0, 4, 0, 34)),
);

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
      builder: (context, v, _) => Text('${v.round()}', style: _scoreStyle),
    );
  }
}

/// A recessed socket holding a glass orb, matching the board's dock.
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
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: Alignment(0, -0.3),
          colors: [Palette.socketInner, Color(0xFF151C46)],
        ),
        border: Border.fromBorderSide(BorderSide(color: Palette.socketRim)),
      ),
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
        child: OrbIcon(key: ValueKey('$color-$size'), sprites: sprites, color: color, size: size * 0.84),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0x331F2860),
        border: Border.all(color: Palette.panelBorder),
      ),
      child: Text(label, style: PopType.of(10.5, 700, color: Palette.text, spacing: 1.4)),
    );
  }
}

/// One capsule per drop until the next row rises; lit capsules are drops
/// left. They turn red for the last two.
class _Pips extends StatelessWidget {
  const _Pips({required this.left, required this.max});
  final int left;
  final int max;

  @override
  Widget build(BuildContext context) {
    final urgent = left <= 2;
    final lit = urgent ? Palette.danger : const Color(0xFFDDE3FF);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < max; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 11,
            height: 6,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: i < left ? lit : Palette.pipEmpty,
            ),
          ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.tooltip, required this.onPressed});
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        type: MaterialType.transparency,
        child: Ink(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0x331F2860),
            border: Border.all(color: Palette.panelBorder),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Icon(icon, size: 20, color: Palette.textDim),
          ),
        ),
      ),
    );
  }
}
