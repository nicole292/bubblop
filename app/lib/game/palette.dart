import 'dart:ui';

/// "Lit Glass at Night" colour tokens. Every screen uses these.
abstract final class Palette {
  // Night sky behind everything.
  static const backgroundTop = Color(0xFF060816);
  static const backgroundMid = Color(0xFF0C1030);
  static const backgroundBottom = Color(0xFF141A44);
  static const backgroundGlow = Color(0xFF2A3580);

  // Board bezel (dark metal with a lit top edge).
  static const bezelTop = Color(0xFF2B3470);
  static const bezelMid = Color(0xFF161C42);
  static const bezelBottom = Color(0xFF0B0F28);
  static const bezelHighlight = Color(0x8CB9C6FF);

  // Board well.
  static const wellTop = Color(0xFF080B1E);
  static const wellBottom = Color(0xFF121944);
  static const channel = Color(0x0AFFFFFF);
  static const separator = Color(0x14A9B6FF);
  static const floorLight = Color(0xFF3B57D6);

  // Sockets (HUD queue, next-row dock).
  static const socketInner = Color(0xFF05071A);
  static const socketRim = Color(0x33B9C6FF);

  // Panels and text.
  static const panelTop = Color(0xE01B2250);
  static const panelBottom = Color(0xE00E1333);
  static const panel = Color(0xCC141A38);
  static const panelBorder = Color(0x40A9B6FF);
  static const pipEmpty = Color(0xFF1F2650);
  static const text = Color(0xFFF2F4FF);
  static const textDim = Color(0xFF8C93B8);
  static const gold = Color(0xFFFFD36B);
  static const danger = Color(0xFFFF4D6A);

  /// Coral, Saffron, Mint, Azure, Orchid — in colour-index order.
  /// Each also has a symbol (see render/orb_material.dart).
  static const orbs = [
    Color(0xFFFF6B5B),
    Color(0xFFFFC23D),
    Color(0xFF3DDC97),
    Color(0xFF3FA9F5),
    Color(0xFFB57BFF),
  ];
}
