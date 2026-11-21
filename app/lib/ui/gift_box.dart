import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/palette.dart';
import '../progress/cosmetics.dart';
import '../progress/rewards.dart';
import 'glass.dart';
import 'swatches.dart';
import 'type.dart';

/// A gift to open with a tap: it wobbles while waiting, shakes, pops its lid
/// in a burst of confetti, then shows exactly what was inside. The reward is
/// already in the player's account; opening only reveals it.
class GiftBox extends StatefulWidget {
  const GiftBox({
    super.key,
    required this.kind,
    required this.contents,
    required this.onOpen,
    this.duplicateCosmetic = false,
  });

  final GiftKind kind;
  final GiftContents contents;

  /// Plays the opening sound and vibration.
  final VoidCallback onOpen;
  final bool duplicateCosmetic;

  @override
  State<GiftBox> createState() => _GiftBoxState();
}

class _GiftBoxState extends State<GiftBox> with TickerProviderStateMixin {
  /// The waiting loop: a hop, a wiggle, then the hand taps.
  late final _idle = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();

  /// Slow turn of the light rays and sparkles behind the box.
  late final _glow = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  late final _open = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  bool _opened = false;

  bool get _special => widget.kind == GiftKind.special;

  @override
  void dispose() {
    _idle.dispose();
    _glow.dispose();
    _open.dispose();
    super.dispose();
  }

  void _tap() {
    if (_opened) return;
    setState(() => _opened = true);
    widget.onOpen();
    _open.forward();
  }

