import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;

import '../game/palette.dart';
import 'orb_material.dart';

/// Pre-rendered images for everything drawn many times per frame: balls,
/// shells, halos and the shadow. Each is rendered once per screen size (balls
/// with the shader in shaders/ball.frag), so a frame only draws images.
/// Rebaked when the layout changes.
class OrbSprites {
  OrbSprites._({
    required this.radius,
    required this._balls,
    required this._shells,
    required this._halos,
    required this.stone,
    required this.shadow,
    required this.usesShader,
  });

  /// Sprite half-size, in ball radii (room for shadow and halo).
  static const pad = 1.45;

  static const _shaderAsset = 'shaders/ball.frag';

  /// Loads the ball shader, or returns null (with a log line) if this device
  /// cannot compile it; sprites then fall back to Canvas drawing.
  static Future<FragmentProgram?> loadProgram() async {
    // The web renderer compiles the shader but draws it misplaced (square or
    // quarter balls), so the browser build uses the Canvas material.
    if (kIsWeb) return null;
    try {
      return await FragmentProgram.fromAsset(_shaderAsset);
    } catch (e) {
      debugPrint('Ball shader unavailable, using fallback material: $e');
      return null;
    }
  }

  /// [shapes] adds a white symbol to every ball (the colour-blind option);
  /// shells show it through their glass.
  factory OrbSprites.bake(double radius, double pixelRatio, FragmentProgram? program, {bool shapes = false}) {
    final size = (radius * pad * 2 * pixelRatio).ceil();
    final rPx = radius * pixelRatio;
    final full = Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());

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
      canvas.drawRect(full, Paint()..shader = shader);
      shader.dispose();
    }

    final balls = <Image>[];
    final shells = <Image>[];
    for (var c = 0; c < Palette.balls.length; c++) {
      final ball = picture((canvas) {
        if (program != null) {
          shaderPass(canvas, Palette.balls[c], 0);
        } else {
          centred(canvas, (cv) => paintBall(cv, radius, c));
        }
        if (shapes) centred(canvas, (cv) => _paintSymbol(cv, radius, c));
      });
      balls.add(ball);
      shells.add(picture((canvas) {
        if (program != null) {
          // The full-size ball under frosted glass, so every cell reads
          // as the same size.
          canvas.drawImage(ball, Offset.zero, Paint());
          shaderPass(canvas, const Color(0xFFFFFFFF), 1);
        } else {
          centred(canvas, (cv) => paintShell(cv, radius, c));
          if (shapes) centred(canvas, (cv) => _paintSymbol(cv, radius, c));
        }
      }));
    }

    return OrbSprites._(
      radius: radius,
      balls: balls,
      shells: shells,
      halos: [
        for (final color in Palette.balls)
          picture((canvas) => centred(canvas, (cv) => _paintHalo(cv, radius, color))),
      ],
      stone: picture((canvas) => centred(canvas, (cv) => paintStone(cv, radius))),
      shadow: picture((canvas) => centred(canvas, (cv) => paintContactShadow(cv, radius))),
      usesShader: program != null,
    );
  }

  /// Logical radius the sprites were baked for.
  final double radius;
  final List<Image> _balls;
  final List<Image> _shells;
  final List<Image> _halos;
  final Image stone;
  final Image shadow;

  /// False when the shader could not be loaded and Canvas fallbacks are used.
  final bool usesShader;

  Image ball(int color) => _balls[color];
  Image shell(int color) => _shells[color];
  Image halo(int color) => _halos[color];

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
    for (final image in [..._balls, ..._shells, ..._halos, stone, shadow]) {
      image.dispose();
    }
  }

  /// One shape per colour, so balls can be told apart without colour:
  /// triangle, star, square, plus, ring (in [Palette.balls] order).
  static void _paintSymbol(Canvas canvas, double r, int color) {
    final s = r * 0.36;
    final path = Path();
    switch (color) {
      case 0:
        path
          ..moveTo(0, -s)
          ..lineTo(s * 0.95, s * 0.7)
          ..lineTo(-s * 0.95, s * 0.7)
          ..close();
      case 1:
        for (var i = 0; i < 10; i++) {
          final a = -math.pi / 2 + i * math.pi / 5;
          final d = i.isEven ? s * 1.05 : s * 0.45;
          final p = Offset(math.cos(a) * d, math.sin(a) * d + s * 0.06);
          i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
        path.close();
      case 2:
        path.addRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: s * 1.5, height: s * 1.5), Radius.circular(s * 0.22)));
      case 3:
        final w = s * 0.5;
        path
          ..addRRect(RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: s * 1.9, height: w), Radius.circular(w * 0.3)))
          ..addRRect(RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: w, height: s * 1.9), Radius.circular(w * 0.3)));
      default:
        path
          ..fillType = PathFillType.evenOdd
          ..addOval(Rect.fromCircle(center: Offset.zero, radius: s * 0.9))
          ..addOval(Rect.fromCircle(center: Offset.zero, radius: s * 0.5));
    }
    // A soft dark edge keeps white readable on the light yellow ball.
    canvas.drawPath(
        path.shift(Offset(0, r * 0.03)),
        Paint()
          ..color = const Color(0x40000000)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.05));
    canvas.drawPath(path, Paint()..color = const Color(0xF2FFFFFF));
  }

  /// A soft coloured glow, used when a group is about to pop.
  static void _paintHalo(Canvas canvas, double r, Color color) {
    canvas.drawCircle(
      Offset.zero,
      r * pad,
      Paint()
        ..shader = Gradient.radial(Offset.zero, r * pad, [
          color.withValues(alpha: 0.65),
          color.withValues(alpha: 0.25),
          color.withValues(alpha: 0),
        ], const [0.5, 0.72, 1.0]),
    );
  }
}
