import 'dart:ui';

import 'package:flutter/painting.dart' show HSLColor;

import '../game/palette.dart';

/// Canvas versions of the ball materials. Used only if the shader in
/// shaders/ball.frag cannot be loaded on a device, plus the shared shadow.
/// Everything draws centred on (0, 0); light comes from the top-left.

Color _shift(Color c, double lightness) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness + lightness).clamp(0.0, 1.0)).toColor();
}

/// A soft shadow on the board under a resting ball.
void paintContactShadow(Canvas canvas, double r) {
  canvas.drawOval(
    Rect.fromCenter(center: Offset(0, r * 0.88), width: r * 1.5, height: r * 0.32),
    Paint()
      ..color = const Color(0x402A2370)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.12),
  );
}

/// Fallback ball: mostly solid colour, gentle shading, soft highlight.
void paintBall(Canvas canvas, double r, int colorIndex) {
  final base = Palette.balls[colorIndex];
  canvas.drawCircle(
    Offset.zero,
    r,
    Paint()
      ..shader = Gradient.radial(Offset(-r * 0.3, -r * 0.35), r * 1.45,
          [_shift(base, 0.08), base, _shift(base, -0.10)], const [0.0, 0.55, 1.0]),
  );
  canvas.save();
  canvas.translate(-r * 0.3, -r * 0.42);
  canvas.rotate(-0.6);
  canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: r * 0.62, height: r * 0.34),
      Paint()
        ..color = const Color(0x99FFFFFF)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.05));
  canvas.restore();
}

/// Fallback shell: the full-size ball under frosted glass with a white rim.
void paintShell(Canvas canvas, double r, int colorIndex) {
  paintBall(canvas, r, colorIndex);
  canvas.drawCircle(Offset.zero, r, Paint()..color = const Color(0x80FFFFFF));
  canvas.drawCircle(
    Offset.zero,
    r * 0.93,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.14
      ..color = const Color(0xF2FFFFFF),
  );
}

/// Grey ball (stones exist only in the simulator; kept so the renderer
/// never fails if that rule is ever enabled).
void paintStone(Canvas canvas, double r) {
  canvas.drawCircle(Offset.zero, r * 0.92, Paint()..color = const Color(0xFFB4B9D6));
}