  @override
  Widget build(BuildContext context) {
    final boxColor = _special ? const Color(0xFF8B5CF6) : const Color(0xFFFF5C8A);
    // Gold ribbon and bow, so they show on the white card.
    const ribbon = Palette.gold;
    return GestureDetector(
      // The whole gift area opens it, not just the drawn box.
      behavior: HitTestBehavior.opaque,
      onTap: _tap,
      child: SizedBox(
        height: 160,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: Listenable.merge([_idle, _glow, _open]),
          builder: (context, _) {
            final t = _open.value;
            final i = _idle.value;
            // 0–0.3 shake, 0.3–0.55 lid flies, burst from 0.3, contents from 0.45.
            final shake = t < 0.3 ? math.sin(t / 0.3 * math.pi * 6) * 0.08 * (1 - t / 0.3) : 0.0;
            // Waiting: a hop (0–0.3), a wiggle (0.3–0.5), then rest.
            final hop = _opened || i > 0.3 ? 0.0 : math.sin(i / 0.3 * math.pi);
            final wiggle = _opened || i < 0.3 || i > 0.5 ? 0.0 : math.sin((i - 0.3) / 0.2 * math.pi * 3) * 0.09;
            // Squash on take-off and landing, stretch in the air.
            final squash = _opened ? 1.0 : (i < 0.04 || (i > 0.27 && i < 0.33) ? 0.92 : 1 + 0.05 * hop);
            final lift = Curves.easeOut.transform(((t - 0.3) / 0.25).clamp(0.0, 1.0));
            final boxFade = 1 - Curves.easeIn.transform(((t - 0.35) / 0.25).clamp(0.0, 1.0));
            final reveal = Curves.easeOutBack.transform(((t - 0.45) / 0.45).clamp(0.0, 1.0));
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Glow, turning rays and twinkles behind the box.
                if (boxFade > 0)
                  Positioned.fill(
                    child: Opacity(
                      opacity: boxFade,
                      child: CustomPaint(painter: _GlowPainter(_glow.value, boxColor, _special)),
                    ),
                  ),
                if (t > 0.3)
                  Positioned.fill(
                    child: CustomPaint(painter: _BurstPainter(((t - 0.3) / 0.7).clamp(0.0, 1.0), _special)),
                  ),
                if (boxFade > 0)
                  Opacity(
                    opacity: boxFade,
                    child: Transform.translate(
                      offset: Offset(0, -16 * hop - 6),
                      child: Transform.rotate(
                        angle: shake + wiggle,
                        child: Transform(
                          alignment: Alignment.bottomCenter,
                          transform: Matrix4.diagonal3Values(2 - squash, squash, 1),
                          child: _box(boxColor, ribbon, lift),
                        ),
                      ),
                    ),
                  ),
                if (!_opened) ...[
                  // A hand taps the box, so it is clear what to do.
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 70,
                    child: IgnorePointer(child: Center(child: _hand(i))),
                  ),
                  Positioned(
                    bottom: 0,
                    child: Transform.scale(
                      scale: 1 + 0.06 * math.sin(i * math.pi * 2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [boxColor, Color.lerp(boxColor, Palette.gold, 0.45)!]),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(color: boxColor.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: Text(
                          _special ? 'Special gift! Tap to open' : 'Tap to open!',
                          style: PopType.of(14, 1000, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
                if (reveal > 0)
                  Transform.scale(
                    scale: reveal,
                    child: Opacity(opacity: reveal.clamp(0.0, 1.0), child: _contents()),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// A pointing hand beside the box that presses in once per loop, with a
  /// ripple where it taps.
  Widget _hand(double i) {
    // Moves in (0.5–0.7), presses (0.7–0.8), lifts away (0.8–1).
    final inT = Curves.easeOut.transform(((i - 0.5) / 0.2).clamp(0.0, 1.0));
    final press = i > 0.7 && i < 0.8 ? math.sin((i - 0.7) / 0.1 * math.pi) : 0.0;
    final out = ((i - 0.85) / 0.15).clamp(0.0, 1.0);
    final ripple = ((i - 0.72) / 0.25).clamp(0.0, 1.0);
    final visible = (inT - out).clamp(0.0, 1.0);
    return SizedBox(
      width: 150,
      height: 60,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (ripple > 0 && ripple < 1)
            Positioned(
              left: 52 - 18 * ripple,
              top: -4 - 18 * ripple,
              child: Container(
                width: 36 * ripple + 8,
                height: 36 * ripple + 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Palette.accent.withValues(alpha: 0.9 * (1 - ripple)), width: 3),
                ),
              ),
            ),
          Positioned(
            left: 62 + 26 * (1 - inT),
            top: 4 + 14 * (1 - inT) + 5 * press,
            child: Opacity(
              opacity: visible,
              child: Transform.scale(
                scale: 1 - 0.12 * press,
                child: Icon(
                  Icons.touch_app_rounded,
                  size: 40,
                  color: Palette.accent,
                  shadows: const [
                    Shadow(color: Colors.white, blurRadius: 4),
                    Shadow(color: Color(0x55000000), blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _box(Color body, Color ribbon, double lift) {
    const w = 88.0;
    final dark = Color.lerp(body, Colors.black, 0.18)!;
    final light = Color.lerp(body, Colors.white, 0.25)!;
    return SizedBox(
      width: w + 16,
      height: 112,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Soft shadow on the card.
          Positioned(
            bottom: 12,
            child: Container(
              width: w * 0.9,
              height: 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: body.withValues(alpha: 0.45), blurRadius: 12, spreadRadius: 1)],
              ),
            ),
          ),
          // Body: polka dots, a ribbon with a shine, and a sheen sweeping across.
          Positioned(
            bottom: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: w,
                height: 64,
                child: CustomPaint(painter: _BoxPainter(body, light, dark, ribbon, _glow.value)),
              ),
            ),
          ),
          // Lid and bow, which fly up when opened.
          Positioned(
            bottom: 74 + lift * 46,
            child: Opacity(
              opacity: 1 - lift,
              child: Transform.rotate(
                angle: -0.4 * lift,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _loop(ribbon, -0.5),
                        Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.only(bottom: 2),
                          decoration: const BoxDecoration(color: Color(0xFFFFB000), shape: BoxShape.circle),
                        ),
                        _loop(ribbon, 0.5),
                      ],
                    ),
                    Container(
                      width: w + 12,
                      height: 22,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color.lerp(body, Colors.white, 0.3)!, body],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 2))],
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: 16,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [Color(0xFFFFE17A), Palette.gold, Color(0xFFFFB000)]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loop(Color color, double tilt) => Transform.rotate(
        angle: tilt,
        child: Container(
          width: 28,
          height: 20,
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 6),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 3, offset: Offset(0, 1))],
          ),
        ),
      );

  Widget _contents() {
    final cosmetic = widget.contents.cosmetic;
    final coins = widget.contents.coins + (widget.duplicateCosmetic ? LevelRewards.duplicateCosmeticCoins : 0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _special ? Palette.accent : Palette.gold, width: 2.5),
        boxShadow: [BoxShadow(color: Palette.panelShadow, blurRadius: 14, offset: Offset(0, 5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (cosmetic != null && !widget.duplicateCosmetic) ...[
            CosmeticSwatch(cosmetic: cosmetic, height: 34),
            const SizedBox(height: 6),
            Text(
              switch (cosmetic.kind) {
                CosmeticKind.balls => 'New balls: ${cosmetic.name}!',
                CosmeticKind.shape => 'New shapes: ${cosmetic.name}!',
                CosmeticKind.sky => 'New sky: ${cosmetic.name}!',
              },
              style: PopType.of(16, 1000, color: Palette.accent),
            ),
            const SizedBox(height: 4),
          ],
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CoinIcon(size: 26),
              const SizedBox(width: 6),
              Text('+$coins coins', style: PopType.of(20, 1000, numbers: true)),
            ],
          ),
        ],
      ),
    );
  }
}

//// The gift's body: a gradient, polka dots, a gold ribbon with a shine,
/// and a sheen that sweeps across now and then ([t], 0–1 looping).
class _BoxPainter extends CustomPainter {
  _BoxPainter(this.body, this.light, this.dark, this.ribbon, this.t);
  final Color body, light, dark, ribbon;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [light, body, dark],
          stops: const [0, 0.45, 1],
        ).createShader(rect),
    );
    // Polka dots.
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.32);
    for (var y = 0; y < 4; y++) {
      for (var x = 0; x < 6; x++) {
        final c = Offset(8 + x * 16 + (y.isOdd ? 8 : 0), 8 + y * 16);
        canvas.drawCircle(c, 3.2, dot);
      }
    }
    // Ribbon down the middle, with a bright edge.
    final r = Rect.fromCenter(center: rect.center, width: 16, height: size.height);
    canvas.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFFFFE17A), Palette.gold, Color(0xFFFFB000)])
            .createShader(r),
    );
    // The sheen: a soft diagonal band crossing once per loop.
    final x = -size.width * 0.6 + (t * 4 % 1) * size.width * 2.2;
    canvas.save();
    canvas.translate(x, 0);
    canvas.skew(-0.5, 0);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, 14, size.height),
      Paint()..color = Colors.white.withValues(alpha: 0.28),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BoxPainter old) => old.t != t || old.body != body;
}

