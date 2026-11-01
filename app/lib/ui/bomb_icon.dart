import 'package:flutter/material.dart';

import '../game/palette.dart';
import '../render/piece_art.dart';

/// The bomb from the board (its Blender render), at [size]. Falls back to
/// an icon if the image is missing.
class BombIcon extends StatelessWidget {
  const BombIcon({super.key, this.size = 22});
  final double size;

  @override
  Widget build(BuildContext context) {
    final image = PieceArt.bomb;
    if (image == null) return Icon(Icons.brightness_1, size: size * 0.8, color: Palette.ink);
    // The render leaves room around the bomb; crop to it.
    return SizedBox.square(
      dimension: size,
      child: OverflowBox(
        maxWidth: size * 1.45,
        maxHeight: size * 1.45,
        child: RawImage(image: image, width: size * 1.45, height: size * 1.45, filterQuality: FilterQuality.medium),
      ),
    );
  }
}
