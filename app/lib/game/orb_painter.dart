import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/animation.dart' show Curves;
import 'package:pop_core/pop_core.dart';

import '../render/orb_sprites.dart';
import 'palette.dart';
import 'timings.dart';
import 'visual_orb.dart';

final _additive = [
  for (final c in Palette.orbs)
    Paint()
      ..blendMode = BlendMode.plus
      ..filterQuality = FilterQuality.low
      ..colorFilter = ColorFilter.mode(c, BlendMode.modulate),
];
final _additiveWhite = Paint()
  ..blendMode = BlendMode.plus
  ..filterQuality = FilterQuality.low;
final _crackLight = Paint()
  ..style = PaintingStyle.stroke
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;
final _crackDark = Paint()
  ..style = PaintingStyle.stroke
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

/// Draws one on-screen orb from the baked sprites, applying its animation
/// state (squash, highlight glow, cracks, shell reveal, pop, reveal flash).
void paintOrb(Canvas canvas, OrbSprites sprites, Offset center, VisualOrb orb) {
  if (orb.alpha <= 0 || orb.scale <= 0) return;
  final s = orb.squash / Timings.squash;
  final flash = orb.flash / Timings.revealFlash;
  // A freed core swells briefly, then settles.
  final grow = 1 + 0.12 * math.sin(math.pi * (1 - flash)) * (flash > 0 ? 1 : 0);
  final sx = orb.scale * grow * (1 + 0.10 * s);
  final sy = orb.scale * grow * (1 - 0.10 * s);
  // Squash keeps the orb resting on its bottom edge; scaling stays centred.
  final c = center.translate(0, sprites.radius * orb.scale * 0.10 * s);
  final color = orb.cell.color;

  switch (orb.cell.kind) {
    case CellKind.stone:
      sprites.draw(canvas, sprites.stone, c, sx: sx, sy: sy, alpha: orb.alpha);
    case CellKind.shell:
      final t = orb.reveal;
      if (orb.crack > 0) {
        // Stress light inside the casing as it is about to give.
        sprites.draw(canvas, sprites.halo(color), c,
            sx: 0.9, sy: 0.9, alpha: 0.5 * orb.crack, paint: _additive[color]);
      }
      if (t < 1) {
        final k = 1 + 0.22 * t;
        sprites.draw(canvas, sprites.shell(color), c, sx: sx * k, sy: sy * k, alpha: orb.alpha * (1 - t));
        if (orb.crack > 0) _paintCracks(canvas, c, sprites.radius * sx, orb, 1 - t);
      }
      if (t > 0) {
        final k = 0.62 + 0.38 * Curves.easeOutBack.transform(t);
        sprites.draw(canvas, sprites.orb(color), c, sx: sx * k, sy: sy * k, alpha: orb.alpha * t);
      }
    case CellKind.orb:
      if (orb.glow > 0 || flash > 0) {
        final g = math.max(orb.glow, flash);
        final k = 1.05 + 0.35 * g;
        sprites.draw(canvas, sprites.halo(color), c,
            sx: sx * k, sy: sy * k, alpha: orb.alpha * g * 0.9, paint: _additive[color]);
      }
      sprites.draw(canvas, sprites.orb(color), c, sx: sx, sy: sy, alpha: orb.alpha);
      if (orb.glow > 0) {
        // The orb itself brightens toward white just before it bursts.
        sprites.draw(canvas, sprites.orb(color), c,
            sx: sx, sy: sy, alpha: orb.alpha * orb.glow * 0.45, paint: _additiveWhite);
      }
  }
}

/// The soft shadow under an orb; drawn in a pass before all orbs.
void paintOrbShadow(Canvas canvas, OrbSprites sprites, Offset center, VisualOrb orb) {
  if (orb.alpha <= 0 || orb.scale <= 0) return;
  sprites.draw(canvas, sprites.shadow, center, sx: orb.scale, sy: orb.scale, alpha: orb.alpha * 0.8);
}

/// Coloured light that a glowing orb spills onto the board under it.
void paintFloorLight(Canvas canvas, OrbSprites sprites, Offset center, VisualOrb orb, double strength) {
  if (orb.alpha <= 0 || orb.cell.kind == CellKind.stone) return;
  sprites.draw(canvas, sprites.halo(orb.cell.color), center.translate(0, sprites.radius * 0.35),
      sx: 1.25, sy: 1.0, alpha: strength * orb.alpha, paint: _additive[orb.cell.color]);
}

/// Jagged cracks spreading from the side that was hit. The pattern is fixed
/// per orb (seeded) and grows with [VisualOrb.crack].
void _paintCracks(Canvas canvas, Offset c, double r, VisualOrb orb, double alpha) {
  final progress = Curves.easeOut.transform(orb.crack);
  var seed = orb.seed * 9301 + 49297;
  double rand() {
    seed = (seed * 9301 + 49297) % 233280;
    return seed / 233280;
  }

  final start = c + Offset(math.cos(orb.crackAngle), math.sin(orb.crackAngle)) * r * 0.92;
  final light = Path();
  for (var branch = 0; branch < 4; branch++) {
    var dir = orb.crackAngle + math.pi + (rand() - 0.5) * 2.0;
    var p = start;
    light.moveTo(p.dx, p.dy);
    final steps = 4 + (rand() * 2).floor();
    final length = r * (0.9 + rand() * 0.9) * progress;
    for (var i = 0; i < steps; i++) {
      dir += (rand() - 0.5) * 1.1;
      p += Offset(math.cos(dir), math.sin(dir)) * (length / steps);
      if ((p - c).distance > r * 0.97) break;
      light.lineTo(p.dx, p.dy);
    }
  }
  _crackDark
    ..strokeWidth = math.max(1.4, r * 0.07)
    ..color = Color.fromRGBO(20, 26, 60, 0.55 * alpha);
  canvas.drawPath(light.shift(Offset(r * 0.03, r * 0.03)), _crackDark);
  _crackLight
    ..strokeWidth = math.max(1.0, r * 0.045)
    ..color = Color.fromRGBO(255, 255, 255, 0.95 * alpha);
  canvas.drawPath(light, _crackLight);
}
