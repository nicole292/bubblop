import 'package:flutter/widgets.dart';

/// Makes the whole game bigger on tablets and large windows: it lays the app
/// out at phone size and scales it up to fill the screen, so an iPad shows
/// the same game, just larger, instead of a small game in a sea of sky.
/// Phones (shortest side up to [phoneSide]) are left exactly as they are.
class UiScale extends StatelessWidget {
  const UiScale({super.key, required this.child});
  final Widget child;

  /// The shortest side, in logical pixels, the layout is designed for.
  static const phoneSide = 430.0;

  /// The most the app is scaled up (an iPad Pro gets this).
  static const maxFactor = 1.8;

  /// The current scale, also used to bake images sharp enough for it.
  static double factor = 1;

  static double factorFor(Size size) => (size.shortestSide / phoneSide).clamp(1.0, maxFactor);

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final s = factorFor(mq.size);
    factor = s;
    if (s <= 1.01) return child;
    final size = mq.size / s;
    return MediaQuery(
      data: mq.copyWith(
        size: size,
        padding: mq.padding / s,
        viewPadding: mq.viewPadding / s,
        viewInsets: mq.viewInsets / s,
        devicePixelRatio: mq.devicePixelRatio * s,
      ),
      child: SizedBox.expand(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: size.width,
          maxWidth: size.width,
          minHeight: size.height,
          maxHeight: size.height,
          child: Transform.scale(scale: s, alignment: Alignment.topLeft, child: child),
        ),
      ),
    );
  }
}
