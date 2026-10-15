import 'dart:ui';

/// "Bright & Bouncy" colour tokens. Every screen uses these.
abstract final class Palette {
  // Sky behind everything: bright, airy, a little playful.
  static const skyTop = Color(0xFF5CC8FF);
  static const skyMid = Color(0xFF7FA8FF);
  static const skyBottom = Color(0xFFA98BFF);

  // Board card.
  static const card = Color(0xFFFFFFFF);
  static const well = Color(0xFFF1F4FF);
  static const laneAlt = Color(0xFFE8EDFF);
  static const cardShadow = Color(0x553A2D9E);
  static const socket = Color(0xFFE4E9FF);

  // Text and UI.
  static const ink = Color(0xFF26285A);
  static const inkSoft = Color(0xFF7B80B0);
  static const accent = Color(0xFF7B5CFF);
  static const pipEmpty = Color(0xFFDDE2FA);
  static const gold = Color(0xFFFFB020);
  static const danger = Color(0xFFFF4D5E);
  static const buttonStart = Color(0xFFFFA62B);
  static const buttonEnd = Color(0xFFFF5C8A);

  /// Cherry, Sunflower, Fresh green, Sky blue, Grape — in colour-index order.
  /// Chosen to differ in brightness as well as hue, since colour is the only
  /// cue on a ball.
  static const balls = [
    Color(0xFFFF4757),
    Color(0xFFFFC312),
    Color(0xFF2ED573),
    Color(0xFF1E90FF),
    Color(0xFF9B59F6),
  ];
}
