import 'dart:ui';

import 'package:pop_core/pop_core.dart';

import 'palette.dart';
import 'timings.dart';
import 'visual_orb.dart';

/// GREYBOX orb drawing: readable shapes for judging gameplay, not final art.
/// Stage 3 replaces this with the lit-glass material.
void paintOrb(Canvas canvas, Offset center, double radius, VisualOrb orb) {
  if (orb.alpha <= 0 || orb.scale <= 0) return;

  final s = orb.squash / Timings.squash;
  final sx = orb.scale * (1 + 0.08 * s);
  final sy = orb.scale * (1 - 0.08 * s);

  canvas.save();
  // Squash keeps the orb resting on its bottom edge.
  canvas.translate(center.dx, center.dy + radius * (1 - sy));
  canvas.scale(sx, sy);

  switch (orb.cell.kind) {
    case CellKind.stone:
      _stone(canvas, radius, orb.alpha);
    case CellKind.shell:
      _shell(canvas, radius, orb);
    case CellKind.orb:
      _orb(canvas, radius, Palette.orbs[orb.cell.color], orb.alpha, orb.glow);
  }
  canvas.restore();
}

void _orb(Canvas canvas, double r, Color color, double alpha, double glow) {
  if (glow > 0) {
    canvas.drawCircle(
      Offset.zero,
      r * (1 + 0.35 * glow),
      Paint()
        ..color = color.withValues(alpha: 0.35 * glow * alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.3),
    );
  }
  canvas.drawCircle(Offset(0, r * 0.08), r,
      Paint()..color = const Color(0xFF000000).withValues(alpha: 0.25 * alpha));
  canvas.drawCircle(Offset.zero, r, Paint()..color = color.withValues(alpha: alpha));
  canvas.drawOval(
    Rect.fromCenter(center: Offset(-r * 0.32, -r * 0.38), width: r * 0.7, height: r * 0.42),
    Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.35 * alpha),
  );
}

void _shell(Canvas canvas, double r, VisualOrb orb) {
  final color = Palette.orbs[orb.cell.color];
  if (orb.reveal > 0) {
    _orb(canvas, r, color, orb.alpha * orb.reveal, 0);
  }
  final shellAlpha = orb.alpha * (1 - orb.reveal);
  canvas.drawCircle(Offset.zero, r,
      Paint()..color = color.withValues(alpha: 0.28 * shellAlpha));
  canvas.drawCircle(
    Offset.zero,
    r * 0.94,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.12
      ..color = const Color(0xFFDDE3FF).withValues(alpha: 0.75 * shellAlpha),
  );
}

void _stone(Canvas canvas, double r, double alpha) {
  final rect = Rect.fromCircle(center: Offset.zero, radius: r * 0.92);
  canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(r * 0.3)),
      Paint()..color = Palette.stone.withValues(alpha: alpha));
}
