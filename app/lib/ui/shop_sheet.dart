import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/palette.dart';
import '../progress/power_ups.dart';
import '../progress/progress.dart';
import 'bomb_icon.dart';
import 'glass.dart';
import 'type.dart';

/// The shop: every power-up on its own bright card, with a − / + picker for
/// how many to buy and the total in coins. Opens from the power-up bar while
/// playing, and from a level's card. [highlight] scrolls that item into view
/// and makes it bounce.
Future<void> showShop(
  BuildContext context, {
  required Progress progress,
  PowerUp? highlight,
  VoidCallback? onBought,
  VoidCallback? onDeny,
}) =>
    showDialog<void>(
      context: context,
      barrierColor: Palette.scrim.withValues(alpha: 0.45),
      builder: (context) => _ShopSheet(
        progress: progress,
        highlight: highlight,
        onBought: onBought,
        onDeny: onDeny,
      ),
    );

class _ShopSheet extends StatelessWidget {
  const _ShopSheet({required this.progress, this.highlight, this.onBought, this.onDeny});
  final Progress progress;
  final PowerUp? highlight;
  final VoidCallback? onBought;
  final VoidCallback? onDeny;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 640),
        child: Container(
          decoration: BoxDecoration(
            color: Palette.card,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Palette.edge, width: 1.2),
            boxShadow: const [BoxShadow(color: Color(0x663A2D9E), blurRadius: 30, offset: Offset(0, 12))],
          ),
          child: ListenableBuilder(
            listenable: progress,
            builder: (context, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header: a warm gradient with the title and the coins you have.
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 10, 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFFFFA62B), Color(0xFFFF5C8A)]),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
                      const SizedBox(width: 8),
                      Text('Shop', style: PopType.of(26, 1000, color: Colors.white)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.fromLTRB(6, 4, 12, 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CoinIcon(size: 24),
                            const SizedBox(width: 5),
                            Text('${progress.coins}', style: PopType.of(17, 1000, numbers: true)),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                    children: [
                      for (final p in PowerUp.values) ...[
                        _ShopItem(
                          item: p,
                          progress: progress,
                          highlighted: p == highlight,
                          onBought: onBought,
                          onDeny: onDeny,
                        ),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        'Earn coins by finishing levels, opening gifts and winning awards.',
                        textAlign: TextAlign.center,
                        style: PopType.of(12, 800, color: Palette.inkSoft),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One power-up: its icon on a glowing badge, name, what it does, how many
/// you have, a − / + picker and a Buy button with the total.
class _ShopItem extends StatefulWidget {
  const _ShopItem({
    required this.item,
    required this.progress,
    required this.highlighted,
    this.onBought,
    this.onDeny,
  });
  final PowerUp item;
  final Progress progress;
  final bool highlighted;
  final VoidCallback? onBought;
  final VoidCallback? onDeny;

  @override
  State<_ShopItem> createState() => _ShopItemState();
}

class _ShopItemState extends State<_ShopItem> with TickerProviderStateMixin {
  int _count = 1;

  /// A pop of the badge and a ring of sparkles after buying.
  late final _bought = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

  /// The item asked for bounces in when the shop opens.
  late final _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    if (widget.highlighted) _intro.forward();
  }

  @override
  void dispose() {
    _bought.dispose();
    _intro.dispose();
    super.dispose();
  }

  int get _have => widget.progress.stock(widget.item);
  int get _maxMore => PowerUp.maxStock - _have;
  int get _total => widget.item.price * _count;

  void _change(int by) {
    final next = (_count + by).clamp(1, math.max(1, _maxMore)).toInt();
    if (next == _count) return;
    setState(() => _count = next);
  }

  void _buy() {
    if (!widget.progress.buyPowerUp(widget.item, _count)) {
      widget.onDeny?.call();
      return;
    }
    widget.onBought?.call();
    _bought.forward(from: 0);
    setState(() => _count = 1);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final color = item.color;
    final affordable = widget.progress.coins >= _total && _maxMore > 0;
    return AnimatedBuilder(
      animation: _intro,
      builder: (context, child) {
        final t = _intro.value;
        final bounce = widget.highlighted ? 1 + 0.05 * math.sin(t * math.pi * 3) * (1 - t) : 1.0;
        return Transform.scale(scale: bounce, child: child);
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withValues(alpha: 0.16), color.withValues(alpha: 0.05)],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: color.withValues(alpha: widget.highlighted ? 0.9 : 0.35),
            width: widget.highlighted ? 2.5 : 1.5,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                AnimatedBuilder(
                  animation: _bought,
                  builder: (context, _) => PowerUpBadge(item: item, size: 58, burst: _bought.isAnimating ? _bought.value : null),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(child: Text(item.label, style: PopType.of(18, 1000))),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(9)),
                            child: Text('You have $_have',
                                style: PopType.of(11, 1000, color: Colors.white, numbers: true)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(item.about, style: PopType.of(13, 800, color: Palette.inkSoft)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                // How many to buy.
                _Stepper(
                  count: _count,
                  color: color,
                  onLess: _count > 1 ? () => _change(-1) : null,
                  onMore: _count < _maxMore ? () => _change(1) : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _BuyButton(
                    total: _total,
                    color: color,
                    enabled: affordable,
                    onPressed: affordable ? _buy : widget.onDeny,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.count, required this.color, this.onLess, this.onMore});
  final int count;
  final Color color;
  final VoidCallback? onLess;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, VoidCallback? onTap, String tip) => Material(
          color: onTap == null ? Palette.pipEmpty : color,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Tooltip(
              message: tip,
              child: SizedBox.square(dimension: 38, child: Icon(icon, color: Colors.white, size: 22)),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Palette.card, borderRadius: BorderRadius.circular(24)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(Icons.remove_rounded, onLess, 'Fewer'),
          SizedBox(
            width: 42,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
              child: Text(
                '$count',
                key: ValueKey(count),
                textAlign: TextAlign.center,
                style: PopType.of(22, 1000, numbers: true),
              ),
            ),
          ),
          button(Icons.add_rounded, onMore, 'More'),
        ],
      ),
    );
  }
}

class _BuyButton extends StatelessWidget {
  const _BuyButton({required this.total, required this.color, required this.enabled, this.onPressed});
  final int total;
  final Color color;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onPressed,
          child: Ink(
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Color.lerp(color, Colors.white, 0.15)!, color]),
              borderRadius: BorderRadius.circular(24),
              boxShadow: enabled
                  ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Buy', style: PopType.of(17, 1000, color: Colors.white)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.fromLTRB(4, 2, 9, 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CoinIcon(size: 20),
                      const SizedBox(width: 3),
                      Text('$total', style: PopType.of(15, 1000, numbers: true)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A power-up's icon on a glossy round badge in its colour. [burst] (0–1)
/// pops it and throws a ring of sparkles, after buying.
class PowerUpBadge extends StatelessWidget {
  const PowerUpBadge({super.key, required this.item, this.size = 48, this.burst, this.dim = false});
  final PowerUp item;
  final double size;
  final double? burst;
  final bool dim;

  @override
  Widget build(BuildContext context) {
    final b = burst;
    final pop = b == null ? 1.0 : 1 + 0.3 * math.sin(b * math.pi);
    final color = item.color;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (b != null)
            Positioned(
              left: -size * 0.3,
              top: -size * 0.3,
              right: -size * 0.3,
              bottom: -size * 0.3,
              child: IgnorePointer(child: CustomPaint(painter: _SparklePainter(b, color))),
            ),
          Transform.scale(
            scale: pop,
            child: Opacity(
              opacity: dim ? 0.55 : 1,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.35, -0.45),
                    colors: [Color.lerp(color, Colors.white, 0.55)!, color, Color.lerp(color, Colors.black, 0.25)!],
                    stops: const [0, 0.6, 1],
                  ),
                  border: Border.all(color: Colors.white, width: size * 0.05),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: size * 0.22, offset: Offset(0, size * 0.06))],
                ),
                alignment: Alignment.center,
                child: _icon(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _icon() => switch (item) {
        PowerUp.bomb => BombIcon(size: size * 0.6),
        PowerUp.rainbow => CustomPaint(size: Size.square(size * 0.6), painter: _RainbowPainter()),
        PowerUp.freeze => Icon(Icons.ac_unit_rounded, size: size * 0.56, color: Colors.white),
        PowerUp.drops => Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.water_drop_rounded, size: size * 0.6, color: Colors.white),
              Padding(
                padding: EdgeInsets.only(top: size * 0.12),
                child: Text('+${PowerUp.extraDrops}',
                    style: PopType.of(size * 0.22, 1000, color: item.color, numbers: true)),
              ),
            ],
          ),
      };
}

