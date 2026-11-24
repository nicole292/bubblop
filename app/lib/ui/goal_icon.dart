import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pop_core/pop_core.dart';

import '../game/palette.dart';
import 'bomb_icon.dart';

/// One icon per goal type, used on the level card, the mission bar and the
/// results: a star for points, a little cluster of balls in different
/// colours for popping (any colour counts, so the icon is never one colour),
/// linked rings for a chain, a cracked white shell for shells, a bomb for
/// blasting bombs.
class GoalIcon extends StatelessWidget {
  const GoalIcon({super.key, required this.kind, this.size = 20});
  final GoalKind kind;
  final double size;

  @override
  Widget build(BuildContext context) => switch (kind) {
        GoalKind.score => Icon(Icons.star_rounded, size: size, color: Palette.gold),
        GoalKind.pop => CustomPaint(size: Size.square(size), painter: _BallsPainter(Palette.balls)),
        GoalKind.chain => Icon(Icons.link_rounded, size: size, color: Palette.accent),
        GoalKind.crack => CustomPaint(size: Size.square(size), painter: _ShellPainter(Palette.inkSoft)),
        GoalKind.blast => BombIcon(size: size),
      };
}

/// Three balls in three different colours: "pop balls of any colour".
class _BallsPainter extends CustomPainter {
  _BallsPainter(this.colors);
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final r = s * 0.25;
    final spots = [Offset(s * 0.3, s * 0.66), Offset(s * 0.7, s * 0.66), Offset(s * 0.5, s * 0.32)];
    for (final (i, c) in spots.indexed) {
      final color = colors[i % colors.length];
      canvas.drawCircle(c, r + s * 0.04, Paint()..color = Colors.white);
      canvas.drawCircle(c, r, Paint()..color = color);
      canvas.drawCircle(c.translate(-r * 0.35, -r * 0.35), r * 0.28, Paint()..color = const Color(0x99FFFFFF));
    }
  }

  @override
  bool shouldRepaint(_BallsPainter old) => old.colors != colors;
}

/// A white shell bubble with a crack across it.
class _ShellPainter extends CustomPainter {
  _ShellPainter(this.ink);
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = Offset(s / 2, s / 2);
    final r = s * 0.42;
    canvas.drawCircle(c, r, Paint()..color = Colors.white);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, s * 0.09)
        ..color = ink,
    );
    final crack = Path()
      ..moveTo(c.dx - r * 0.75, c.dy - r * 0.25)
      ..lineTo(c.dx - r * 0.2, c.dy + r * 0.15)
      ..lineTo(c.dx + r * 0.05, c.dy - r * 0.35)
      ..lineTo(c.dx + r * 0.4, c.dy + r * 0.2)
      ..lineTo(c.dx + r * 0.78, c.dy - r * 0.05);
    canvas.drawPath(
      crack,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, s * 0.08)
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = ink,
    );
    canvas.drawCircle(c.translate(-r * 0.4, -r * 0.5), r * 0.16, Paint()..color = const Color(0x66B9C3FF));
  }

  @override
  bool shouldRepaint(_ShellPainter old) => old.ink != ink;
}

/// Progress as a short count: "23/40", or "×1/×3" for a chain (a single
/// pop is ×1).
String goalCount(LevelGoal goal, int progress) => switch (goal.kind) {
      GoalKind.chain => '×${math.max(1, progress)}/×${goal.target}',
      _ => '$progress/${goal.target}',
    };

/// A mission's icon on its own round coloured badge, so it reads at a
/// glance even when small: a white star on gold for points, three coloured
/// balls on white for popping, white links on purple for a chain, a cracked
/// shell on grey for shells, a bomb on orange for bombs. A finished mission
/// shows a white tick on green.
class GoalBadge extends StatelessWidget {
  const GoalBadge({super.key, required this.kind, this.size = 26, this.done = false});
  final GoalKind kind;
  final double size;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final (Color fill, Widget icon) = done
        ? (Palette.success, Icon(Icons.check_rounded, size: size * 0.72, color: Colors.white))
        : switch (kind) {
            GoalKind.score => (Palette.gold, Icon(Icons.star_rounded, size: size * 0.74, color: Colors.white)),
            GoalKind.pop => (Colors.white, GoalIcon(kind: kind, size: size * 0.78)),
            GoalKind.chain => (Palette.accent, Icon(Icons.link_rounded, size: size * 0.7, color: Colors.white)),
            GoalKind.crack => (const Color(0xFFE3E7F7), GoalIcon(kind: kind, size: size * 0.74)),
            GoalKind.blast => (const Color(0xFFFFD7A8), BombIcon(size: size * 0.7)),
          };
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(color: Colors.white, width: size * 0.07),
        boxShadow: [BoxShadow(color: fill.withValues(alpha: 0.45), blurRadius: size * 0.2, offset: Offset(0, size * 0.06))],
      ),
      child: icon,
    );
  }
}
