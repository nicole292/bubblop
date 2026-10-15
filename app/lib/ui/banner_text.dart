import 'package:flutter/material.dart';

import '../game/palette.dart';

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
    duration: const Duration(milliseconds: 900),
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
          final scale = t < 0.15 ? 0.8 + 0.2 * Curves.easeOutBack.transform(t / 0.15) : 1.0;
          final opacity = t < 0.7 ? 1.0 : 1 - (t - 0.7) / 0.3;
          return Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Text(
                widget.text!,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Palette.text,
                  shadows: [Shadow(blurRadius: 12, color: Color(0xAA000000))],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
