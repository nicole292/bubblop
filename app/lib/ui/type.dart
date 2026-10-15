import 'package:flutter/painting.dart';

import '../game/palette.dart';

/// Text styles. Nunito is a rounded variable font, so weight is set through
/// the 'wght' axis rather than FontWeight (which could add synthetic bold).
abstract final class PopType {
  static TextStyle of(
    double size,
    double weight, {
    Color color = Palette.ink,
    double spacing = 0,
    bool numbers = false,
    Paint? foreground,
  }) {
    return TextStyle(
      fontFamily: 'Nunito',
      fontSize: size,
      fontVariations: [FontVariation('wght', weight)],
      // A text style takes either a colour or a foreground paint, not both.
      color: foreground == null ? color : null,
      foreground: foreground,
      letterSpacing: spacing,
      height: 1.1,
      fontFeatures: numbers ? const [FontFeature.tabularFigures()] : null,
    );
  }

  static final label = of(11, 800, color: Palette.inkSoft, spacing: 1.3);
  static final score = of(36, 900, numbers: true);
  static final small = of(12, 800, color: Palette.inkSoft, numbers: true);
  static final onSky = of(11, 900, color: const Color(0xFFFFFFFF), spacing: 1.3);
  static final banner = of(46, 1000, color: const Color(0xFFFFFFFF));
  static final panelTitle = of(13, 900, color: Palette.inkSoft, spacing: 2);
  static final panelScore = of(58, 900, numbers: true);
  static final button = of(20, 900, color: const Color(0xFFFFFFFF), spacing: 0.3);
}
