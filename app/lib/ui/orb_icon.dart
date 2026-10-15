import 'package:flutter/widgets.dart';

import '../render/orb_sprites.dart';

/// A glass orb for the HUD, drawn from the same baked sprites as the board
/// (one image draw). Drawing the vector material here instead cost ~8 ms of
/// raster time per frame, because the HUD is redrawn every frame on top of
/// the game canvas.
class OrbIcon extends StatelessWidget {
  const OrbIcon({super.key, required this.sprites, required this.color, required this.size});

  final OrbSprites? sprites;
  final int color;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: sprites == null ? null : _OrbPainter(sprites!, color),
      );
}

class _OrbPainter extends CustomPainter {
  _OrbPainter(this.sprites, this.color);
  final OrbSprites sprites;
  final int color;

  @override
  void paint(Canvas canvas, Size size) {
    // Sprites are baked with padding around the orb; scale so the orb
    // itself fills [size].
    final scale = size.width / (sprites.radius * 2);
    sprites.draw(canvas, sprites.ball(color), size.center(Offset.zero), sx: scale, sy: scale);
  }

  @override
  bool shouldRepaint(_OrbPainter old) => old.sprites != sprites || old.color != color;
}
