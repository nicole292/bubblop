import 'dart:ui';

import 'package:flutter/foundation.dart' show debugPrint;

import '../game/palette.dart';
import 'orb_material.dart';

/// Pre-rendered images for everything drawn many times per frame: orbs,
/// shells, glows and effect sprites. Each is rendered once per screen size
/// (orbs with the glass shader in shaders/orb.frag), so a frame only draws
/// images. Rebaked when the layout changes.
class OrbSprites {
  OrbSprites._({
    required this.radius,
    required this._orbs,
    required this._shells,
    required this._halos,
    required this.stone,
    required this.shadow,
    required this.bloom,
    required this.ring,
    required this.usesShader,
  });

  /// Sprite half-size, in orb radii (room for shadow and glow).
  static const pad = 1.45;

  static const _shaderAsset = 'shaders/orb.frag';

  /// Loads the glass shader, or returns null (with a log line) if this
  /// device cannot compile it; sprites then fall back to Canvas drawing.
  static Future<FragmentProgram?> loadProgram() async {
    try {
      return await FragmentProgram.fromAsset(_shaderAsset);
    } catch (e) {
      debugPrint('Orb shader unavailable, using fallback material: $e');
      return null;
    }
  }

  factory OrbSprites.bake(double radius, double pixelRatio, FragmentProgram? program) {
    final size = (radius * pad * 2 * pixelRatio).ceil();
    final rPx = radius * pixelRatio;

    Image picture(void Function(Canvas canvas) paint) {
      final recorder = PictureRecorder();
      paint(Canvas(recorder));
      final pic = recorder.endRecording();
      final image = pic.toImageSync(size, size);
      pic.dispose();
      return image;
    }

    /// Runs [paint] in logical units centred on the sprite.
    void centred(Canvas canvas, void Function(Canvas) paint) {
      canvas.save();
      canvas.translate(size / 2, size / 2);
      canvas.scale(pixelRatio);
      paint(canvas);
      canvas.restore();
    }

    void shaderPass(Canvas canvas, Color color, double mode) {
      final shader = program!.fragmentShader()
        ..setFloat(0, size.toDouble())
        ..setFloat(1, size.toDouble())
        ..setFloat(2, rPx)
        ..setFloat(3, color.r)
        ..setFloat(4, color.g)
        ..setFloat(5, color.b)
        ..setFloat(6, mode);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()), Paint()..shader = shader);
      shader.dispose();
    }

    final colors = Palette.orbs.length;
    final orbs = <Image>[];
    final shells = <Image>[];
    for (var c = 0; c < colors; c++) {
      final color = Palette.orbs[c];
      final orb = picture((canvas) {
        if (program != null) {
          shaderPass(canvas, color, 0);
          centred(canvas, (cv) => paintInnerGlyph(cv, radius, c));
        } else {
          centred(canvas, (cv) => paintGlassOrb(cv, radius, c));
        }
      });
      orbs.add(orb);
      final coreImage = program != null ? picture((cv) => shaderPass(cv, color, 2)) : null;
      shells.add(picture((canvas) {
        if (coreImage != null) {
          // Core orb (no reflection of its own), bold symbol, then the
          // frosted casing over both.
          final core = Rect.fromCenter(
              center: Offset(size / 2, size / 2), width: size * 0.6, height: size * 0.6);
          canvas.drawImageRect(coreImage, Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()), core,
              Paint()..filterQuality = FilterQuality.high);
          centred(canvas, (cv) => paintGlyph(cv, radius * 0.24, c,
              alpha: 0.95, embossColor: const Color(0xFF0B1030)));
          shaderPass(canvas, const Color(0xFFFFFFFF), 1);
        } else {
          centred(canvas, (cv) => paintShell(cv, radius, c));
        }
      }));
      // Safe now: the shell picture has been rasterised into its own image.
      coreImage?.dispose();
    }

    return OrbSprites._(
      radius: radius,
      orbs: orbs,
      shells: shells,
      halos: [
        for (var c = 0; c < colors; c++)
          picture((canvas) => centred(canvas, (cv) => _paintHalo(cv, radius, Palette.orbs[c]))),
      ],
      stone: picture((canvas) => centred(canvas, (cv) => paintStone(cv, radius))),
      shadow: picture((canvas) => centred(canvas, (cv) => paintContactShadow(cv, radius))),
      bloom: picture((canvas) => centred(canvas, (cv) => _paintBloom(cv, radius))),
      ring: picture((canvas) => centred(canvas, (cv) => _paintRing(cv, radius))),
      usesShader: program != null,
    );
  }

  /// Logical radius the sprites were baked for.
  final double radius;
  final List<Image> _orbs;
  final List<Image> _shells;
  final List<Image> _halos;
  final Image stone;
  final Image shadow;

  /// White soft light (tint it); used for flashes, sparks and motes.
  final Image bloom;

  /// White soft ring (tint it); used for shockwaves.
  final Image ring;

  /// False when the shader could not be loaded and Canvas fallbacks are used.
  final bool usesShader;

  Image orb(int color) => _orbs[color];
  Image shell(int color) => _shells[color];
  Image halo(int color) => _halos[color];

  final _paint = Paint()..filterQuality = FilterQuality.medium;

  /// Draws [image] centred on [center], scaled by [sx]/[sy], faded by [alpha].
  /// [paint] overrides the default (e.g. additive or tinted drawing).
  void draw(Canvas canvas, Image image, Offset center,
      {double sx = 1, double sy = 1, double alpha = 1, Paint? paint}) {
    if (alpha <= 0) return;
    final half = radius * pad;
    final dst = Rect.fromCenter(center: center, width: half * 2 * sx, height: half * 2 * sy);
    final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final p = paint ?? _paint;
    p.color = Color.fromRGBO(255, 255, 255, alpha.clamp(0.0, 1.0));
    canvas.drawImageRect(image, src, dst, p);
  }

  void dispose() {
    for (final image in [..._orbs, ..._shells, ..._halos, stone, shadow, bloom, ring]) {
      image.dispose();
    }
  }

  static void _paintHalo(Canvas canvas, double r, Color color) {
    canvas.drawCircle(
      Offset.zero,
      r * pad,
      Paint()
        ..shader = Gradient.radial(Offset.zero, r * pad, [
          color.withValues(alpha: 0.8),
          color.withValues(alpha: 0.28),
          color.withValues(alpha: 0),
        ], const [0.35, 0.65, 1.0]),
    );
  }

  static void _paintBloom(Canvas canvas, double r) {
    canvas.drawCircle(
      Offset.zero,
      r * pad,
      Paint()
        ..shader = Gradient.radial(Offset.zero, r * pad, const [
          Color(0xFFFFFFFF),
          Color(0x99FFFFFF),
          Color(0x26FFFFFF),
          Color(0x00FFFFFF),
        ], const [0.0, 0.18, 0.5, 1.0]),
    );
  }

  static void _paintRing(Canvas canvas, double r) {
    final outer = r * pad;
    canvas.drawCircle(
      Offset.zero,
      outer,
      Paint()
        ..shader = Gradient.radial(Offset.zero, outer, const [
          Color(0x00FFFFFF),
          Color(0x00FFFFFF),
          Color(0x66FFFFFF),
          Color(0xFFFFFFFF),
          Color(0x55FFFFFF),
          Color(0x00FFFFFF),
        ], const [0.0, 0.62, 0.80, 0.88, 0.94, 1.0]),
    );
  }
}
