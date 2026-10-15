import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart'
    show TextPainter, TextSpan, TextStyle, Shadow, TextDirection;

import '../game/palette.dart';
import 'orb_sprites.dart';

enum _Kind { flash, spark, mote, shard, ring, beam, text }

class _Fx {
  _Kind kind = _Kind.flash;
  bool active = false;
  double x = 0, y = 0, vx = 0, vy = 0;
  double x2 = 0, y2 = 0;
  double age = 0, life = 1;
  double size = 1, endSize = 1;
  double angle = 0, spin = 0;
  double strength = 1;

  /// Palette index, or -1 for white light.
  int color = -1;
  TextPainter? text;
}

/// All transient visual effects: light flashes, streak sparks, motes, glass
/// shards, shockwave rings, chain beams and floating text.
///
/// Light is drawn with additive blending from white sprites tinted per
/// colour, so overlapping effects brighten like real light instead of
/// stacking flat discs. Everything comes from a fixed pool; when it is full,
/// new effects are skipped rather than slowing the game down.
class Effects {
  Effects({int capacity = 900}) : _pool = List.generate(capacity, (_) => _Fx());

  final List<_Fx> _pool;
  int _cursor = 0;
  final _random = math.Random();

  OrbSprites? sprites;

  /// Effect sizes and speeds are in cells so they scale with the screen.
  double cell = 40;

