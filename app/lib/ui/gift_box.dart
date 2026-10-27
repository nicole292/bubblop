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
  late final _idle = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
  late final _open = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  bool _opened = false;

  bool get _special => widget.kind == GiftKind.special;

  @override
  void dispose() {
    _idle.dispose();
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
    final boxColor = _special ? Palette.accent : const Color(0xFFFF6B8B);
    // Gold ribbon and bow, so they show on the white card.
    const ribbon = Palette.gold;
    return GestureDetector(
      // The whole gift area opens it, not just the drawn box.
      behavior: HitTestBehavior.opaque,
      onTap: _tap,
      child: SizedBox(
        height: 150,
        width: double.infinity,
        child: AnimatedBuilder(
          animation: Listenable.merge([_idle, _open]),
          builder: (context, _) {
            final t = _open.value;
            // 0–0.3 shake, 0.3–0.55 lid flies, burst from 0.3, contents from 0.45.
            final shake = t < 0.3 ? math.sin(t / 0.3 * math.pi * 6) * 0.08 * (1 - t / 0.3) : 0.0;
            final idle = _opened ? 0.0 : math.sin(_idle.value * math.pi * 2) * 0.04;
            final lift = Curves.easeOut.transform(((t - 0.3) / 0.25).clamp(0.0, 1.0));
            final boxFade = 1 - Curves.easeIn.transform(((t - 0.35) / 0.25).clamp(0.0, 1.0));
            final reveal = Curves.easeOutBack.transform(((t - 0.45) / 0.45).clamp(0.0, 1.0));
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (t > 0.3)
                  Positioned.fill(
                    child: CustomPaint(painter: _BurstPainter(((t - 0.3) / 0.7).clamp(0.0, 1.0), _special)),
                  ),
                if (boxFade > 0)
                  Opacity(
                    opacity: boxFade,
                    child: Transform.rotate(
                      angle: shake + idle,
                      child: _box(boxColor, ribbon, lift),
                    ),
                  ),
                if (!_opened)
                  Positioned(
                    bottom: 0,
                    child: Text(
                      _special ? 'Special gift! Tap to open' : 'Tap to open!',
                      style: PopType.of(14, 900, color: _special ? Palette.accent : Palette.inkSoft),
                    ),
                  ),
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

  Widget _box(Color body, Color ribbon, double lift) {
    const w = 84.0;
    return SizedBox(
      width: w + 16,
      height: 110,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Body with a vertical ribbon.
          Positioned(
            bottom: 18,
            child: Container(
              width: w,
              height: 62,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [body, Color.lerp(body, Colors.black, 0.12)!],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: body.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 6))],
              ),
              alignment: Alignment.center,
              child: Container(width: 16, color: ribbon),
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
                      children: [
                        _loop(ribbon, -0.5),
                        const SizedBox(width: 2),
                        _loop(ribbon, 0.5),
                      ],
                    ),
                    Container(
                      width: w + 12,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Color.lerp(body, Colors.white, 0.18),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 4, offset: Offset(0, 2))],
                      ),
                      alignment: Alignment.center,
                      child: Container(width: 16, color: ribbon),
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
          width: 26,
          height: 18,
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 6),
            borderRadius: BorderRadius.circular(12),
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
        boxShadow: const [BoxShadow(color: Palette.panelShadow, blurRadius: 14, offset: Offset(0, 5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (cosmetic != null && !widget.duplicateCosmetic) ...[
            CosmeticSwatch(cosmetic: cosmetic, height: 34),
            const SizedBox(height: 6),
            Text(
              cosmetic.kind == CosmeticKind.balls ? 'New balls: ${cosmetic.name}!' : 'New sky: ${cosmetic.name}!',
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

/// Confetti and a soft ring bursting out of the opened gift.
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
