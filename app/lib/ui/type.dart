import 'package:flutter/painting.dart';

import '../game/palette.dart';

/// Text styles. Sora is a variable font, so weight is set through the
/// 'wght' axis rather than FontWeight (which could add synthetic bold).
abstract final class PopType {
  static TextStyle of(
    double size,
    double weight, {
    Color color = Palette.text,
    double spacing = 0,
    bool numbers = false,
  }) {
    return TextStyle(
      fontFamily: 'Sora',
      fontSize: size,
      fontVariations: [FontVariation('wght', weight)],
      color: color,
      letterSpacing: spacing,
      height: 1.1,
      fontFeatures: numbers ? const [FontFeature.tabularFigures()] : null,
    );
  }

  static final label = of(10.5, 600, color: Palette.textDim, spacing: 1.8);
  static final score = of(34, 700, numbers: true);
  static final small = of(12, 500, color: Palette.textDim, numbers: true);
  static final banner = of(30, 800, spacing: 0.5);
  static final panelTitle = of(15, 600, color: Palette.textDim, spacing: 0.5);
  static final panelScore = of(52, 800, numbers: true);
  static final button = of(17, 700, color: const Color(0xFF1A1206));
}
