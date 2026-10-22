import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/hud_state.dart';
import '../game/palette.dart';
import '../render/orb_sprites.dart';
import 'orb_icon.dart';
import 'type.dart';

/// The header at the top of the board card: pause (quiet, on the left),
/// score with best and level under it, and the next balls on the right.
/// Laid out at [designHeight] and scaled to fit the header, so it keeps its
/// proportions on every screen.
class HudBar extends StatelessWidget {
  const HudBar({super.key, required this.hud, required this.sprites, required this.onPause});

  final HudState hud;
  final OrbSprites? sprites;
  final VoidCallback onPause;

  static const designHeight = 76.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = (constraints.maxHeight / designHeight).clamp(0.5, 1.25);
        return FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: constraints.maxWidth / scale,
            height: designHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
              child: Row(
                children: [
                  _PauseButton(onPressed: onPause),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Score(value: hud.score, gain: hud.gain, gainId: hud.gainId),
                        _SubLine(best: hud.best, level: hud.level),
                      ],
                    ),
                  ),
                  NextBalls(sprites: sprites, queue: hud.queue),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Quiet round button: easy to hit (44 px), but it doesn't draw the eye.
class _PauseButton extends StatelessWidget {
  const _PauseButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Pause',
      child: Material(
        color: Palette.well,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Icon(Icons.pause_rounded, size: 24, color: Palette.inkSoft),
          ),
        ),
      ),
    );
  }
}

/// The score rolls up to its new value, gives a small bump when points land,
/// and shows the gain beside it for a moment.
class _Score extends StatefulWidget {
  const _Score({required this.value, required this.gain, required this.gainId});
  final int value;
  final int gain;
  final int gainId;

  @override
  State<_Score> createState() => _ScoreState();
}

class _ScoreState extends State<_Score> with SingleTickerProviderStateMixin {
  late final _bump = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void didUpdateWidget(_Score old) {
    super.didUpdateWidget(old);
    if (widget.gainId != old.gainId && widget.gain > 0) _bump.forward(from: 0);
  }

  @override
  void dispose() {
    _bump.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Very long scores shrink to fit rather than overflow the panel.
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AnimatedBuilder(
              animation: _bump,
              builder: (context, child) {
                final t = _bump.value;
                // A quick swell over the first third, then settle.
                final s = _bump.isAnimating && t < 0.3 ? 1 + 0.1 * math.sin(math.pi * t / 0.3) : 1.0;
                return Transform.scale(scale: s, alignment: Alignment.centerLeft, child: child);
              },
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: widget.value.toDouble()),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => Text('${v.round()}', style: PopType.score),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        AnimatedBuilder(
          animation: _bump,
          builder: (context, _) {
            final t = _bump.value;
            if (!_bump.isAnimating || t <= 0 || t >= 1 || widget.gain <= 0) return const SizedBox.shrink();
            final appear = Curves.easeOutBack.transform((t / 0.2).clamp(0.0, 1.0));
            final fade = t < 0.7 ? 1.0 : 1 - (t - 0.7) / 0.3;
            return Opacity(
              opacity: fade,
              child: Transform.translate(
                offset: Offset(0, -6 * t),
                child: Transform.scale(
                  scale: 0.6 + 0.4 * appear,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Palette.gold, borderRadius: BorderRadius.circular(10)),
                    child: Text('+${widget.gain}', style: PopType.gain),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SubLine extends StatelessWidget {
  const _SubLine({required this.best, required this.level});
  final int best;
  final int level;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.emoji_events_rounded, size: 14, color: Palette.gold),
        const SizedBox(width: 3),
        Text('$best', style: PopType.small),
        Container(
          width: 3,
          height: 3,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: const BoxDecoration(color: Palette.pipEmpty, shape: BoxShape.circle),
        ),
        Text('LEVEL $level', style: PopType.level),
      ],
    );
  }
}

/// The ball you are about to drop, big in a white ring so it is easy to
/// see at a glance, then the two after it, smaller and lighter.
class NextBalls extends StatelessWidget {
  const NextBalls({super.key, required this.sprites, required this.queue});
  final OrbSprites? sprites;
  final List<int> queue;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
      decoration: BoxDecoration(color: Palette.well, borderRadius: BorderRadius.circular(28)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Palette.card,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Palette.panelShadow, blurRadius: 6, offset: Offset(0, 2))],
            ),
            child: queue.isEmpty ? null : _Ball(sprites: sprites, color: queue[0], size: 40),
          ),
          for (var i = 1; i < queue.length; i++) ...[
            SizedBox(width: i == 1 ? 10 : 6),
            Opacity(
              opacity: i == 1 ? 1 : 0.65,
              child: _Ball(sprites: sprites, color: queue[i], size: i == 1 ? 26 : 21),
            ),
          ],
        ],
      ),
    );
  }
}

class _Ball extends StatelessWidget {
  const _Ball({required this.sprites, required this.color, required this.size});
  final OrbSprites? sprites;
  final int color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOutBack,
        transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
        child: OrbIcon(key: ValueKey('$color-$size'), sprites: sprites, color: color, size: size),
      ),
    );
  }
}
