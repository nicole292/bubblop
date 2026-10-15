import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart'
    show TextPainter, TextSpan, TextStyle, TextDirection;

enum _Kind { confetti, star, ring, puff, label }

class _Fx {
  _Kind kind = _Kind.confetti;
  bool active = false;
  double x = 0, y = 0, vx = 0, vy = 0;
  double age = 0, life = 1;
  double size = 1, endSize = 1;
  double angle = 0, spin = 0;
  bool round = true;
  Color color = const Color(0xFFFFFFFF);
  TextPainter? fill;
  TextPainter? outline;
}

/// All transient effects, in a playful "confetti" style suited to a bright
/// board: coloured confetti bits, twinkling star sparkles, soft rings, little
/// puffs and bubbly floating text.
///
/// Everything comes from a fixed pool; when it is full, new effects are
/// skipped rather than slowing the game down. An effect can start after a
/// delay (used for the sparkle trail between chain steps).
class Effects {
  Effects({int capacity = 900}) : _pool = List.generate(capacity, (_) => _Fx());

  final List<_Fx> _pool;
  int _cursor = 0;
  final _random = math.Random();

  /// Effect sizes and speeds are in cells so they scale with the screen.
  double cell = 40;

  final _paint = Paint();
  final _stroke = Paint()..style = PaintingStyle.stroke;

  /// A 4-point sparkle of radius 1, scaled when drawn.
  static final _starPath = () {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final a = -math.pi / 2 + i * math.pi / 4;
      final r = i.isEven ? 1.0 : 0.28;
      final p = Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }();

  int get activeCount => _pool.where((p) => p.active).length;

  _Fx? _take({double delay = 0}) {
    for (var i = 0; i < _pool.length; i++) {
      final p = _pool[(_cursor + i) % _pool.length];
      if (!p.active) {
        _cursor = (_cursor + i + 1) % _pool.length;
        return p
          ..active = true
          ..age = -delay
          ..vx = 0
          ..vy = 0
          ..spin = 0
          ..angle = 0
          ..fill = null
          ..outline = null;
      }
    }
    return null;
  }

  /// Confetti thrown up and out in [color] (and a lighter tint of it).
  void confetti(Offset at, Color color, {int count = 8, double power = 1}) {
    final light = Color.lerp(color, const Color(0xFFFFFFFF), 0.45)!;
    for (var i = 0; i < count; i++) {
      final p = _take();
      if (p == null) return;
      final angle = -math.pi / 2 + (_random.nextDouble() - 0.5) * math.pi * 1.7;
      final speed = cell * (3.0 + _random.nextDouble() * 3.5) * (0.85 + 0.2 * power);
      p
        ..kind = _Kind.confetti
        ..x = at.dx
        ..y = at.dy
        ..vx = math.cos(angle) * speed
        ..vy = math.sin(angle) * speed
        ..life = 0.55 + _random.nextDouble() * 0.35
        ..size = cell * (0.08 + _random.nextDouble() * 0.07)
        ..angle = _random.nextDouble() * math.pi
        ..spin = (_random.nextDouble() - 0.5) * 18
        ..round = _random.nextBool()
        ..color = i.isEven ? color : light;
    }
  }

  /// A twinkling 4-point sparkle that pops in, spins a little and fades.
  void star(Offset at, {double size = 0.22, Color color = const Color(0xFFFFFFFF), double delay = 0, double life = 0.45}) {
    final p = _take(delay: delay);
    if (p == null) return;
    p
      ..kind = _Kind.star
      ..x = at.dx
      ..y = at.dy
      ..vy = -cell * 0.6
      ..life = life
      ..size = cell * size
      ..spin = (_random.nextDouble() - 0.5) * 3
      ..color = color;
  }

  /// A few sparkles scattered around a point.
  void sparkles(Offset at, {int count = 3, double spread = 0.6, Color color = const Color(0xFFFFFFFF)}) {
    for (var i = 0; i < count; i++) {
      final offset = Offset((_random.nextDouble() - 0.5) * 2, (_random.nextDouble() - 0.5) * 2) * cell * spread;
      star(at + offset, size: 0.14 + _random.nextDouble() * 0.12, color: color, delay: _random.nextDouble() * 0.12);
    }
  }

  /// A soft coloured ring that expands to [to] cells (radius) and fades.
  void ring(Offset at, Color color, {double from = 0.35, double to = 1.2, double life = 0.4, double width = 0.16}) {
    final p = _take();
    if (p == null) return;
    p
      ..kind = _Kind.ring
      ..x = at.dx
      ..y = at.dy
      ..life = life
      ..size = from
      ..endSize = to
      ..angle = width
      ..color = color;
  }

  /// Small white puffs (landing dust, a shell's bubble popping).
  void puff(Offset at, {int count = 5, double spread = 0.4, double size = 0.12, Color color = const Color(0xFFFFFFFF)}) {
    for (var i = 0; i < count; i++) {
      final p = _take();
      if (p == null) return;
      final angle = (i / count) * math.pi * 2 + _random.nextDouble() * 0.6;
      final speed = cell * (1.2 + _random.nextDouble() * 1.4) * spread / 0.4;
      p
        ..kind = _Kind.puff
        ..x = at.dx + math.cos(angle) * cell * 0.25
        ..y = at.dy + math.sin(angle) * cell * 0.25
        ..vx = math.cos(angle) * speed
        ..vy = math.sin(angle) * speed
        ..life = 0.35 + _random.nextDouble() * 0.15
        ..size = cell * size * (0.7 + _random.nextDouble() * 0.6)
        ..color = color;
    }
  }

