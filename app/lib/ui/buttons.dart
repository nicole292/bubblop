import 'package:flutter/material.dart';

import '../game/palette.dart';
import 'type.dart';

/// The chunky, bouncy pill button used for main actions. It sits on a solid
/// darker base and presses down when touched.
class BigButton extends StatefulWidget {
  const BigButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.colors = const [Palette.buttonStart, Palette.buttonEnd],
    this.baseColor = const Color(0xFFD9406E),
    this.height = 60,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final List<Color> colors;
  final Color baseColor;
  final double height;

  @override
  State<BigButton> createState() => _BigButtonState();
}

class _BigButtonState extends State<BigButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final depth = _down ? 1.0 : 5.0;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onPressed();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        height: widget.height,
        width: double.infinity,
        margin: EdgeInsets.only(top: 5 - depth),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.height / 2),
          gradient: LinearGradient(colors: widget.colors),
          boxShadow: [
            BoxShadow(color: widget.baseColor, offset: Offset(0, depth)),
            BoxShadow(color: widget.colors.last.withValues(alpha: 0.35), blurRadius: 16, offset: Offset(0, depth + 4)),
          ],
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: Colors.white, size: widget.height * 0.42),
                const SizedBox(width: 8),
              ],
              Text(widget.label, style: PopType.of(widget.height * 0.34, 900, color: Colors.white, spacing: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A secondary action: white pill with ink text.
class SoftButton extends StatelessWidget {
  const SoftButton({super.key, required this.label, required this.onPressed, this.icon});

  final String label;
  final IconData? icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Palette.well,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onPressed,
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            // Shrinks the label on narrow screens instead of overflowing.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Palette.ink, size: 22),
                    const SizedBox(width: 8),
                  ],
                  Text(label, style: PopType.of(17, 900)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A white round icon button (pause, settings, sound).
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, required this.tooltip, required this.onPressed, this.size = 40});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Palette.card,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(width: size, height: size, child: Icon(icon, size: size * 0.55, color: Palette.ink)),
        ),
      ),
    );
  }
}

/// A labelled on/off row for settings.
class ToggleRow extends StatelessWidget {
  const ToggleRow({super.key, required this.icon, required this.label, required this.value, required this.onChanged});

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: Palette.ink),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: PopType.of(17, 800))),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: Palette.balls[2],
            ),
          ],
        ),
      ),
    );
  }
}
