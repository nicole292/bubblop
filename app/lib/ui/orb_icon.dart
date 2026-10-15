import 'package:flutter/widgets.dart';

import '../render/orb_material.dart';

/// A glass orb drawn with the same material as the board, for the HUD.
class OrbIcon extends StatelessWidget {
  const OrbIcon({super.key, required this.color, required this.size});

  final int color;
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _OrbPainter(color));
}

class _OrbPainter extends CustomPainter {
  _OrbPainter(this.color);
  final int color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);
    paintGlassOrb(canvas, size.width / 2, color);
  }

  @override
  bool shouldRepaint(_OrbPainter old) => old.color != color;
}
