import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart' show HSLColor;

import '../game/palette.dart';

/// "Lit Glass at Night" materials, drawn with plain Canvas calls so the same
/// code can bake sprites (OrbSprites) and draw HUD icons.
///
/// Every function draws centred on (0, 0). One light source, top-left, for
/// everything.

Color _shift(Color c, double lightness, {double saturation = 0}) {
  final hsl = HSLColor.fromColor(c);
  return hsl
      .withLightness((hsl.lightness + lightness).clamp(0.0, 1.0))
      .withSaturation((hsl.saturation + saturation).clamp(0.0, 1.0))
      .toColor();
}

/// A soft contact shadow under a resting orb.
void paintContactShadow(Canvas canvas, double r) {
  canvas.drawOval(
    Rect.fromCenter(center: Offset(0, r * 0.86), width: r * 1.55, height: r * 0.34),
    Paint()
      ..color = const Color(0x8C000000)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.12),
  );
}

/// A coloured glass orb lit from inside.
void paintGlassOrb(Canvas canvas, double r, int colorIndex, {double glyphAlpha = 0.55}) {
  final base = Palette.orbs[colorIndex];
  final light = _shift(base, 0.22, saturation: 0.05);
  final deep = _shift(base, -0.30, saturation: 0.05);
  final circle = Rect.fromCircle(center: Offset.zero, radius: r);

  // Body: volume from a light-to-deep radial falloff.
  canvas.drawCircle(
    Offset.zero,
    r,
    Paint()
      ..shader = Gradient.radial(
        Offset(-r * 0.28, -r * 0.34),
        r * 1.45,
        [light, base, deep],
        const [0.0, 0.42, 1.0],
      ),
  );

  // Inner light: glow transmitted through the glass toward the lower right.
  canvas.drawCircle(
    Offset(r * 0.12, r * 0.30),
    r * 0.72,
    Paint()
      ..shader = Gradient.radial(
        Offset(r * 0.12, r * 0.30),
        r * 0.72,
        [_shift(base, 0.30).withValues(alpha: 0.55), _shift(base, 0.30).withValues(alpha: 0)],
      ),
  );

  // Rim light along the lower edge, separating the orb from the dark board.
  canvas.drawCircle(
    Offset.zero,
    r * 0.965,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.07
      ..shader = Gradient.linear(
        circle.topCenter,
        circle.bottomCenter,
        [light.withValues(alpha: 0), light.withValues(alpha: 0.65)],
        const [0.35, 1.0],
      ),
  );

  paintGlyph(canvas, r * 0.36, colorIndex, alpha: glyphAlpha, embossColor: deep);

  // Specular highlight: a soft window reflection plus a crisp hot spot.
  canvas.save();
  canvas.translate(-r * 0.34, -r * 0.46);
  canvas.rotate(-0.55);
  final spec = Rect.fromCenter(center: Offset.zero, width: r * 0.78, height: r * 0.36);
  canvas.drawOval(
    spec,
    Paint()
      ..shader = Gradient.linear(
        spec.topCenter,
        spec.bottomCenter,
        const [Color(0xD9FFFFFF), Color(0x00FFFFFF)],
      ),
  );
  canvas.restore();
  canvas.drawCircle(Offset(-r * 0.46, -r * 0.50), r * 0.075, Paint()..color = const Color(0xE6FFFFFF));

  // Thin dark edge so neighbouring orbs never blur together.
  canvas.drawCircle(
    Offset.zero,
    r,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.035
      ..color = deep.withValues(alpha: 0.7),
  );
}

