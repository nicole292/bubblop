import 'dart:ui';

/// Greybox colours. These follow the planned art direction so colour
/// readability can be judged now; the orb materials come in Stage 3.
abstract final class Palette {
  static const background = Color(0xFF0E1226);
  static const board = Color(0xFF141A33);
  static const laneA = Color(0xFF161D3A);
  static const laneB = Color(0xFF1A2244);
  static const aimLane = Color(0xFF26305C);
  static const danger = Color(0xFFFF4D6A);
  static const stone = Color(0xFF6B7085);
  static const text = Color(0xFFF2F4FF);
  static const textDim = Color(0xFF8C93B8);

  /// Coral, Saffron, Mint, Azure, Orchid — in colour-index order.
  static const orbs = [
    Color(0xFFFF6B5B),
    Color(0xFFFFC23D),
    Color(0xFF3DDC97),
    Color(0xFF3FA9F5),
    Color(0xFFB57BFF),
  ];
}
