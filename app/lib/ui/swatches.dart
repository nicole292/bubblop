import 'package:flutter/material.dart';

import '../game/palette.dart';
import '../progress/cosmetics.dart';
import '../render/piece_shapes.dart';

/// A small preview of a cosmetic: five glossy pieces for a ball set (in the
/// chosen shape) or a shape (in the chosen colours), a rounded gradient for
/// a sky.
class CosmeticSwatch extends StatelessWidget {
  const CosmeticSwatch({super.key, required this.cosmetic, this.height = 40, this.wide = false});
  final Cosmetic cosmetic;
  final double height;

  /// Fills the available width (a long sky strip, or balls spread out).
  final bool wide;

  @override
  Widget build(BuildContext context) {
    if (cosmetic.kind == CosmeticKind.sky) {
      return Container(
        height: height,
        width: wide ? double.infinity : height * 2.6,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height * 0.3),
          // A wide strip runs left to right so all three sky colours show.
          gradient: LinearGradient(
            begin: wide ? Alignment.centerLeft : Alignment.topCenter,
            end: wide ? Alignment.centerRight : Alignment.bottomCenter,
            colors: cosmetic.colors,
          ),
          border: Border.all(color: Colors.white, width: 2),
        ),
      );
    }
    final ball = height * 0.72;
    final shape = cosmetic.kind == CosmeticKind.shape ? cosmetic.shape : Palette.shape;
    final colors = cosmetic.kind == CosmeticKind.shape ? Palette.balls : cosmetic.colors;
    return SizedBox(
      height: height,
      child: Row(
        // Wide: the five balls spread across the space, as in a row of the board.
        mainAxisSize: wide ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: wide ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
        children: [
          for (final (i, color) in colors.indexed) ...[
            if (i > 0 && !wide) SizedBox(width: ball * 0.12),
            GlossyBall(color: color, size: ball, shape: shape),
          ],
        ],
      ),
    );
  }
}

/// A simple shaded ball (or [shape]): lighter top-left, the colour below, a
/// highlight.
class GlossyBall extends StatelessWidget {
  const GlossyBall({super.key, required this.color, required this.size, this.shape = PieceShape.ball});
  final Color color;
  final double size;
  final PieceShape shape;

  @override
  Widget build(BuildContext context) {
    if (shape != PieceShape.ball) {
      return CustomPaint(size: Size.square(size), painter: _ShapePainter(color, shape));
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 0.95,
          colors: [Color.lerp(color, Colors.white, 0.35)!, color, Color.lerp(color, Colors.black, 0.12)!],
          stops: const [0, 0.6, 1],
        ),
      ),
      alignment: const Alignment(-0.35, -0.45),
      child: Container(
        width: size * 0.24,
        height: size * 0.16,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(size),
        ),
      ),
    );
  }
}

/// [GlossyBall]'s look, cut to a piece outline.
class _ShapePainter extends CustomPainter {
  _ShapePainter(this.color, this.shape);
  final Color color;
  final PieceShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final outline = piecePath(shape, r)!.shift(size.center(Offset.zero));
    canvas.save();
    canvas.clipPath(outline);
    final cover = Rect.fromCircle(center: size.center(Offset.zero), radius: r * shapeCover);
    canvas.drawRect(
        cover,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.4),
            radius: 0.85,
            colors: [Color.lerp(color, Colors.white, 0.35)!, color, Color.lerp(color, Colors.black, 0.12)!],
            stops: const [0, 0.6, 1],
          ).createShader(cover));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(r * 0.65, r * 0.55), width: r * 0.48, height: r * 0.32),
            Radius.circular(r)),
        Paint()..color = Colors.white.withValues(alpha: 0.75));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShapePainter old) => old.color != color || old.shape != shape;
}