/// A warm glow behind the waiting gift, slowly turning light rays (more of
/// them, in gold, for a special gift) and twinkling sparkles.
class _GlowPainter extends CustomPainter {
  _GlowPainter(this.t, this.color, this.special);
  final double t;
  final Color color;
  final bool special;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.42);
    final r = size.height * 0.62;
    final pulse = 0.85 + 0.15 * math.sin(t * math.pi * 2 * 6);
    canvas.drawCircle(
      c,
      r * pulse,
      Paint()
        ..shader = RadialGradient(
          colors: [
            (special ? Palette.gold : color).withValues(alpha: 0.35),
            (special ? Palette.gold : color).withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: c, radius: r * pulse)),
    );
    final rays = special ? 14 : 10;
    final ray = Paint()
      ..shader = RadialGradient(
        colors: [
          (special ? const Color(0xFFFFD54A) : Colors.white).withValues(alpha: special ? 0.5 : 0.4),
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(t * math.pi * 2);
    for (var i = 0; i < rays; i++) {
      final a = i * math.pi * 2 / rays;
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(math.cos(a - 0.09) * r, math.sin(a - 0.09) * r)
          ..lineTo(math.cos(a + 0.09) * r, math.sin(a + 0.09) * r)
          ..close(),
        ray,
      );
    }
    canvas.restore();
    // Sparkles that twinkle in turn around the box.
    final star = Paint()..color = special ? Palette.gold : Colors.white;
    for (var i = 0; i < 7; i++) {
      final a = i * 2.4 + 0.6;
      final p = c + Offset(math.cos(a) * r * 0.78, math.sin(a) * r * 0.55);
      final tw = math.sin(t * math.pi * 2 * 5 + i * 1.7);
      if (tw <= 0) continue;
      final s = 3 + 5 * tw;
      final path = Path();
      for (var k = 0; k < 8; k++) {
        final ang = k * math.pi / 4;
        final rr = k.isEven ? s : s * 0.3;
        final q = p + Offset(math.cos(ang) * rr, math.sin(ang) * rr);
        k == 0 ? path.moveTo(q.dx, q.dy) : path.lineTo(q.dx, q.dy);
      }
      star.color = (special ? Palette.gold : Colors.white).withValues(alpha: tw);
      canvas.drawPath(path..close(), star);
    }
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.t != t;
}

// Confetti and a soft ring bursting out of the opened gift.
class _BurstPainter extends CustomPainter {
  _BurstPainter(this.t, this.special);
  final double t;
  final bool special;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.5);
    final random = math.Random(7);
    final colors = [...Palette.balls, Palette.gold];
    final fade = (1 - t).clamp(0.0, 1.0);
    // A soft ring.
    canvas.drawCircle(
      center,
      20 + 90 * Curves.easeOut.transform(t),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6 * fade
        ..color = (special ? Palette.accent : Palette.gold).withValues(alpha: 0.5 * fade),
    );
    final paint = Paint();
    final count = special ? 46 : 30;
    for (var i = 0; i < count; i++) {
      final angle = random.nextDouble() * math.pi * 2;
      final speed = 90 + random.nextDouble() * 120;
      final spin = random.nextDouble() * 8;
      final p = center + Offset(math.cos(angle), math.sin(angle) - 0.6) * speed * t + Offset(0, 160 * t * t);
      paint.color = colors[i % colors.length].withValues(alpha: fade);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(spin * t * math.pi);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 9, height: 5), const Radius.circular(2)),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}
