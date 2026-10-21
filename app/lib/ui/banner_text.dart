import 'package:flutter/material.dart';

import '../game/palette.dart';
import 'type.dart';

/// Briefly shows [text] each time [id] changes, then fades it out.
class BannerText extends StatefulWidget {
  const BannerText({super.key, required this.text, required this.id});

  final String? text;
  final int id;

  @override
  State<BannerText> createState() => _BannerTextState();
}

class _BannerTextState extends State<BannerText> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 750),
  );

  @override
  void didUpdateWidget(BannerText old) {
    super.didUpdateWidget(old);
    if (widget.id != old.id && widget.text != null) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          if (t == 0 || t == 1 || widget.text == null) return const SizedBox.shrink();
          // Quick pop-in, hold, then fade.
          final scale = t < 0.18 ? 0.4 + 0.6 * Curves.easeOutBack.transform(t / 0.18) : 1.0;
          final opacity = t < 0.7 ? 1.0 : 1 - (t - 0.7) / 0.3;
          return Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              // White letters with a purple outline, like the board labels.
              child: Stack(
                children: [
                  Text(
                    widget.text!,
                    style: PopType.of(36, 1000,
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 8
                          ..strokeJoin = StrokeJoin.round
                          ..color = Palette.accent),
                  ),
                  Text(widget.text!, style: PopType.banner),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
