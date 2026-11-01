import 'dart:math' as math;
import 'dart:ui';

import '../progress/cosmetics.dart';

/// The surface of a ball set ([Finish]), painted over a ball of radius [r]
/// centred on (0, 0). The caller clips to the piece; [glowUnder] is the part
/// of a glowing finish that spills outside it. Baked once into the sprites,
/// so none of this runs per frame. [seed] varies the pattern per colour.
void paintFinish(Canvas canvas, double r, Color color, Finish finish, int seed) {
  final random = math.Random(seed * 7919 + finish.index);
  switch (finish) {
    case Finish.gloss:
      break;
    case Finish.sugar:
      // Soft and pastel, dusted with sugar.
      canvas.drawCircle(Offset.zero, r, Paint()..color = const Color(0x1AFFFFFF));
      final sugar = Paint()..color = const Color(0xD9FFFFFF);
      for (var i = 0; i < 16; i++) {
        final p = _inDisc(random, r * 0.85);
        canvas.drawCircle(p, r * (0.025 + random.nextDouble() * 0.03), sugar);
      }
    case Finish.dew:
      // Fresh: a few dewdrops catching the light.
      for (var i = 0; i < 3; i++) {
        final p = _inDisc(random, r * 0.62).translate(r * 0.1, r * 0.15);
        final d = r * (0.09 + random.nextDouble() * 0.06);
        canvas.drawCircle(p.translate(d * 0.15, d * 0.25), d, Paint()..color = const Color(0x33000000));
        canvas.drawCircle(p, d, Paint()..color = const Color(0x40FFFFFF));
        canvas.drawCircle(p.translate(-d * 0.35, -d * 0.35), d * 0.32, Paint()..color = const Color(0xE6FFFFFF));
      }
    case Finish.pearl:
      // Pearly: a sheen sliding from pink to aqua across the ball.
      canvas.drawCircle(
        Offset.zero,
        r,
        Paint()
          ..blendMode = BlendMode.screen
          ..shader = Gradient.linear(
            Offset(-r, -r),
            Offset(r, r),
            const [Color(0x59FFB3E6), Color(0x14FFFFFF), Color(0x5980FFF0), Color(0x26B3B3FF)],
            const [0.0, 0.4, 0.75, 1.0],
          ),
      );
      canvas.drawCircle(
        Offset.zero,
        r * 0.9,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.12
          ..color = const Color(0x33FFFFFF)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.08),
      );
    case Finish.glow:
      // Neon: lit from inside, with a bright rim.
      canvas.drawCircle(
        Offset.zero,
        r,
        Paint()
          ..blendMode = BlendMode.screen
          ..shader = Gradient.radial(
            Offset.zero,
            r,
            [Color.lerp(color, const Color(0xFFFFFFFF), 0.55)!.withValues(alpha: 0.55), color.withValues(alpha: 0)],
            const [0.0, 0.7],
          ),
      );
      canvas.drawCircle(
        Offset.zero,
        r * 0.94,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.08
          ..color = Color.lerp(color, const Color(0xFFFFFFFF), 0.7)!.withValues(alpha: 0.85)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.04),
      );
    case Finish.cosmic:
      // Starry: a deep nebula swirl with tiny stars.
      canvas.drawCircle(
        Offset.zero,
        r,
        Paint()
          ..shader = Gradient.sweep(
            Offset(r * 0.1, r * 0.1),
            [
              const Color(0x00000000),
              const Color(0x330B0630),
              const Color(0x00000000),
              const Color(0x400B0630),
              const Color(0x00000000),
            ],
            const [0.0, 0.25, 0.5, 0.75, 1.0],
            TileMode.clamp,
            random.nextDouble() * math.pi,
          ),
      );
      final star = Paint()..color = const Color(0xF2FFFFFF);
      for (var i = 0; i < 12; i++) {
        canvas.drawCircle(_inDisc(random, r * 0.88), r * (0.015 + random.nextDouble() * 0.025), star);
      }
      for (var i = 0; i < 2; i++) {
        _twinkle(canvas, _inDisc(random, r * 0.6), r * (0.12 + random.nextDouble() * 0.06));
      }
  }
}

/// The glow a [Finish.glow] ball casts around itself, drawn under the ball.
void paintGlowUnder(Canvas canvas, double r, Color color) {
  canvas.drawCircle(
    Offset.zero,
    r * 1.35,
    Paint()
      ..shader = Gradient.radial(
        Offset.zero,
        r * 1.35,
        [color.withValues(alpha: 0.5), color.withValues(alpha: 0)],
        const [0.6, 1.0],
      ),
  );
}

Offset _inDisc(math.Random random, double radius) {
  final a = random.nextDouble() * math.pi * 2;
  final d = math.sqrt(random.nextDouble()) * radius;
  return Offset(math.cos(a) * d, math.sin(a) * d);
}

/// A four-pointed sparkle.
void _twinkle(Canvas canvas, Offset c, double s) {
  final path = Path()
    ..moveTo(c.dx, c.dy - s)
    ..quadraticBezierTo(c.dx, c.dy, c.dx + s, c.dy)
    ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + s)
    ..quadraticBezierTo(c.dx, c.dy, c.dx - s, c.dy)
    ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - s)
    ..close();
  canvas.drawPath(path, Paint()..color = const Color(0xF2FFFFFF));
}
