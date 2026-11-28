import 'package:flutter/material.dart';

import '../game/palette.dart';
import 'glass.dart';
import 'type.dart';

/// The undo colour: a fresh teal, unlike any power-up.
const undoColor = Color(0xFF14B8A6);

/// What an undo costs, as a small tag: "FREE" in green, or the coin price.
class UndoPrice extends StatelessWidget {
  const UndoPrice({super.key, required this.cost, this.size = 1});
  final int cost;
  final double size;

  @override
  Widget build(BuildContext context) {
    final free = cost == 0;
    return Container(
      padding: EdgeInsets.fromLTRB(free ? 6 * size : 3 * size, 1.5 * size, 6 * size, 1.5 * size),
      decoration: BoxDecoration(
        color: free ? Palette.success : Colors.white,
        borderRadius: BorderRadius.circular(9 * size),
        border: Border.all(color: free ? Colors.white : undoColor, width: 1.5 * size),
      ),
      child: free
          ? Text('FREE', style: PopType.of(10 * size, 1000, color: Colors.white, spacing: 0.4))
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CoinIcon(size: 13 * size),
                SizedBox(width: 2 * size),
                Text('$cost', style: PopType.of(11 * size, 1000, numbers: true)),
              ],
            ),
    );
  }
}

/// The undo button in the power-up bar: a round teal badge with a
/// curved-back arrow, and what it costs under it. Dim when there is
/// nothing to undo.
class UndoBadgeButton extends StatefulWidget {
  const UndoBadgeButton({super.key, required this.cost, required this.onPressed});

  /// Null when there is nothing to undo.
  final int? cost;
  final VoidCallback onPressed;

  @override
  State<UndoBadgeButton> createState() => _UndoBadgeButtonState();
}

class _UndoBadgeButtonState extends State<UndoBadgeButton> with SingleTickerProviderStateMixin {
  /// A quick backwards spin when tapped.
  late final _spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cost = widget.cost;
    final enabled = cost != null;
    return Tooltip(
      message: !enabled
          ? 'Nothing to undo yet'
          : cost == 0
              ? 'Undo your last move (free this round)'
              : 'Undo your last move for $cost coins',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (enabled) _spin.forward(from: 0);
          widget.onPressed();
        },
        child: Center(
          child: SizedBox.square(
            dimension: 54,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: enabled ? 1 : 0.45,
                  child: AnimatedBuilder(
                    animation: _spin,
                    builder: (context, child) =>
                        Transform.rotate(angle: -Curves.easeOut.transform(_spin.value) * 6.283, child: child),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(-0.35, -0.45),
                          colors: [Color.lerp(undoColor, Colors.white, 0.55)!, undoColor, Color.lerp(undoColor, Colors.black, 0.25)!],
                          stops: const [0, 0.6, 1],
                        ),
                        border: Border.all(color: Colors.white, width: 2.3),
                        boxShadow: [BoxShadow(color: undoColor.withValues(alpha: 0.45), blurRadius: 10, offset: const Offset(0, 3))],
                      ),
                      child: const Icon(Icons.undo_rounded, color: Colors.white, size: 28),
                    ),
                  ),
                ),
                if (enabled) Positioned(right: -6, top: -4, child: UndoPrice(cost: cost)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Undo last move" on the lost-round cards, with its price.
class UndoPill extends StatelessWidget {
  const UndoPill({super.key, required this.cost, required this.onPressed});
  final int cost;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onPressed,
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Color.lerp(undoColor, Colors.white, 0.2)!, undoColor]),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [BoxShadow(color: undoColor.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.undo_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 6),
              Text('Undo last move', style: PopType.of(17, 1000, color: Colors.white)),
              const SizedBox(width: 8),
              UndoPrice(cost: cost, size: 1.15),
            ],
          ),
        ),
      ),
    );
  }
}
