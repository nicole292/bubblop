import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pop_core/pop_core.dart' show GoalKind;

import '../game/hud_state.dart';
import '../game/palette.dart';
import '../render/orb_sprites.dart';
import 'bomb_icon.dart';
import 'goal_icon.dart';
import 'orb_icon.dart';
import 'type.dart';

/// The header at the top of the board card: pause (quiet, on the left),
/// score with best score, level and best level under it, and the next
/// balls on the right.
/// Laid out at [designHeight] and scaled to fit the header, so it keeps its
/// proportions on every screen.
class HudBar extends StatelessWidget {
  const HudBar({
    super.key,
    required this.hud,
    required this.sprites,
    required this.onPause,
    this.onBomb,
    this.showNext = true,
  });

  final HudState hud;
  final OrbSprites? sprites;
  final VoidCallback onPause;

  /// Arms (or disarms) a bomb for the next drop. Null hides the button.
  final VoidCallback? onBomb;

  /// The next balls usually float just above the stack instead; they come
  /// up here only when the stack is too tall to leave them room.
  final bool showNext;

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
                  if (hud.isLevel) ...[
                    // A level: the score and the level; the missions have
                    // their own bar under the header (MissionBar).
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: _Score(
                              value: hud.score,
                              gain: hud.gain,
                              gainId: hud.gainId,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'LEVEL ${hud.levelNumber}',
                            style: PopType.of(
                              13,
                              1000,
                              color: Palette.accent,
                              spacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Score(
                            value: hud.score,
                            gain: hud.gain,
                            gainId: hud.gainId,
                          ),
                          _SubLine(
                            best: hud.best,
                            level: hud.level,
                            bestLevel: hud.bestLevel,
                          ),
                        ],
                      ),
                    ),
                  if (onBomb != null) ...[
                    // Room for the ready bomb's glow and badge.
                    const SizedBox(width: 12),
                    _BombButton(
                      charge: hud.bombCharge,
                      armed: hud.bombArmed,
                      onPressed: onBomb!,
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (showNext) NextBalls(sprites: sprites, queue: hud.queue),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

//// The bomb: a ring fills as balls pop. Once full it can't be missed:
/// golden rays spin behind it, its fuse sparkles, it hops, and a "READY!"
/// badge sits under it. Tap it, then a column, to drop it (tap again to put
/// it back). It starts filling again after every bomb.
class _BombButton extends StatefulWidget {
  const _BombButton({
    required this.charge,
    required this.armed,
    required this.onPressed,
  });
  final double charge;
  final bool armed;
  final VoidCallback onPressed;

  @override
  State<_BombButton> createState() => _BombButtonState();
}

class _BombButtonState extends State<_BombButton>
    with TickerProviderStateMixin {
  /// Runs while the bomb is ready: drives the hop, rays and fuse spark.
  late final _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  /// A one-off pop the moment the bomb becomes ready.
  late final _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  bool get _ready => widget.charge >= 1;

  @override
  void initState() {
    super.initState();
    if (_ready) _loop.repeat();
  }

  @override
  void didUpdateWidget(_BombButton old) {
    super.didUpdateWidget(old);
    if (_ready && !_loop.isAnimating) {
      _loop.repeat();
      if (old.charge < 1) _burst.forward(from: 0);
    }
    if (!_ready && _loop.isAnimating) _loop.reset();
  }

  @override
  void dispose() {
    _loop.dispose();
    _burst.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const fire = Color(0xFFFF8A1A);
    final lit = _ready || widget.armed;
    return Tooltip(
      message: widget.armed
          ? 'Bomb ready: tap a column'
          : _ready
          ? 'Use the bomb'
          : 'Pop balls to charge the bomb',
      child: GestureDetector(
        onTap: widget.onPressed,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 52,
          height: 52,
          child: AnimatedBuilder(
            animation: Listenable.merge([_loop, _burst]),
            builder: (context, _) {
              final t = _loop.value;
              // Two quick hops in the first half of each loop, then a rest.
              final hop = _ready && !widget.armed && t < 0.5
                  ? math.max(0.0, math.sin(t * math.pi * 4))
                  : 0.0;
              final burst = _burst.isAnimating
                  ? Curves.easeOut.transform(_burst.value)
                  : null;
              final pop = burst == null
                  ? 1.0
                  : 1 + 0.35 * math.sin(burst * math.pi);
              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  if (lit)
                    Positioned(
                      left: -18,
                      top: -18,
                      right: -18,
                      bottom: -18,
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _RaysPainter(spin: t, burst: burst),
                        ),
                      ),
                    ),
                  Transform.translate(
                    offset: Offset(0, -4 * hop),
                    child: Transform.scale(
                      scale: pop * (lit ? 1.06 : 1),
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: lit
                                  ? const RadialGradient(
                                      colors: [
                                        Color(0xFFFFF3C4),
                                        Color(0xFFFFC85C),
                                      ],
                                    )
                                  : null,
                              color: lit ? null : Palette.well,
                              boxShadow: lit
                                  ? [
                                      BoxShadow(
                                        color: fire.withValues(
                                          alpha:
                                              0.55 +
                                              0.25 * math.sin(t * math.pi * 4),
                                        ),
                                        blurRadius: 16,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          // The charge ring, filling clockwise from the top.
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(end: widget.charge.clamp(0.0, 1.0)),
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOut,
                              builder: (context, value, _) =>
                                  CircularProgressIndicator(
                                    value: value,
                                    strokeWidth: 4,
                                    strokeCap: StrokeCap.round,
                                    color: lit ? const Color(0xFFFF6A00) : fire,
                                    backgroundColor: Palette.pipEmpty,
                                  ),
                            ),
                          ),
                          Opacity(
                            opacity: lit ? 1 : 0.45,
                            child: BombIcon(size: lit ? 32 : 28),
                          ),
                          // The fuse sparks.
                          if (lit)
                            Positioned(
                              right: 6,
                              top: 2,
                              child: IgnorePointer(
                                child: CustomPaint(
                                  size: const Size(14, 14),
                                  painter: _SparkPainter(t),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (lit)
                    Positioned(
                      bottom: -12,
                      child: IgnorePointer(
                        child: Transform.scale(
                          scale: 1 + 0.08 * math.sin(t * math.pi * 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF9A2E), Color(0xFFFF4F6D)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x55FF4F6D),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              widget.armed ? 'AIM!' : 'READY!',
                              style: PopType.of(
                                9,
                                1000,
                                color: Colors.white,
                                spacing: 0.6,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Soft golden rays turning slowly behind a ready bomb; [burst] (0–1)
/// throws a ring out the moment it becomes ready.
class _RaysPainter extends CustomPainter {
  _RaysPainter({required this.spin, this.burst});
  final double spin;
  final double? burst;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final paint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0x99FFD54A), Color(0x00FFD54A)],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(spin * math.pi * 2 / 3);
    const rays = 10;
    for (var i = 0; i < rays; i++) {
      final a = i * math.pi * 2 / rays;
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(math.cos(a - 0.13) * r, math.sin(a - 0.13) * r)
        ..lineTo(math.cos(a + 0.13) * r, math.sin(a + 0.13) * r)
        ..close();
      canvas.drawPath(path, paint);
    }
    canvas.restore();
    final b = burst;
    if (b != null) {
      canvas.drawCircle(
        c,
        r * (0.5 + 0.6 * b),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5 * (1 - b)
          ..color = const Color(0xFFFFB020).withValues(alpha: 1 - b),
      );
    }
  }

  @override
  bool shouldRepaint(_RaysPainter old) =>
      old.spin != spin || old.burst != burst;
}

/// A flickering spark on the bomb's fuse.
class _SparkPainter extends CustomPainter {
  _SparkPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final flicker = 0.75 + 0.25 * math.sin(t * math.pi * 26);
    canvas.drawCircle(
      c,
      5.5 * flicker,
      Paint()..color = const Color(0x88FFD54A),
    );
    final star = Path();
    for (var i = 0; i < 8; i++) {
      final a = t * math.pi * 6 + i * math.pi / 4;
      final rr = (i.isEven ? 6.5 : 2.2) * flicker;
      final p = c + Offset(math.cos(a), math.sin(a)) * rr;
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(star..close(), Paint()..color = const Color(0xFFFFF4B0));
    canvas.drawCircle(c, 1.8, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.t != t;
}

// Quiet round button: easy to hit (44 px), but it doesn't draw the eye.
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
          child: SizedBox(
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
  late final _bump = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

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
                final s = _bump.isAnimating && t < 0.3
                    ? 1 + 0.1 * math.sin(math.pi * t / 0.3)
                    : 1.0;
                return Transform.scale(
                  scale: s,
                  alignment: Alignment.centerLeft,
                  child: child,
                );
              },
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: widget.value.toDouble()),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) =>
                    Text('${v.round()}', style: PopType.score),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        AnimatedBuilder(
          animation: _bump,
          builder: (context, _) {
            final t = _bump.value;
            if (!_bump.isAnimating || t <= 0 || t >= 1 || widget.gain <= 0) {
              return const SizedBox.shrink();
            }
            final appear = Curves.easeOutBack.transform(
              (t / 0.2).clamp(0.0, 1.0),
            );
            final fade = t < 0.7 ? 1.0 : 1 - (t - 0.7) / 0.3;
            return Opacity(
              opacity: fade,
              child: Transform.translate(
                offset: Offset(0, -6 * t),
                child: Transform.scale(
                  scale: 0.6 + 0.4 * appear,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Palette.gold,
                      borderRadius: BorderRadius.circular(10),
                    ),
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
  const _SubLine({
    required this.best,
    required this.level,
    required this.bestLevel,
  });
  final int best;
  final int level;
  final int bestLevel;

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 3,
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Palette.pipEmpty,
        shape: BoxShape.circle,
      ),
    );
    // Shrinks rather than overflowing on narrow headers.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events_rounded, size: 14, color: Palette.gold),
          const SizedBox(width: 3),
          Text('$best', style: PopType.small),
          dot,
          Text('LEVEL $level', style: PopType.level),
          // Once this round passes the best level, the current level is the best.
          if (bestLevel > level) ...[
            dot,
            Text(
              'BEST LV $bestLevel',
              style: PopType.of(11, 900, color: Palette.inkSoft, spacing: 1.1),
            ),
          ],
        ],
      ),
    );
  }
}

///// A level's missions, in their own bar under the header: each one in
/// words ("Pop 23/110") with a thin bar that fills as you go, turning green
/// with a tick when it is done; then the drops left on a level with a drop
/// limit (red near the end). Tapping it shows the missions in full.
/// Laid out at [designHeight] and scaled to fit, like the header.
class MissionBar extends StatelessWidget {
  const MissionBar({super.key, required this.goals, this.dropsLeft});
  final List<GoalView> goals;
  final int? dropsLeft;

  static const designHeight = 40.0;

  @override
  Widget build(BuildContext context) {
    final full = [
      for (final g in goals) '${g.met ? '✓' : '•'} ${g.goal.text}',
      if (dropsLeft != null) '• $dropsLeft drops left',
    ].join('\n');
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = (constraints.maxHeight / designHeight).clamp(0.5, 1.25);
        return Tooltip(
          message: full,
          triggerMode: TooltipTriggerMode.tap,
          showDuration: const Duration(seconds: 3),
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: constraints.maxWidth / scale,
              height: designHeight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Palette.well,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      for (final (i, g) in goals.indexed) ...[
                        if (i > 0) _divider(),
                        Expanded(child: _Mission(goal: g)),
                      ],
                      if (dropsLeft case final drops?) ...[
                        _divider(),
                        _Drops(drops: drops),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _divider() => Container(
    width: 1.5,
    height: 20,
    margin: const EdgeInsets.symmetric(horizontal: 8),
    color: Palette.pipEmpty,
  );
}

/// The word for a mission in the bar.
String _missionWord(GoalKind kind) => switch (kind) {
  GoalKind.score => 'Points',
  GoalKind.pop => 'Pop',
  GoalKind.chain => 'Chain',
  GoalKind.crack => 'Shells',
  GoalKind.blast => 'Bombs',
};

/// The colour of a mission's bar while it is still going.
Color _missionTint(GoalKind kind) => switch (kind) {
  GoalKind.score => Palette.gold,
  // Any colour counts, so not a ball colour.
  GoalKind.pop => const Color(0xFFFF5C8A),
  GoalKind.chain => Palette.accent,
  GoalKind.crack => const Color(0xFF8A93C8),
  GoalKind.blast => const Color(0xFFFF8A1A),
};

class _Mission extends StatelessWidget {
  const _Mission({required this.goal});
  final GoalView goal;

  @override
  Widget build(BuildContext context) {
    final g = goal;
    final fraction = g.goal.target <= 0
        ? 1.0
        : (g.progress / g.goal.target).clamp(0.0, 1.0);
    final tint = g.met ? Palette.success : _missionTint(g.goal.kind);
    // A big round badge with the mission's icon, then its word and count
    // over a bar that fills as you go.
    return Row(
      children: [
        GoalBadge(kind: g.goal.kind, size: 28, done: g.met),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _missionWord(g.goal.kind),
                      style: PopType.of(12, 900, color: Palette.inkSoft),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      g.met ? 'Done!' : goalCount(g.goal, g.progress),
                      style: PopType.of(
                        13,
                        1000,
                        color: g.met ? Palette.success : Palette.ink,
                        numbers: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: SizedBox(
                  height: 4,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ColoredBox(color: Palette.pipEmpty),
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween(end: fraction),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        builder: (context, v, _) => FractionallySizedBox(
                          widthFactor: v,
                          heightFactor: 1,
                          child: ColoredBox(color: tint),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Drops extends StatelessWidget {
  const _Drops({required this.drops});
  final int drops;

  @override
  Widget build(BuildContext context) {
    final low = drops <= 5;
    final color = low ? Palette.danger : Palette.inkSoft;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.water_drop_rounded, size: 15, color: color),
        const SizedBox(width: 3),
        Text(
          '$drops',
          style: PopType.of(
            14,
            1000,
            color: low ? Palette.danger : Palette.ink,
            numbers: true,
          ),
        ),
        const SizedBox(width: 3),
        Text('left', style: PopType.of(12, 900, color: color)),
      ],
    );
  }
}

// The ball you are about to drop, big in a white ring so it is easy to
/// see at a glance, then the two after it, smaller and lighter.
class NextBalls extends StatelessWidget {
  const NextBalls({
    super.key,
    required this.sprites,
    required this.queue,
    this.floating = false,
  });
  final OrbSprites? sprites;
  final List<int> queue;

  /// Floating over the board: white, with a soft shadow, so it stands out.
  final bool floating;

  static const height = 56.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
      decoration: BoxDecoration(
        color: floating ? Palette.card.withValues(alpha: 0.92) : Palette.well,
        borderRadius: BorderRadius.circular(28),
        boxShadow: floating
            ? [
                BoxShadow(
                  color: Palette.panelShadow,
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: floating ? Palette.well : Palette.card,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Palette.panelShadow,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: queue.isEmpty
                ? null
                : _Ball(sprites: sprites, color: queue[0], size: 40),
          ),
          for (var i = 1; i < queue.length; i++) ...[
            SizedBox(width: i == 1 ? 10 : 6),
            Opacity(
              opacity: i == 1 ? 1 : 0.65,
              child: _Ball(
                sprites: sprites,
                color: queue[i],
                size: i == 1 ? 26 : 21,
              ),
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
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: OrbIcon(
          key: ValueKey('$color-$size'),
          sprites: sprites,
          color: color,
          size: size,
        ),
      ),
    );
  }
}
