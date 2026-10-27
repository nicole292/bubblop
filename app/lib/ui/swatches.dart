import 'package:flutter/material.dart';

import '../progress/cosmetics.dart';

/// A small preview of a cosmetic: five glossy balls for a ball set, a
/// rounded gradient for a sky.
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
    return SizedBox(
      height: height,
      child: Row(
        // Wide: the five balls spread across the space, as in a row of the board.
        mainAxisSize: wide ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: wide ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
        children: [
          for (final (i, color) in cosmetic.colors.indexed) ...[
            if (i > 0 && !wide) SizedBox(width: ball * 0.12),
            GlossyBall(color: color, size: ball),
          ],
        ],
      ),
    );
  }
}

/// A simple shaded ball: lighter top-left, the colour below, a highlight.
class GlossyBall extends StatelessWidget {
  const GlossyBall({super.key, required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
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
