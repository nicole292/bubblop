import 'package:flutter/material.dart';

import '../game/palette.dart';
import 'type.dart';

/// Frosted glass over the sky: a faint white fill with a brighter edge.
BoxDecoration glass(double radius) => BoxDecoration(
      color: const Color(0x33FFFFFF),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0x80FFFFFF), width: 1.2),
      boxShadow: const [BoxShadow(color: Color(0x143A2D9E), blurRadius: 10, offset: Offset(0, 3))],
    );

/// A round glass button with a white icon, optionally with a small label
/// underneath and a red dot when something new is waiting.
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.off = false,
    this.label,
    this.dot = false,
    this.size = 44,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool off;
  final String? label;
  final bool dot;
  final double size;

  @override
  Widget build(BuildContext context) {
    final button = Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: glass(size / 2),
          child: Icon(icon, size: size * 0.5, color: off ? const Color(0x80FFFFFF) : Colors.white),
        ),
        if (dot)
          Positioned(
            right: -1,
            top: -1,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: Palette.danger,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: label == null
            ? button
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  button,
                  const SizedBox(height: 5),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(label!, maxLines: 1, style: PopType.of(13, 800, color: Colors.white)),
                  ),
                ],
              ),
      ),
    );
  }
}

/// A glass pill with a label and an optional icon (secondary actions on
/// the sky). [wide] fills the available width, with the content centred.
class GlassPill extends StatelessWidget {
  const GlassPill({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.iconColor,
    this.wide = false,
    this.height = 48,
  });
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final Color? iconColor;
  final bool wide;
  final double height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: height,
        width: wide ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: glass(height / 2),
        child: Row(
          mainAxisSize: wide ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: height * 0.42, color: iconColor ?? const Color(0xFFFFD45C)),
              const SizedBox(width: 8),
            ],
            Text(label, style: PopType.of(height / 3, 800, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

/// A gold coin: a round gold disc with a soft rim and a white star.
class CoinIcon extends StatelessWidget {
  const CoinIcon({super.key, this.size = 22});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFD45C), Palette.coin],
        ),
        border: Border.all(color: const Color(0xFFE89A0C), width: size * 0.07),
      ),
      child: Icon(Icons.star_rounded, size: size * 0.62, color: Colors.white),
    );
  }
}

/// The coin balance on the sky (glass) or on a white card.
class CoinChip extends StatelessWidget {
  const CoinChip({super.key, required this.coins, this.onCard = false});
  final int coins;
  final bool onCard;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
      decoration: onCard
          ? BoxDecoration(color: Palette.well, borderRadius: BorderRadius.circular(22))
          : glass(22),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CoinIcon(size: 28),
          const SizedBox(width: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(end: coins.toDouble()),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Text(
              '${v.round()}',
              style: PopType.of(20, 900, color: onCard ? Palette.ink : Colors.white, numbers: true),
            ),
          ),
        ],
      ),
    );
  }
}

/// A back arrow in a glass circle, for screens over the sky.
class GlassBackButton extends StatelessWidget {
  const GlassBackButton({super.key, required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) =>
      GlassIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Back', onPressed: onPressed);
}

/// The light sky behind the menu screens, in the chosen sky's colours.
class SkyGradient extends StatelessWidget {
  const SkyGradient({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.skyTop, Palette.skyMid, Palette.skyBottom],
        ),
      ),
      child: child,
    );
  }
}
