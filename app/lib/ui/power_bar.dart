import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/palette.dart';
import '../progress/power_ups.dart';
import '../progress/progress.dart';
import 'shop_sheet.dart';
import 'undo_button.dart';
import 'type.dart';

/// The power-up bar above the board while playing: each power-up that can
/// be used in this round, on a glossy badge with how many you have (a "+"
/// when you have none, which opens the shop), then a Shop button. Laid out
/// at [designHeight] and scaled to fit, like the header.
class PowerBar extends StatelessWidget {
  const PowerBar({
    super.key,
    required this.progress,
    required this.items,
    required this.onUse,
    required this.onShop,
    this.armedBomb = false,
    required this.undoCost,
    required this.onUndo,
  });

  /// What an undo costs now (0 = the round's free one), or null when there
  /// is nothing to undo.
  final int? undoCost;
  final VoidCallback onUndo;

  final Progress progress;

  /// The power-ups that make sense in this round.
  final List<PowerUp> items;
  final ValueChanged<PowerUp> onUse;

  /// Opens the shop, with the power-up that was tapped (if any) picked out.
  final ValueChanged<PowerUp?> onShop;

  /// A bought bomb is armed: its badge glows.
  final bool armedBomb;

  static const designHeight = 64.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = (constraints.maxHeight / designHeight).clamp(0.5, 1.6);
        return FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: constraints.maxWidth / scale,
            height: designHeight,
            // Taps between the buttons must not drop a ball.
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              onPanStart: (_) {},
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Palette.card.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [BoxShadow(color: Palette.panelShadow, blurRadius: 14, offset: const Offset(0, 5))],
                ),
                child: ListenableBuilder(
                  listenable: progress,
                  builder: (context, _) => Row(
                    children: [
                      Expanded(child: UndoBadgeButton(cost: undoCost, onPressed: onUndo)),
                      for (final p in items)
                        Expanded(
                          child: _PowerButton(
                            item: p,
                            count: progress.stock(p),
                            armed: p == PowerUp.bomb && armedBomb,
                            onTap: () => progress.stock(p) > 0 ? onUse(p) : onShop(p),
                          ),
                        ),
                      _ShopButton(onTap: () => onShop(null)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PowerButton extends StatefulWidget {
  const _PowerButton({required this.item, required this.count, required this.armed, required this.onTap});
  final PowerUp item;
  final int count;
  final bool armed;
  final VoidCallback onTap;

  @override
  State<_PowerButton> createState() => _PowerButtonState();
}

class _PowerButtonState extends State<_PowerButton> with TickerProviderStateMixin {
  /// A squash when tapped.
  late final _press = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));

  /// A gentle glow loop while a bought bomb is armed.
  late final _glow = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void initState() {
    super.initState();
    if (widget.armed) _glow.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PowerButton old) {
    super.didUpdateWidget(old);
    if (widget.armed && !_glow.isAnimating) _glow.repeat(reverse: true);
    if (!widget.armed && _glow.isAnimating) _glow.reset();
  }

  @override
  void dispose() {
    _press.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final have = widget.count > 0;
    return Tooltip(
      message: have ? '${widget.item.label}: ${widget.item.about}' : 'Buy ${widget.item.label}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _press.forward(from: 0);
          widget.onTap();
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([_press, _glow]),
          builder: (context, child) {
            final squash = 1 - 0.15 * math.sin(_press.value * math.pi);
            return Transform.scale(scale: squash, child: child);
          },
          child: Center(
            child: SizedBox.square(
              dimension: 54,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  if (widget.armed)
                    AnimatedBuilder(
                      animation: _glow,
                      builder: (context, _) => Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: widget.item.color.withValues(alpha: 0.5 + 0.4 * _glow.value),
                              blurRadius: 12 + 8 * _glow.value,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  PowerUpBadge(item: widget.item, size: 46, dim: !have),
                  // How many you have, or a + to buy some.
                  Positioned(
                    right: -2,
                    top: -2,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                      child: Container(
                        key: ValueKey(widget.count),
                        constraints: const BoxConstraints(minWidth: 22),
                        height: 22,
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: have ? Palette.danger : Palette.success,
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: have
                            ? Text('${widget.count}', style: PopType.of(12, 1000, color: Colors.white, numbers: true))
                            : const Icon(Icons.add_rounded, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The way into the shop: a golden button with a little shine.
class _ShopButton extends StatelessWidget {
  const _ShopButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Shop',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(left: 6),
          padding: const EdgeInsets.fromLTRB(10, 0, 14, 0),
          height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFFC23D), Color(0xFFFF8A1A)]),
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [BoxShadow(color: Color(0x55FF8A1A), blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.storefront_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 5),
              Text('Shop', style: PopType.of(15, 1000, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