  /// Additive paints tinted per palette colour; the last one is white.
  late final List<Paint> _light = [
    for (final c in [...Palette.orbs, const Color(0xFFFFFFFF)])
      Paint()
        ..blendMode = BlendMode.plus
        ..filterQuality = FilterQuality.low
        ..colorFilter = ColorFilter.mode(c, BlendMode.modulate),
  ];
  late final List<Paint> _beam = [
    for (final c in [...Palette.orbs, const Color(0xFFFFFFFF)])
      Paint()
        ..blendMode = BlendMode.plus
        ..strokeCap = StrokeCap.round
        ..color = c
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
  ];
  final _shardFill = Paint()..color = const Color(0x8CD8E2FF);
  final _shardEdge = Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0xE6FFFFFF);

  Paint _lightPaint(int color) => _light[color < 0 ? _light.length - 1 : color];

  int get activeCount => _pool.where((p) => p.active).length;

  _Fx? _take() {
    for (var i = 0; i < _pool.length; i++) {
      final p = _pool[(_cursor + i) % _pool.length];
      if (!p.active) {
        _cursor = (_cursor + i + 1) % _pool.length;
        return p
          ..active = true
          ..age = 0
          ..vx = 0
          ..vy = 0
          ..spin = 0
          ..angle = 0
          ..strength = 1
          ..text = null;
      }
    }
    return null;
  }

  /// A burst of light that swells and fades. [size] is in cells.
  void flash(Offset at, int color, {double size = 1.4, double life = 0.28, double strength = 1}) {
    final p = _take();
    if (p == null) return;
    p
      ..kind = _Kind.flash
      ..x = at.dx
      ..y = at.dy
      ..life = life
      ..size = size * 0.45
      ..endSize = size
      ..strength = strength
      ..color = color;
  }

  /// Streaks of light thrown outward; [power] scales speed and reach.
  void sparks(Offset at, int color, {int count = 6, double power = 1}) {
    for (var i = 0; i < count; i++) {
      final p = _take();
      if (p == null) return;
      final angle = _random.nextDouble() * math.pi * 2;
      final speed = cell * (3.0 + _random.nextDouble() * 4.0) * (0.8 + 0.25 * power);
      p
        ..kind = _Kind.spark
        ..x = at.dx
        ..y = at.dy
        ..vx = math.cos(angle) * speed
        ..vy = math.sin(angle) * speed - cell * 1.2
        ..life = 0.30 + _random.nextDouble() * 0.25
        ..size = 0.10 + _random.nextDouble() * 0.06
        // Every third spark burns white-hot, the rest in the orb's colour.
        ..color = i % 3 == 0 ? -1 : color;
    }
  }

  /// Soft motes of light that drift upward after a pop.
  void motes(Offset at, int color, {int count = 2}) {
    for (var i = 0; i < count; i++) {
      final p = _take();
      if (p == null) return;
      p
        ..kind = _Kind.mote
        ..x = at.dx + (_random.nextDouble() - 0.5) * cell * 0.6
        ..y = at.dy + (_random.nextDouble() - 0.5) * cell * 0.6
        ..vx = (_random.nextDouble() - 0.5) * cell * 0.6
        ..vy = -cell * (0.8 + _random.nextDouble() * 0.9)
        ..life = 0.7 + _random.nextDouble() * 0.5
        ..size = 0.18 + _random.nextDouble() * 0.16
        ..angle = _random.nextDouble() * math.pi * 2
        ..color = color;
    }
  }

  /// Frosted glass pieces breaking off a shell, mostly away from [awayFrom].
  void shards(Offset at, {double awayFrom = 0, int count = 9}) {
    for (var i = 0; i < count; i++) {
      final p = _take();
      if (p == null) return;
      final spread = (_random.nextDouble() - 0.5) * 3.4;
      final angle = awayFrom + math.pi + spread;
      final speed = cell * (2.0 + _random.nextDouble() * 2.6);
      p
        ..kind = _Kind.shard
        ..x = at.dx + math.cos(angle) * cell * 0.32
        ..y = at.dy + math.sin(angle) * cell * 0.32
        ..vx = math.cos(angle) * speed
        ..vy = math.sin(angle) * speed - cell * 1.6
        ..life = 0.45 + _random.nextDouble() * 0.2
        ..size = 0.08 + _random.nextDouble() * 0.09
        ..angle = _random.nextDouble() * math.pi * 2
        ..spin = (_random.nextDouble() - 0.5) * 16
        ..color = -1;
    }
  }

  /// A soft shockwave expanding to [to] cells.
  void ring(Offset at, int color, {double from = 0.4, double to = 1.6, double life = 0.38, double strength = 1}) {
    final p = _take();
    if (p == null) return;
    p
      ..kind = _Kind.ring
      ..x = at.dx
      ..y = at.dy
      ..life = life
      ..size = from
      ..endSize = to
      ..strength = strength
      ..color = color;
  }

  /// Light running from one chain step's pop to the next.
  void beam(Offset from, Offset to, int color) {
    final p = _take();
    if (p == null) return;
    p
      ..kind = _Kind.beam
      ..x = from.dx
      ..y = from.dy
      ..x2 = to.dx
      ..y2 = to.dy
      ..life = 0.42
      ..color = color;
  }

  /// Floating text (score, combo) that pops in, rises and fades.
  void label(Offset at, String text, Color color, {double size = 0.45, double life = 0.85, double rise = 0.9}) {
    final p = _take();
    if (p == null) return;
    p
      ..kind = _Kind.text
      ..x = at.dx
      ..y = at.dy
      ..life = life
      ..size = rise
      ..text = (TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: cell * size,
            fontVariations: const [FontVariation('wght', 800)],
            color: color,
            shadows: [
              Shadow(blurRadius: cell * 0.25, color: const Color(0xCC000000)),
              Shadow(blurRadius: cell * 0.4, color: color.withValues(alpha: 0.6)),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout());
  }

  /// Starts fading every floating label now (when newer ones arrive).
  void fadeLabels() {
    for (final p in _pool) {
      if (p.active && p.kind == _Kind.text) p.age = math.max(p.age, p.life * 0.75);
    }
  }

  void clear() {
    for (final p in _pool) {
      p
        ..active = false
        ..text = null;
    }
  }

  void update(double dt) {
    final gravity = cell * 10;
    for (final p in _pool) {
      if (!p.active) continue;
      p.age += dt;
      if (p.age >= p.life) {
        p
          ..active = false
          ..text = null;
        continue;
      }
      switch (p.kind) {
        case _Kind.spark:
          p
            ..vy += gravity * 0.55 * dt
            ..vx *= 1 - 3.0 * dt
            ..vy *= 1 - 1.5 * dt;
        case _Kind.shard:
          p.vy += gravity * dt;
          p.vx *= 1 - 1.2 * dt;
        case _Kind.mote:
          p.vx += math.sin(p.angle + p.age * 4) * cell * 0.8 * dt;
        default:
          break;
      }
      p
        ..x += p.vx * dt
        ..y += p.vy * dt
        ..angle += p.spin * dt;
    }
  }

  void render(Canvas canvas) {
    final sprites = this.sprites;
    if (sprites == null) return;
    // Scale factor that makes a sprite exactly one cell across.
    final unit = cell / (sprites.radius * OrbSprites.pad * 2);
    for (final p in _pool) {
      if (!p.active) continue;
      final t = p.age / p.life;
      switch (p.kind) {
        case _Kind.flash:
          final k = 1 - (1 - t) * (1 - t);
          final s = (p.size + (p.endSize - p.size) * k) * unit;
          sprites.draw(canvas, sprites.bloom, Offset(p.x, p.y),
              sx: s, sy: s, alpha: math.pow(1 - t, 1.6) * p.strength, paint: _lightPaint(p.color));
        case _Kind.spark:
          final speed = math.sqrt(p.vx * p.vx + p.vy * p.vy);
          final length = (p.size * cell + speed * 0.045) / cell;
          canvas.save();
          canvas.translate(p.x, p.y);
          canvas.rotate(math.atan2(p.vy, p.vx));
          sprites.draw(canvas, sprites.bloom, Offset.zero,
              sx: length * unit * 2.4, sy: p.size * unit * 2.4, alpha: 1 - t * t, paint: _lightPaint(p.color));
          canvas.restore();
        case _Kind.mote:
          final a = math.sin(math.pi * t) * 0.75;
          final s = p.size * unit * 2.5;
          sprites.draw(canvas, sprites.bloom, Offset(p.x, p.y), sx: s, sy: s, alpha: a, paint: _lightPaint(p.color));
        case _Kind.shard:
          final s = p.size * cell;
          final a = 1 - t;
          canvas.save();
          canvas.translate(p.x, p.y);
          canvas.rotate(p.angle);
          final path = Path()
            ..moveTo(0, -s)
            ..lineTo(s * 0.75, s * 0.35)
            ..lineTo(-s * 0.2, s * 0.8)
            ..lineTo(-s * 0.7, 0)
            ..close();
          _shardFill.color = Color.fromRGBO(216, 226, 255, 0.55 * a);
          canvas.drawPath(path, _shardFill);
          _shardEdge
            ..strokeWidth = math.max(1, s * 0.18)
            ..color = Color.fromRGBO(255, 255, 255, 0.9 * a);
          canvas.drawLine(Offset(0, -s), Offset(s * 0.75, s * 0.35), _shardEdge);
          canvas.restore();
        case _Kind.ring:
          final k = 1 - math.pow(1 - t, 3).toDouble();
          final s = (p.size + (p.endSize - p.size) * k) * unit * 2 / 0.88;
          sprites.draw(canvas, sprites.ring, Offset(p.x, p.y),
              sx: s, sy: s, alpha: (1 - t) * 0.9 * p.strength, paint: _lightPaint(p.color));
        case _Kind.beam:
          // The head travels in the first half, then the trail fades.
          final head = math.min(1.0, t / 0.45);
          final fade = t < 0.45 ? 1.0 : 1 - (t - 0.45) / 0.55;
          final from = Offset(p.x, p.y);
          final to = Offset.lerp(from, Offset(p.x2, p.y2), _easeOut(head))!;
          final paint = _beam[p.color < 0 ? _beam.length - 1 : p.color];
          paint
            ..strokeWidth = cell * 0.22
            ..color = paint.color.withValues(alpha: 0.85 * fade);
          canvas.drawLine(from, to, paint);
          final white = _beam.last
            ..strokeWidth = cell * 0.07
            ..color = Color.fromRGBO(255, 255, 255, 0.9 * fade);
          canvas.drawLine(from, to, white);
          final s = 1.6 * unit;
          sprites.draw(canvas, sprites.bloom, to, sx: s, sy: s, alpha: fade, paint: _lightPaint(p.color));
        case _Kind.text:
          final painter = p.text!;
          final pop = t < 0.12
              ? 0.6 + 0.6 * (t / 0.12)
              : t < 0.22
                  ? 1.2 - 0.2 * ((t - 0.12) / 0.1)
                  : 1.0;
          final rise = p.size * cell * (1 - math.pow(1 - t, 2).toDouble());
          final alpha = t < 0.6 ? 1.0 : 1 - (t - 0.6) / 0.4;
          if (alpha <= 0) break;
          canvas.save();
          canvas.translate(p.x, p.y - rise);
          canvas.scale(pop);
          canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, alpha));
          painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
          canvas.restore();
          canvas.restore();
      }
    }
  }
}

double _easeOut(double t) => 1 - (1 - t) * (1 - t);
