import 'dart:ui';

import '../game/palette.dart';
import 'orb_material.dart';

/// Pre-rendered orb images at the current cell size. Drawing an image per
/// orb per frame is far cheaper than redrawing gradients and paths, which
/// keeps frame times low on ordinary phones. Rebaked when the layout changes.
class OrbSprites {
  OrbSprites._(this.radius, this._orbs, this._shells, this._glows, this.stone, this.shadow);

  /// Sprite half-size, in orb radii (room for shadow and glow).
  static const pad = 1.45;

  factory OrbSprites.bake(double radius, double pixelRatio) {
    Image bake(void Function(Canvas) paint) => _bake(radius, pixelRatio, paint);
    final colors = Palette.orbs.length;
    return OrbSprites._(
      radius,
      [for (var c = 0; c < colors; c++) bake((cv) => paintGlassOrb(cv, radius, c))],
      [for (var c = 0; c < colors; c++) bake((cv) => paintShell(cv, radius, c))],
      [for (var c = 0; c < colors; c++) bake((cv) => _paintGlow(cv, radius, Palette.orbs[c]))],
      bake((cv) => paintStone(cv, radius)),
      bake((cv) => paintContactShadow(cv, radius)),
    );
  }

  /// Logical radius the sprites were baked for.
  final double radius;
  final List<Image> _orbs;
  final List<Image> _shells;
  final List<Image> _glows;
  final Image stone;
  final Image shadow;

  Image orb(int color) => _orbs[color];
  Image shell(int color) => _shells[color];
  Image glow(int color) => _glows[color];

  final _paint = Paint()..filterQuality = FilterQuality.medium;

  /// Draws [image] centred on [center], scaled by [sx]/[sy], faded by [alpha].
  void draw(Canvas canvas, Image image, Offset center,
      {double sx = 1, double sy = 1, double alpha = 1}) {
    if (alpha <= 0) return;
    final half = radius * pad;
    final dst = Rect.fromCenter(center: center, width: half * 2 * sx, height: half * 2 * sy);
    final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    _paint.color = Color.fromRGBO(255, 255, 255, alpha.clamp(0.0, 1.0));
    canvas.drawImageRect(image, src, dst, _paint);
  }

  void dispose() {
    for (final image in [..._orbs, ..._shells, ..._glows, stone, shadow]) {
      image.dispose();
    }
  }

  static Image _bake(double radius, double pixelRatio, void Function(Canvas) paint) {
    final size = (radius * pad * 2 * pixelRatio).ceil();
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder)
      ..translate(size / 2, size / 2)
      ..scale(pixelRatio);
    paint(canvas);
    final picture = recorder.endRecording();
    final image = picture.toImageSync(size, size);
    picture.dispose();
    return image;
  }

  static void _paintGlow(Canvas canvas, double r, Color color) {
    canvas.drawCircle(
      Offset.zero,
      r * pad,
      Paint()
        ..shader = Gradient.radial(Offset.zero, r * pad, [
          color.withValues(alpha: 0.75),
          color.withValues(alpha: 0.25),
          color.withValues(alpha: 0),
        ], const [0.45, 0.7, 1.0]),
    );
  }
}
