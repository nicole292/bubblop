import 'dart:math' as math;
import 'dart:ui';

import '../progress/cosmetics.dart';

/// How a ball feels right now. Chosen every frame from what is happening
/// on the board (board_component.dart); purely visual.
enum Mood {
  /// Looking around, blinking now and then.
  idle,

  /// About to pop: wide eyes, open mouth.
  excited,

  /// A chain just went off: happy eyes, big grin, a little hop.
  happy,

  /// Its column is nearly full, or a bomb is aimed close by: worried
  /// brows, wobbly mouth, a sweat drop, trembling.
  scared,

  /// Sealed in a shell: eyes shut, waiting to be freed.
  asleep,

  /// The round was lost.
  sad,
}

final _ink = Paint()..color = const Color(0xFF2B2140);
final _line = Paint()
  ..style = PaintingStyle.stroke
  ..strokeCap = StrokeCap.round
  ..color = const Color(0xFF2B2140);
final _white = Paint()..color = const Color(0xFFFFFFFF);
final _blush = Paint()..color = const Color(0x59FF6F91);
final _tongue = Paint()..color = const Color(0xFFFF7A93);
final _sweat = Paint()..color = const Color(0xCC9FE3FF);

/// Where the face sits on each piece, as (x, y, size) in ball radii: on
/// the frosting's wrapper of a cupcake, below a donut's hole, and so on.
(double, double, double) faceAnchor(PieceShape shape) => switch (shape) {
  PieceShape.donut => (0, 0.5, 0.55),
  PieceShape.cupcake => (0, 0.5, 0.6),
  PieceShape.macaron => (0, 0.02, 0.8),
  PieceShape.gem => (0, -0.05, 0.7),
  PieceShape.cherry => (0, 0.2, 0.85),
  PieceShape.strawberry => (0, 0.05, 0.85),
  PieceShape.kitty || PieceShape.bunny || PieceShape.bear => (0, 0.12, 1.0),
  PieceShape.frog => (0, 0.08, 1.0),
  PieceShape.heart => (0, -0.05, 0.85),
  PieceShape.star => (0, 0.05, 0.75),
  _ => (0, 0.05, 1.0),
};

