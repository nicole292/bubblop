import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart' show TextPainter, TextSpan, TextStyle, TextDirection;
import 'package:flutter/widgets.dart' show WidgetsBinding;

import '../game/palette.dart';

class _Bubble {
  double x = 0, y = 0, r = 10, speed = 10, phase = 0;
}

/// The bright sky behind everything: a cheerful gradient, a few large soft
/// colour blobs, a barely visible pattern of the maker's name, and bubbles
/// floating slowly upward. Calm enough not to compete with the board.
class SkyBackground {
  final _random = math.Random(7);
  Size _size = Size.zero;
  Image? _blobs;
  Image? _signature;
  Paint? _gradient;
  final List<_Bubble> _bubbles = [];
  final _blobPaint = Paint()..filterQuality = FilterQuality.medium;
  final _bubbleFill = Paint();
  final _bubbleRim = Paint()..style = PaintingStyle.stroke;
  double _time = 0;

  void resize(Size size) {
    if (size == _size || size.isEmpty) return;
    _size = size;
    _gradient = Paint()
      ..shader = Gradient.linear(Offset.zero, Offset(size.width * 0.3, size.height),
          const [Palette.skyTop, Palette.skyMid, Palette.skyBottom], const [0, 0.5, 1]);
    _blobs?.dispose();
    _blobs = _bakeBlobs(size);
    _signature?.dispose();
    _signature = _bakeSignature(size);
    _bubbles.clear();
    for (var i = 0; i < 6; i++) {
      _bubbles.add(_reset(_Bubble(), anywhere: true));
    }
  }

  _Bubble _reset(_Bubble b, {bool anywhere = false}) {
    final r = 5 + math.pow(_random.nextDouble(), 2) * 16;
    return b
      ..r = r.toDouble()
      ..x = _random.nextDouble() * _size.width
      ..y = anywhere ? _random.nextDouble() * _size.height : _size.height + r + 10
      ..speed = 8 + _random.nextDouble() * 14
      ..phase = _random.nextDouble() * math.pi * 2;
  }

  void update(double dt) {
    _time += dt;
    for (final b in _bubbles) {
      b.y -= b.speed * dt;
      if (b.y < -b.r - 10) _reset(b);
    }
  }

  void render(Canvas canvas) {
    if (_size.isEmpty) return;
    canvas.drawRect(Offset.zero & _size, _gradient!);

    final blobs = _blobs;
    if (blobs != null) {
      final drift = Offset(math.sin(_time * 0.07) * 14, math.cos(_time * 0.05) * 10);
      canvas.drawImageRect(blobs, Rect.fromLTWH(0, 0, blobs.width.toDouble(), blobs.height.toDouble()),
          (Offset.zero & _size).inflate(24).shift(drift), _blobPaint);
    }

    final signature = _signature;
    if (signature != null) {
      canvas.drawImageRect(signature, Rect.fromLTWH(0, 0, signature.width.toDouble(), signature.height.toDouble()),
          Offset.zero & _size, _blobPaint);
    }

    for (final b in _bubbles) {
      final c = Offset(b.x + math.sin(_time * 0.8 + b.phase) * 8, b.y);
      _bubbleFill.color = const Color(0x14FFFFFF);
      canvas.drawCircle(c, b.r, _bubbleFill);
      _bubbleRim
        ..strokeWidth = math.max(1, b.r * 0.08)
        ..color = const Color(0x38FFFFFF);
      canvas.drawCircle(c, b.r, _bubbleRim);
      _bubbleFill.color = const Color(0x66FFFFFF);
      canvas.drawCircle(c.translate(-b.r * 0.35, -b.r * 0.35), b.r * 0.18, _bubbleFill);
    }
  }

  /// Big soft patches of colour, rendered once at quarter resolution.
  Image _bakeBlobs(Size size) {
    const scale = 0.25;
    final w = math.max(1, (size.width * scale).round());
    final h = math.max(1, (size.height * scale).round());
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    void blob(double fx, double fy, double radius, Color color) {
      final c = Offset(fx * w, fy * h);
      final r = radius * w;
      canvas.drawCircle(c, r, Paint()..shader = Gradient.radial(c, r, [color, color.withValues(alpha: 0)]));
    }

    blob(0.05, 0.08, 0.75, const Color(0x55FFFFFF));
    blob(1.0, 0.30, 0.7, const Color(0x40FF8FD1));
    blob(0.0, 0.75, 0.8, const Color(0x3D6CF0E0));
    blob(0.95, 0.95, 0.7, const Color(0x40FFB36B));
    final picture = recorder.endRecording();
    final image = picture.toImageSync(w, h);
    picture.dispose();
    return image;
  }

  /// "elishakov" repeated in slanted rows, white at 6%: there if you look,
  /// invisible if you don't. Rendered once per screen size, at full
  /// resolution so the letters stay crisp.
  Image _bakeSignature(Size size) {
    final ratio = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder)..scale(ratio);
    final word = TextPainter(
      text: const TextSpan(
        text: 'elishakov',
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 15,
          fontVariations: [FontVariation('wght', 900)],
          letterSpacing: 1.5,
          color: Color(0x10FFFFFF),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-0.35);
    final reach = size.longestSide;
    final stepX = word.width + 34;
    const stepY = 46.0;
    for (var row = 0, y = -reach; y < reach; row++, y += stepY) {
      // Every other row shifts by half a word, like bricks.
      for (var x = -reach + (row.isOdd ? stepX / 2 : 0); x < reach; x += stepX) {
        word.paint(canvas, Offset(x, y));
      }
    }
    canvas.restore();
    final picture = recorder.endRecording();
    final image = picture.toImageSync(math.max(1, (size.width * ratio).ceil()), math.max(1, (size.height * ratio).ceil()));
    picture.dispose();
    return image;
  }

  void dispose() {
    _blobs?.dispose();
    _signature?.dispose();
  }
}
