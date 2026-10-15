import 'dart:ui';

/// "Lit Glass at Night" colour tokens. Every screen uses these.
abstract final class Palette {
  // Night sky behind everything.
  static const backgroundTop = Color(0xFF080B1C);
  static const backgroundBottom = Color(0xFF111735);
  static const backgroundGlow = Color(0xFF26306A);

  // Board tray.
  static const boardTop = Color(0xFF171E40);
  static const boardBottom = Color(0xFF0F1430);
  static const groove = Color(0x0FFFFFFF);
  static const rimLight = Color(0x59A9B6FF);
  static const rimDark = Color(0x0DA9B6FF);
  static const trayFill = Color(0x66060918);

  // Panels and text.
  static const panel = Color(0xCC141A38);
  static const panelBorder = Color(0x33A9B6FF);
  static const pipEmpty = Color(0xFF232B52);
  static const text = Color(0xFFF2F4FF);
  static const textDim = Color(0xFF8C93B8);
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
