import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/animation.dart' show Curves;
import 'package:pop_core/pop_core.dart';

import '../render/orb_sprites.dart';
import 'timings.dart';
import 'visual_orb.dart';

final _crackDark = Paint()
  ..style = PaintingStyle.stroke
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;
final _crackLight = Paint()
  ..style = PaintingStyle.stroke
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

/// Draws one on-screen ball from the baked sprites, applying its animation
/// state (squash, pre-pop glow, cracks, shell reveal, pop, reveal bounce).
void paintOrb(Canvas canvas, OrbSprites sprites, Offset center, VisualOrb orb) {
  if (orb.alpha <= 0 || orb.scale <= 0) return;
  final s = orb.squash / Timings.squash;
  final flash = orb.flash / Timings.revealFlash;
  // A freed ball boings: overshoots, then settles.
  final boing = flash > 0 ? 1 + 0.16 * math.sin(math.pi * (1 - flash)) * flash.clamp(0.0, 1.0) : 1.0;
  final sx = orb.scale * boing * (1 + 0.12 * s);
  final sy = orb.scale * boing * (1 - 0.12 * s);
  // Squash keeps the ball resting on its bottom edge; scaling stays centred.
  final c = center.translate(0, sprites.radius * orb.scale * 0.12 * s);
  final color = orb.cell.color;

  switch (orb.cell.kind) {
    case CellKind.stone:
      sprites.draw(canvas, sprites.stone, c, sx: sx, sy: sy, alpha: orb.alpha);
    case CellKind.shell:
      final t = orb.reveal;
      if (t < 1) {
        // The bubble swells and fades as it pops.
        final k = 1 + 0.25 * t;
        sprites.draw(canvas, sprites.shell(color), c, sx: sx * k, sy: sy * k, alpha: orb.alpha * (1 - t));
        if (orb.crack > 0) _paintCracks(canvas, c, sprites.radius * sx, orb, 1 - t);
      }
      if (t > 0) {
        final k = 0.9 + 0.1 * Curves.easeOutBack.transform(t);
        sprites.draw(canvas, sprites.ball(color), c, sx: sx * k, sy: sy * k, alpha: orb.alpha * t);
      }
    case CellKind.orb:
      final g = math.max(orb.glow, flash);
      if (g > 0) {
        final k = 1.0 + 0.15 * g;
        sprites.draw(canvas, sprites.halo(color), c, sx: sx * k, sy: sy * k, alpha: orb.alpha * g * 0.55);
      }
      sprites.draw(canvas, sprites.ball(color), c, sx: sx, sy: sy, alpha: orb.alpha);
  }
}

/// The soft shadow under a ball; drawn in a pass before all balls.
void paintOrbShadow(Canvas canvas, OrbSprites sprites, Offset center, VisualOrb orb) {
  if (orb.alpha <= 0 || orb.scale <= 0) return;
  sprites.draw(canvas, sprites.shadow, center, sx: orb.scale, sy: orb.scale, alpha: orb.alpha);
}

/// Jagged cracks spreading over the bubble from the side that was hit. The
/// pattern is fixed per ball (seeded) and grows with [VisualOrb.crack].
void _paintCracks(Canvas canvas, Offset c, double r, VisualOrb orb, double alpha) {
  final progress = Curves.easeOut.transform(orb.crack);
  var seed = orb.seed * 9301 + 49297;
  double rand() {
    seed = (seed * 9301 + 49297) % 233280;
    return seed / 233280;
  }

  final start = c + Offset(math.cos(orb.crackAngle), math.sin(orb.crackAngle)) * r * 0.9;
  final path = Path();
  for (var branch = 0; branch < 3; branch++) {
    var dir = orb.crackAngle + math.pi + (rand() - 0.5) * 1.8;
    var p = start;
    path.moveTo(p.dx, p.dy);
    final steps = 3 + (rand() * 2).floor();
    final length = r * (0.8 + rand() * 0.8) * progress;
    for (var i = 0; i < steps; i++) {
      dir += (rand() - 0.5) * 1.2;
      p += Offset(math.cos(dir), math.sin(dir)) * (length / steps);
      if ((p - c).distance > r * 0.95) break;
      path.lineTo(p.dx, p.dy);
    }
  }
  _crackLight
    ..strokeWidth = math.max(2.0, r * 0.11)
    ..color = Color.fromRGBO(255, 255, 255, 0.9 * alpha);
  canvas.drawPath(path, _crackLight);
  _crackDark
    ..strokeWidth = math.max(1.2, r * 0.05)
    ..color = Color.fromRGBO(72, 78, 140, 0.9 * alpha);
  canvas.drawPath(path, _crackDark);
}
