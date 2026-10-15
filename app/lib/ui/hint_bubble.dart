import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/palette.dart';
import 'type.dart';

/// A tutorial speech bubble near the top of the board, with a bouncing
/// arrow pointing down at a column when [arrowX] is given.
class HintBubble extends StatefulWidget {
  const HintBubble({super.key, required this.text, required this.top, this.arrowX});

  final String text;

  /// Distance from the top of the board slot to place the bubble.
  final double top;

  /// Column centre (slot coordinates) the arrow points at, or null.
  final double? arrowX;

  @override
  State<HintBubble> createState() => _HintBubbleState();
}

class _HintBubbleState extends State<HintBubble> with SingleTickerProviderStateMixin {
  late final _bounce = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: widget.top,
          left: 24,
          right: 24,
          child: TweenAnimationBuilder<double>(
            key: ValueKey(widget.text),
            tween: Tween(begin: 0.7, end: 1),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            builder: (context, s, child) => Transform.scale(scale: s, child: child),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Palette.ink,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [BoxShadow(color: Color(0x553A2D9E), blurRadius: 12, offset: Offset(0, 4))],
              ),
              child: Text(widget.text, textAlign: TextAlign.center, style: PopType.of(16, 800, color: Colors.white)),
            ),
          ),
        ),
        if (widget.arrowX != null)
          AnimatedBuilder(
            animation: _bounce,
            builder: (context, _) => Positioned(
              top: widget.top + 70 + Curves.easeInOut.transform(_bounce.value) * 12,
              left: widget.arrowX! - 22,
              child: Transform.rotate(
                angle: math.pi / 2,
                child: const Icon(Icons.double_arrow_rounded, size: 46, color: Palette.accent,
                    shadows: [Shadow(color: Colors.white, blurRadius: 6), Shadow(color: Colors.white, blurRadius: 2)]),
              ),
            ),
          ),
      ],
    );
  }
}
