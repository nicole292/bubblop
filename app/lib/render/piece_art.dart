import 'dart:ui';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;

import '../progress/cosmetics.dart';

/// One 3D piece rendered in Blender (tools/blender/make_pieces.py): the
/// coloured part lit in white ([body], tinted with the ball colour), its
/// highlights ([gloss]) and the parts that keep their own colours
/// ([detail], e.g. ears, leaves, sprinkles).
class PieceLayers {
  const PieceLayers(this.body, this.gloss, this.detail);
  final Image body;
  final Image gloss;
  final Image? detail;
}

/// The Blender pieces and the bomb, decoded once at start-up. Everything
/// that draws them falls back to plain balls (or a drawn bomb) if an image
/// is missing, so tests and a failed load still work.
abstract final class PieceArt {
  static final _pieces = <PieceShape, PieceLayers>{};
  static Image? bomb;

  /// The layers for [shape], or null for outline shapes and before [load].
  static PieceLayers? of(PieceShape shape) => _pieces[shape];

  static Future<void> load() async {
    Future<Image?> image(String name) async {
      try {
        final data = await rootBundle.load('assets/pieces/$name.png');
        final codec = await instantiateImageCodec(data.buffer.asUint8List());
        return (await codec.getNextFrame()).image;
      } catch (_) {
        return null;
      }
    }

    for (final shape in PieceShape.values.where((s) => s.isArt)) {
      final body = await image('${shape.name}_body');
      final gloss = await image('${shape.name}_gloss');
      if (body == null || gloss == null) {
        debugPrint('Piece art missing for ${shape.name}');
        continue;
      }
      _pieces[shape] = PieceLayers(body, gloss, await image('${shape.name}_detail'));
    }
    bomb = await image('bomb');
  }

  /// Draws [layers] tinted with [color] into [dst]: the body multiplied by
  /// the colour, then its highlights, then the untinted details.
  static void paint(Canvas canvas, PieceLayers layers, Color color, Rect dst, {double alpha = 1}) {
    final src = Rect.fromLTWH(0, 0, layers.body.width.toDouble(), layers.body.height.toDouble());
    final a = alpha.clamp(0.0, 1.0);
    canvas.drawImageRect(
      layers.body,
      src,
      dst,
      Paint()
        ..filterQuality = FilterQuality.medium
        ..colorFilter = ColorFilter.mode(color.withValues(alpha: a), BlendMode.modulate),
    );
    final plain = Paint()
      ..filterQuality = FilterQuality.medium
      ..color = Color.fromRGBO(255, 255, 255, a);
    canvas.drawImageRect(layers.gloss, src, dst, plain);
    final detail = layers.detail;
    if (detail != null) canvas.drawImageRect(detail, src, dst, plain);
  }
}