  /// A line of sparkles that appear one after another from [from] to [to].
  void trail(Offset from, Offset to, Color color, {int count = 7}) {
    for (var i = 0; i <= count; i++) {
      final t = i / count;
      final arc = math.sin(t * math.pi) * cell * 0.5;
      final at = Offset.lerp(from, to, t)!.translate(0, -arc);
      star(at, size: 0.16 + 0.06 * math.sin(t * math.pi), color: i.isEven ? color : const Color(0xFFFFFFFF),
          delay: t * 0.18, life: 0.4);
    }
  }

  /// Bubbly text: white letters with a coloured outline; pops in, rises, fades.
  void label(Offset at, String text, Color outline, {double size = 0.45, double life = 0.85, double rise = 0.9}) {
    final p = _take();
    if (p == null) return;
    TextPainter painter(Paint foreground) => TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: cell * size,
              fontVariations: const [FontVariation('wght', 900)],
              foreground: foreground,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
    p
      ..kind = _Kind.label
      ..x = at.dx
      ..y = at.dy
      ..life = life
      ..size = rise
      ..outline = painter(Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * size * 0.22
        ..strokeJoin = StrokeJoin.round
        ..color = outline)
      ..fill = painter(Paint()..color = const Color(0xFFFFFFFF));
  }

  /// Starts fading every floating label now (when newer ones arrive).
  void fadeLabels() {
    for (final p in _pool) {
      if (p.active && p.kind == _Kind.label) p.age = math.max(p.age, p.life * 0.88);
    }
  }

  void clear() {
    for (final p in _pool) {
      p
        ..active = false
        ..fill = null
        ..outline = null;
    }
  }

  void update(double dt) {
    final gravity = cell * 14;
    for (final p in _pool) {
      if (!p.active) continue;
      p.age += dt;
      if (p.age < 0) continue;
      if (p.age >= p.life) {
        p
          ..active = false
          ..fill = null
          ..outline = null;
        continue;
      }
      switch (p.kind) {
        case _Kind.confetti:
          p
            ..vy += gravity * dt
            ..vx *= 1 - 1.8 * dt;
        case _Kind.puff:
          p
            ..vx *= 1 - 5 * dt
            ..vy *= 1 - 5 * dt;
        case _Kind.star:
          p.vy *= 1 - 3 * dt;
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
    for (final p in _pool) {
      if (!p.active || p.age < 0) continue;
      final t = p.age / p.life;
      switch (p.kind) {
        case _Kind.confetti:
          final a = t < 0.7 ? 1.0 : 1 - (t - 0.7) / 0.3;
          _paint.color = p.color.withValues(alpha: a);
          canvas.save();
          canvas.translate(p.x, p.y);
          canvas.rotate(p.angle);
          if (p.round) {
            canvas.drawCircle(Offset.zero, p.size * 0.8, _paint);
          } else {
            // A little ribbon that flips as it spins.
            final flip = math.cos(p.angle * 2).abs() * 0.7 + 0.3;
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromCenter(center: Offset.zero, width: p.size * 2.2, height: p.size * 1.1 * flip),
                Radius.circular(p.size * 0.4),
              ),
              _paint,
            );
          }
          canvas.restore();
        case _Kind.star:
          // Pops in big, settles, then shrinks away.
          final s = t < 0.25 ? 1.3 * (t / 0.25) : 1.3 - 0.3 * ((t - 0.25) / 0.2).clamp(0.0, 1.0);
          final fade = t < 0.6 ? 1.0 : 1 - (t - 0.6) / 0.4;
          _paint.color = p.color.withValues(alpha: fade);
          canvas.save();
          canvas.translate(p.x, p.y);
          canvas.rotate(p.angle);
          canvas.scale(p.size * s * fade.clamp(0.4, 1.0));
          canvas.drawPath(_starPath, _paint);
          canvas.restore();
        case _Kind.ring:
          final k = 1 - math.pow(1 - t, 3).toDouble();
          final r = (p.size + (p.endSize - p.size) * k) * cell;
          _stroke
            ..strokeWidth = p.angle * cell * (1 - t)
            ..color = p.color.withValues(alpha: 0.75 * (1 - t));
          canvas.drawCircle(Offset(p.x, p.y), r, _stroke);
        case _Kind.puff:
          _paint.color = p.color.withValues(alpha: 0.9 * (1 - t));
          canvas.drawCircle(Offset(p.x, p.y), p.size * (1 + 0.6 * t), _paint);
        case _Kind.label:
          final fill = p.fill!;
          final outline = p.outline!;
          final pop = t < 0.12
              ? 0.5 + 0.75 * (t / 0.12)
              : t < 0.24
                  ? 1.25 - 0.25 * ((t - 0.12) / 0.12)
                  : 1.0;
          final rise = p.size * cell * (1 - math.pow(1 - t, 2).toDouble());
          final alpha = t < 0.65 ? 1.0 : 1 - (t - 0.65) / 0.35;
          if (alpha <= 0) break;
          canvas.save();
          canvas.translate(p.x, p.y - rise);
          canvas.scale(pop);
          canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, alpha));
          final offset = Offset(-outline.width / 2, -outline.height / 2);
          outline.paint(canvas, offset);
          fill.paint(canvas, offset);
          canvas.restore();
          canvas.restore();
      }
    }
  }
}
