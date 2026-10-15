import 'dart:math' as math;
import 'dart:ui';

import '../game/palette.dart';
import 'orb_sprites.dart';

class _Star {
  _Star(this.x, this.y, this.size, this.phase, this.speed);
  final double x, y, size, phase, speed;
}

class _Mote {
  double x = 0, y = 0, size = 1, speed = 10, phase = 0;
  int color = 3;
}

/// The night sky behind everything: gradient, a slowly drifting nebula,
/// twinkling stars and a few motes of light rising past the board.
/// Quiet by design: it should feel alive without pulling the eye.
class NightBackground {
  final _random = math.Random(7);
  Size _size = Size.zero;
  Image? _nebula;
  Paint? _gradient;
  final List<_Star> _stars = [];
  final List<_Mote> _motes = [];
  final _starPaint = Paint();
  final _nebulaPaint = Paint()..filterQuality = FilterQuality.medium;
  late final List<Paint> _moteLight = [
    for (final c in Palette.orbs)
      Paint()
        ..blendMode = BlendMode.plus
        ..colorFilter = ColorFilter.mode(c, BlendMode.modulate),
  ];
  double _time = 0;

  void resize(Size size) {
    if (size == _size || size.isEmpty) return;
    _size = size;
    _gradient = Paint()
      ..shader = Gradient.linear(Offset.zero, Offset(0, size.height),
          const [Palette.backgroundTop, Palette.backgroundMid, Palette.backgroundBottom], const [0, 0.55, 1]);
    _nebula?.dispose();
    _nebula = _bakeNebula(size);

    _stars.clear();
    final count = (size.width * size.height / 5500).clamp(40, 140).round();
    for (var i = 0; i < count; i++) {
      _stars.add(_Star(
        _random.nextDouble() * size.width,
        _random.nextDouble() * size.height,
        0.5 + math.pow(_random.nextDouble(), 3) * 1.4,
        _random.nextDouble() * math.pi * 2,
        0.6 + _random.nextDouble() * 1.6,
      ));
    }

    _motes.clear();
    for (var i = 0; i < 12; i++) {
      _motes.add(_resetMote(_Mote(), anywhere: true));
    }
  }

  _Mote _resetMote(_Mote m, {bool anywhere = false}) {
    return m
      ..x = _random.nextDouble() * _size.width
      ..y = anywhere ? _random.nextDouble() * _size.height : _size.height + 40
      ..size = 0.5 + _random.nextDouble() * 1.2
      ..speed = 6 + _random.nextDouble() * 14
      ..phase = _random.nextDouble() * math.pi * 2
      ..color = _random.nextInt(Palette.orbs.length);
  }

  void update(double dt) {
    _time += dt;
    for (final m in _motes) {
      m.y -= m.speed * dt;
      if (m.y < -40) _resetMote(m);
    }
  }

  void render(Canvas canvas, OrbSprites? sprites, double cell) {
    if (_size.isEmpty) return;
    canvas.drawRect(Offset.zero & _size, _gradient!);

    final nebula = _nebula;
    if (nebula != null) {
      final src = Rect.fromLTWH(0, 0, nebula.width.toDouble(), nebula.height.toDouble());
      final drift = Offset(math.sin(_time * 0.05) * 18, math.cos(_time * 0.04) * 12);
      _nebulaPaint.color = const Color(0xFFFFFFFF);
      canvas.drawImageRect(nebula, src, (Offset.zero & _size).inflate(30).shift(drift), _nebulaPaint);
    }

    for (final s in _stars) {
      final twinkle = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(_time * s.speed + s.phase));
      _starPaint.color = Color.fromRGBO(220, 228, 255, 0.55 * twinkle);
      canvas.drawCircle(Offset(s.x, s.y), s.size * 0.6, _starPaint);
    }

    if (sprites != null) {
      final unit = cell / (sprites.radius * OrbSprites.pad * 2);
      for (final m in _motes) {
        final sway = math.sin(_time * 0.6 + m.phase) * 14;
        final s = m.size * unit * 1.6;
        sprites.draw(canvas, sprites.bloom, Offset(m.x + sway, m.y),
            sx: s, sy: s, alpha: 0.10 + 0.06 * math.sin(_time + m.phase), paint: _moteLight[m.color]);
      }
    }
  }

  /// Large soft clouds of colour, rendered once at quarter resolution.
  Image _bakeNebula(Size size) {
    const scale = 0.25;
    final w = math.max(1, (size.width * scale).round());
    final h = math.max(1, (size.height * scale).round());
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    void cloud(double fx, double fy, double radius, Color color) {
      final c = Offset(fx * w, fy * h);
      final r = radius * w;
      canvas.drawCircle(c, r, Paint()..shader = Gradient.radial(c, r, [color, color.withValues(alpha: 0)]));
    }

    cloud(0.15, 0.18, 0.9, const Color(0x403A2A8C));
    cloud(0.95, 0.35, 0.8, const Color(0x331B5A8C));
    cloud(0.30, 0.70, 1.0, const Color(0x2E5B2A86));
    cloud(0.85, 0.85, 0.7, const Color(0x261E6E7A));
    cloud(0.55, 0.45, 0.6, const Color(0x1F2D3FA0));
    final picture = recorder.endRecording();
    final image = picture.toImageSync(w, h);
    picture.dispose();
    return image;
  }

  void dispose() => _nebula?.dispose();
}
