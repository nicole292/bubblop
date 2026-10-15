import 'dart:ui';

import 'package:pop_core/pop_core.dart';

import '../render/orb_sprites.dart';
import 'timings.dart';
import 'visual_orb.dart';

/// Draws one on-screen orb from the baked sprites, applying its animation
/// state (squash, highlight glow, shell reveal, pop shrink and fade).
void paintOrb(Canvas canvas, OrbSprites sprites, Offset center, VisualOrb orb) {
  if (orb.alpha <= 0 || orb.scale <= 0) return;
  final s = orb.squash / Timings.squash;
  final sx = orb.scale * (1 + 0.10 * s);
  final sy = orb.scale * (1 - 0.10 * s);
  // Squash keeps the orb resting on its bottom edge; scaling (pops) stays
  // centred.
  final c = center.translate(0, sprites.radius * orb.scale * 0.10 * s);

  switch (orb.cell.kind) {
    case CellKind.stone:
      sprites.draw(canvas, sprites.stone, c, sx: sx, sy: sy, alpha: orb.alpha);
    case CellKind.shell:
      final t = orb.reveal;
      if (t < 1) {
        // The casing swells slightly and fades as it breaks away.
        final k = 1 + 0.18 * t;
        sprites.draw(canvas, sprites.shell(orb.cell.color), c,
            sx: sx * k, sy: sy * k, alpha: orb.alpha * (1 - t));
      }
      if (t > 0) {
        // The core grows from its encased size to a full orb.
        final k = 0.62 + 0.38 * t;
        sprites.draw(canvas, sprites.orb(orb.cell.color), c,
            sx: sx * k, sy: sy * k, alpha: orb.alpha * t);
      }
    case CellKind.orb:
      if (orb.glow > 0) {
        final k = 1 + 0.25 * orb.glow;
        sprites.draw(canvas, sprites.glow(orb.cell.color), c,
            sx: sx * k, sy: sy * k, alpha: orb.alpha * orb.glow);
      }
      sprites.draw(canvas, sprites.orb(orb.cell.color), c, sx: sx, sy: sy, alpha: orb.alpha);
  }
}

/// The soft shadow under an orb; drawn in a pass before all orbs.
void paintOrbShadow(Canvas canvas, OrbSprites sprites, Offset center, VisualOrb orb) {
  if (orb.alpha <= 0 || orb.scale <= 0) return;
  sprites.draw(canvas, sprites.shadow, center, sx: orb.scale, sy: orb.scale, alpha: orb.alpha * 0.8);
}
