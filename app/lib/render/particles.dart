import 'dart:math' as math;
import 'dart:ui';

enum _Kind { spark, shard, ring }

class _Particle {
  _Kind kind = _Kind.spark;
  bool active = false;
  double x = 0, y = 0, vx = 0, vy = 0;
  double age = 0, life = 1;
  double size = 1, endSize = 0;
  double angle = 0, spin = 0;
  Color color = const Color(0xFFFFFFFF);
}

/// A fixed pool of short-lived effects (sparks, shell shards, light rings).
/// Nothing is allocated while playing; if the pool is full, new effects are
/// skipped rather than slowing the game down.
class ParticleSystem {
  ParticleSystem({int capacity = 320})
      : _pool = List.generate(capacity, (_) => _Particle());

  final List<_Particle> _pool;
  final _random = math.Random();
  final _paint = Paint();
  final _stroke = Paint()..style = PaintingStyle.stroke;

  /// Units per second are scaled by [cell] so effects look the same on
  /// every screen size.
  double cell = 40;

  _Particle? _take() {
    for (final p in _pool) {
      if (!p.active) return p..active = true;
    }
    return null;
  }

  /// A small burst of sparks in [color] from a popped orb.
  void burst(Offset at, Color color, {int count = 6}) {
    for (var i = 0; i < count; i++) {
      final p = _take();
      if (p == null) return;
      final angle = _random.nextDouble() * math.pi * 2;
      final speed = cell * (2.2 + _random.nextDouble() * 2.6);
      p
        ..kind = _Kind.spark
        ..x = at.dx
        ..y = at.dy
        ..vx = math.cos(angle) * speed
        ..vy = math.sin(angle) * speed - cell * 1.5
        ..age = 0
        ..life = 0.32 + _random.nextDouble() * 0.2
        ..size = cell * (0.07 + _random.nextDouble() * 0.05)
        ..endSize = 0
        ..color = color;
    }
  }

  /// Glass fragments from a cracked shell.
  void shards(Offset at) {
    for (var i = 0; i < 5; i++) {
      final p = _take();
      if (p == null) return;
      final angle = -math.pi / 2 + (_random.nextDouble() - 0.5) * 2.6;
      final speed = cell * (1.6 + _random.nextDouble() * 1.6);
      p
        ..kind = _Kind.shard
        ..x = at.dx + math.cos(angle) * cell * 0.3
        ..y = at.dy + math.sin(angle) * cell * 0.3
        ..vx = math.cos(angle) * speed
        ..vy = math.sin(angle) * speed
        ..age = 0
        ..life = 0.4 + _random.nextDouble() * 0.15
        ..size = cell * (0.10 + _random.nextDouble() * 0.06)
        ..angle = _random.nextDouble() * math.pi
        ..spin = (_random.nextDouble() - 0.5) * 14
        ..color = const Color(0xD9E4E9FF);
    }
  }

  /// An expanding ring of light, e.g. around a popped group.
  void ring(Offset at, Color color, {double from = 0.3, double to = 1.3, double life = 0.32}) {
    final p = _take();
    if (p == null) return;
    p
      ..kind = _Kind.ring
      ..x = at.dx
      ..y = at.dy
      ..vx = 0
      ..vy = 0
      ..age = 0
      ..life = life
      ..size = cell * from
      ..endSize = cell * to
      ..color = color;
  }

  void update(double dt) {
    final gravity = cell * 9;
    for (final p in _pool) {
      if (!p.active) continue;
      p.age += dt;
      if (p.age >= p.life) {
        p.active = false;
        continue;
      }
      if (p.kind != _Kind.ring) {
        p
          ..vy += gravity * dt
          ..vx *= 1 - 2.5 * dt
          ..x += p.vx * dt
          ..y += p.vy * dt
          ..angle += p.spin * dt;
      }
    }
  }

  void render(Canvas canvas) {
    for (final p in _pool) {
      if (!p.active) continue;
      final t = p.age / p.life;
      switch (p.kind) {
        case _Kind.spark:
          _paint.color = p.color.withValues(alpha: 1 - t);
          canvas.drawCircle(Offset(p.x, p.y), p.size + (p.endSize - p.size) * t, _paint);
        case _Kind.shard:
          _paint.color = p.color.withValues(alpha: p.color.a * (1 - t));
          canvas.save();
          canvas.translate(p.x, p.y);
          canvas.rotate(p.angle);
          canvas.drawPath(
            Path()
              ..moveTo(0, -p.size)
              ..lineTo(p.size * 0.5, p.size * 0.6)
              ..lineTo(-p.size * 0.4, p.size * 0.4)
              ..close(),
            _paint,
          );
          canvas.restore();
        case _Kind.ring:
          final eased = 1 - (1 - t) * (1 - t);
          _stroke
            ..strokeWidth = cell * 0.08 * (1 - t)
            ..color = p.color.withValues(alpha: 0.7 * (1 - t));
          canvas.drawCircle(Offset(p.x, p.y), p.size + (p.endSize - p.size) * eased, _stroke);
      }
    }
  }
}