/// A frosted glass casing with a fully coloured core and a bold symbol, so
/// its colour reads at a glance (and without colour vision).
void paintShell(Canvas canvas, double r, int colorIndex) {
  final circle = Rect.fromCircle(center: Offset.zero, radius: r);

  // Casing body: clear in the middle, frostier toward the edge (fresnel).
  canvas.drawCircle(
    Offset.zero,
    r,
    Paint()
      ..shader = Gradient.radial(
        Offset(-r * 0.15, -r * 0.2),
        r * 1.1,
        const [Color(0x1FC9D3FF), Color(0x47C9D3FF), Color(0x80AEB9EE)],
        const [0.0, 0.7, 1.0],
      ),
  );

  // Coloured core with a high-contrast symbol.
  canvas.save();
  canvas.scale(0.62);
  paintGlassOrb(canvas, r, colorIndex, glyphAlpha: 0.0);
  canvas.restore();
  paintGlyph(canvas, r * 0.25, colorIndex, alpha: 0.92, embossColor: const Color(0xFF0E1226));

  // Frost facets: two faint arcs that read as a casing, not an orb.
  final facet = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = r * 0.035
    ..color = const Color(0x40FFFFFF);
  canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r * 0.80), 0.4, 1.1, false, facet);
  canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: r * 0.80), 3.6, 0.7, false, facet);

  // Casing rim: bright at top-left, fading round to the bottom-right.
  canvas.drawCircle(
    Offset.zero,
    r * 0.95,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.09
      ..shader = Gradient.linear(
        circle.topLeft,
        circle.bottomRight,
        const [Color(0xB3FFFFFF), Color(0x33DDE3FF), Color(0x1ADDE3FF)],
        const [0.0, 0.6, 1.0],
      ),
  );

  // Casing highlight, larger and softer than an orb's.
  canvas.save();
  canvas.translate(-r * 0.38, -r * 0.52);
  canvas.rotate(-0.6);
  canvas.drawOval(
    Rect.fromCenter(center: Offset.zero, width: r * 0.62, height: r * 0.2),
    Paint()..color = const Color(0x8CFFFFFF),
  );
  canvas.restore();
}

/// A matte slate block (stones experiment only).
void paintStone(Canvas canvas, double r) {
  final rect = Rect.fromCircle(center: Offset.zero, radius: r * 0.9);
  final rrect = RRect.fromRectAndRadius(rect, Radius.circular(r * 0.32));
  canvas.drawRRect(
    rrect,
    Paint()
      ..shader = Gradient.linear(rect.topLeft, rect.bottomRight,
          const [Color(0xFF8A8FA6), Color(0xFF545A72)]),
  );
  canvas.drawRRect(
    rrect.deflate(r * 0.04),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.05
      ..color = const Color(0x33FFFFFF),
  );
}

/// The colour's symbol as if set inside the glass: a soft inner glow, a lit
/// face and a shadowed upper lip (light comes from the top-left).
void paintInnerGlyph(Canvas canvas, double r, int colorIndex) {
  final base = Palette.orbs[colorIndex];
  final s = r * 0.33;
  final path = glyphPath(colorIndex, s).shift(Offset(r * 0.02, r * 0.05));
  canvas.drawPath(
    path,
    Paint()
      ..color = const Color(0x73FFFFFF)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.3),
  );
  canvas.drawPath(path.shift(Offset(0, -s * 0.09)),
      Paint()..color = _shift(base, -0.36).withValues(alpha: 0.75));
  canvas.drawPath(path, Paint()..color = Color.lerp(base, const Color(0xFFFFFFFF), 0.8)!.withValues(alpha: 0.88));
}

/// One symbol per colour so colour is never the only cue:
/// coral ●, saffron ▲, mint ■, azure ◆, orchid ✦.
void paintGlyph(Canvas canvas, double size, int colorIndex,
    {required double alpha, required Color embossColor}) {
  if (alpha <= 0) return;
  final path = glyphPath(colorIndex, size);
  // Etched look: a dark offset under a light face.
  canvas.drawPath(
    path.shift(Offset(0, size * 0.10)),
    Paint()..color = embossColor.withValues(alpha: alpha * 0.55),
  );
  canvas.drawPath(path, Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: alpha));
}

Path glyphPath(int colorIndex, double s) {
  switch (colorIndex) {
    case 0:
      return Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: s * 0.78));
    case 1:
      return Path()
        ..moveTo(0, -s * 0.95)
        ..lineTo(s * 0.92, s * 0.68)
        ..lineTo(-s * 0.92, s * 0.68)
        ..close();
    case 2:
      return Path()
        ..addRRect(RRect.fromRectAndRadius(
            Rect.fromCircle(center: Offset.zero, radius: s * 0.70), Radius.circular(s * 0.14)));
    case 3:
      return Path()
        ..moveTo(0, -s)
        ..lineTo(s * 0.80, 0)
        ..lineTo(0, s)
        ..lineTo(-s * 0.80, 0)
        ..close();
    default:
      final path = Path();
      for (var i = 0; i < 8; i++) {
        final angle = -math.pi / 2 + i * math.pi / 4;
        final radius = i.isEven ? s : s * 0.36;
        final p = Offset(math.cos(angle) * radius, math.sin(angle) * radius);
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      return path..close();
  }
}