/// Five little balls in the ball colours around a white star: "every ball
/// of a colour pops".
class _RainbowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    for (var i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * math.pi * 2 / 5;
      final p = c + Offset(math.cos(a), math.sin(a)) * r * 0.62;
      canvas.drawCircle(p, r * 0.3, Paint()..color = Colors.white);
      canvas.drawCircle(p, r * 0.23, Paint()..color = Palette.balls[i % Palette.balls.length]);
    }
    final star = Path();
    for (var i = 0; i < 8; i++) {
      final a = -math.pi / 2 + i * math.pi / 4;
      final rr = i.isEven ? r * 0.38 : r * 0.13;
      final p = c + Offset(math.cos(a), math.sin(a)) * rr;
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(star..close(), Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_RainbowPainter old) => false;
}

class _SparklePainter extends CustomPainter {
  _SparklePainter(this.t, this.color);
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 * (0.5 + 0.5 * Curves.easeOut.transform(t));
    final fade = (1 - t).clamp(0.0, 1.0);
    for (var i = 0; i < 10; i++) {
      final a = i * math.pi * 2 / 10;
      final p = c + Offset(math.cos(a), math.sin(a)) * r;
      final paint = Paint()..color = (i.isEven ? Palette.gold : color).withValues(alpha: fade);
      final s = 4.0 * fade + 1;
      canvas.drawPath(
        Path()
          ..moveTo(p.dx, p.dy - s * 1.6)
          ..lineTo(p.dx + s * 0.5, p.dy)
          ..lineTo(p.dx, p.dy + s * 1.6)
          ..lineTo(p.dx - s * 0.5, p.dy)
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.t != t;
}