/// Draws a face for [mood] on a piece of radius [r] centred on [c]. [look]
/// shifts the pupils (-1..1 each way), [time] and [seed] drive blinking.
void paintFace(
  Canvas canvas,
  Offset c,
  double r,
  Mood mood, {
  required PieceShape shape,
  Offset look = Offset.zero,
  double time = 0,
  int seed = 0,
  double alpha = 1,
}) {
  if (alpha < 0.3 || r < 4) return;
  final (ax, ay, k) = faceAnchor(shape);
  final s = r * k;
  final o = c.translate(ax * r, ay * r);
  final eyeX = s * 0.34, eyeY = -s * 0.08;
  final l = Offset(o.dx - eyeX, o.dy + eyeY), rr = Offset(o.dx + eyeX, o.dy + eyeY);
  _line.strokeWidth = math.max(1.2, s * 0.085);

  // Blush first, under everything.
  for (final e in [l, rr]) {
    canvas.drawOval(
      Rect.fromCenter(
        center: e.translate(e.dx < o.dx ? -s * 0.12 : s * 0.12, s * 0.3),
        width: s * 0.3,
        height: s * 0.16,
      ),
      _blush,
    );
  }

  switch (mood) {
    case Mood.asleep:
      for (final e in [l, rr]) {
        canvas.drawArc(Rect.fromCenter(center: e, width: s * 0.26, height: s * 0.2), 0.2, math.pi - 0.4, false, _line);
      }
      canvas.drawCircle(o.translate(0, s * 0.3), s * 0.06, _ink);
    case Mood.happy:
      for (final e in [l, rr]) {
        canvas.drawArc(
          Rect.fromCenter(center: e.translate(0, s * 0.06), width: s * 0.28, height: s * 0.26),
          math.pi + 0.25,
          math.pi - 0.5,
          false,
          _line,
        );
      }
      _grin(canvas, o.translate(0, s * 0.22), s, open: true);
    case Mood.excited:
      for (final e in [l, rr]) {
        _eye(canvas, e, s * 1.15, look);
      }
      canvas.drawOval(Rect.fromCenter(center: o.translate(0, s * 0.3), width: s * 0.24, height: s * 0.26), _ink);
      canvas.drawOval(Rect.fromCenter(center: o.translate(0, s * 0.37), width: s * 0.14, height: s * 0.08), _tongue);
    case Mood.scared:
      for (final e in [l, rr]) {
        canvas.drawCircle(e, s * 0.16, _white);
        canvas.drawCircle(e.translate(look.dx * s * 0.03, s * 0.02), s * 0.08, _ink);
      }
      // Worried brows slanting up towards the middle.
      for (final (e, dir) in [(l, 1.0), (rr, -1.0)]) {
        canvas.drawLine(e.translate(-dir * s * 0.12, -s * 0.2), e.translate(dir * s * 0.1, -s * 0.28), _line);
      }
      final wobble = Path()..moveTo(o.dx - s * 0.16, o.dy + s * 0.32);
      for (var i = 1; i <= 4; i++) {
        wobble.lineTo(o.dx - s * 0.16 + i * s * 0.08, o.dy + s * (i.isOdd ? 0.27 : 0.32));
      }
      canvas.drawPath(wobble, _line);
      final drop = rr.translate(s * 0.32, -s * 0.12);
      canvas.drawPath(
        Path()
          ..moveTo(drop.dx, drop.dy - s * 0.14)
          ..quadraticBezierTo(drop.dx + s * 0.09, drop.dy, drop.dx, drop.dy + s * 0.04)
          ..quadraticBezierTo(drop.dx - s * 0.09, drop.dy, drop.dx, drop.dy - s * 0.14),
        _sweat,
      );
    case Mood.sad:
      for (final e in [l, rr]) {
        _eye(canvas, e.translate(0, s * 0.04), s * 0.9, const Offset(0, 0.6));
      }
      canvas.drawArc(
        Rect.fromCenter(center: o.translate(0, s * 0.42), width: s * 0.3, height: s * 0.2),
        math.pi + 0.3,
        math.pi - 0.6,
        false,
        _line,
      );
    case Mood.idle:
      // A blink every few seconds, at a different moment for every ball.
      final blink = (time + seed * 0.731) % 4.2 < 0.12;
      for (final e in [l, rr]) {
        if (blink) {
          canvas.drawLine(e.translate(-s * 0.1, 0), e.translate(s * 0.1, 0), _line);
        } else {
          _eye(canvas, e, s, look);
        }
      }
      _grin(canvas, o.translate(0, s * 0.2), s, open: false);
  }
}

/// A shiny dark eye with a glint, its pupil shifted by [look].
void _eye(Canvas canvas, Offset e, double s, Offset look) {
  final p = e.translate(look.dx * s * 0.04, look.dy * s * 0.04);
  canvas.drawOval(Rect.fromCenter(center: p, width: s * 0.17, height: s * 0.23), _ink);
  canvas.drawCircle(p.translate(-s * 0.03, -s * 0.05), s * 0.04, _white);
}

/// A small smile, or a wide open grin with a tongue.
void _grin(Canvas canvas, Offset m, double s, {required bool open}) {
  if (!open) {
    canvas.drawArc(Rect.fromCenter(center: m, width: s * 0.24, height: s * 0.16), 0.25, math.pi - 0.5, false, _line);
    return;
  }
  final mouth = Path()
    ..moveTo(m.dx - s * 0.18, m.dy - s * 0.02)
    ..quadraticBezierTo(m.dx, m.dy + s * 0.3, m.dx + s * 0.18, m.dy - s * 0.02)
    ..close();
  canvas.drawPath(mouth, _ink);
  canvas.drawOval(Rect.fromCenter(center: m.translate(0, s * 0.1), width: s * 0.14, height: s * 0.08), _tongue);
}
