import 'dart:math' as math;
import 'dart:ui';

import '../progress/cosmetics.dart';

/// How far past the ball radius a shaped piece's material is drawn, so the
/// shading covers every outline (the farthest point is the star's top tip).
const shapeCover = 1.2;

/// The outline of a non-round piece, centred on (0, 0) and sized for ball
/// radius [r], or null for a round ball. Every outline stays within about
/// one radius of the centre left, right, up and down, so neighbours on the
/// board never touch.
Path? piecePath(PieceShape shape, double r) => switch (shape) {
      PieceShape.ball => null,
      PieceShape.jelly => Path()
        ..addRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: r * 1.78, height: r * 1.78), Radius.circular(r * 0.5))),
      PieceShape.heart => _heart(r),
      PieceShape.star => _star(r),
      PieceShape.flower => _flower(r),
    };

/// Two round lobes meeting in a soft point, nudged up so it looks centred.
Path _heart(double r) {
  final path = Path()..moveTo(0, -0.5 * r);
  // Each curve: two control points and an end point, in radii.
  void curve(double x1, double y1, double x2, double y2, double x, double y) =>
      path.cubicTo(x1 * r, (y1 - 0.05) * r, x2 * r, (y2 - 0.05) * r, x * r, (y - 0.05) * r);
  curve(0.25, -0.95, 1.0, -0.95, 1.0, -0.3);
  curve(1.0, 0.2, 0.45, 0.55, 0, 0.95);
  curve(-0.45, 0.55, -1.0, 0.2, -1.0, -0.3);
  curve(-1.0, -0.95, -0.25, -0.95, 0, -0.45);
  return path..close();
}

/// A plump five-point star with rounded tips, nudged down so it looks
/// centred.
Path _star(double r) {
  final points = <Offset>[
    for (var i = 0; i < 10; i++)
      Offset(math.cos(-math.pi / 2 + i * math.pi / 5), math.sin(-math.pi / 2 + i * math.pi / 5)) *
              (i.isEven ? r * 1.1 : r * 0.62) +
          Offset(0, r * 0.05),
  ];
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final corner = points[i];
    final before = Offset.lerp(corner, points[(i + 9) % 10], i.isEven ? 0.28 : 0.15)!;
    final after = Offset.lerp(corner, points[(i + 1) % 10], i.isEven ? 0.28 : 0.15)!;
    i == 0 ? path.moveTo(before.dx, before.dy) : path.lineTo(before.dx, before.dy);
    path.quadraticBezierTo(corner.dx, corner.dy, after.dx, after.dy);
  }
  return path..close();
}

/// Five round petals around a round middle, merged into one outline so the
/// contour line doesn't cross the petals.
Path _flower(double r) {
  var path = Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: r * 0.62));
  for (var i = 0; i < 5; i++) {
    final a = -math.pi / 2 + i * 2 * math.pi / 5;
    final petal = Path()
      ..addOval(Rect.fromCircle(center: Offset(math.cos(a), math.sin(a)) * r * 0.56, radius: r * 0.46));
    path = Path.combine(PathOperation.union, path, petal);
  }
  return path;
}
