import 'dart:ui';

import '../progress/cosmetics.dart';

/// "Bright & Bouncy" colour tokens. Every screen uses these. The surfaces
/// and text switch with [dark]; the bright accents stay the same in both.
abstract final class Palette {
  /// Dark mode: night skies, deep indigo cards, light text. Set from the
  /// Light / Dark / Auto setting (see ThemeSwitch in ui/theme_switch.dart).
  static bool dark = false;

  // Sky behind everything: bright, airy, a little playful. Set by the
  // chosen sky cosmetic ([apply]); at night the same hues, deepened.
  static Color _skyTop = Cosmetics.day.colors[0];
  static Color _skyMid = Cosmetics.day.colors[1];
  static Color _skyBottom = Cosmetics.day.colors[2];
  static Color get skyTop => _sky(_skyTop);
  static Color get skyMid => _sky(_skyMid);
  static Color get skyBottom => _sky(_skyBottom);
  static Color _sky(Color c) => dark ? Color.lerp(c, const Color(0xFF0B0D26), 0.72)! : c;

  // Board card.
  static Color get card => dark ? const Color(0xFF262A52) : const Color(0xFFFFFFFF);
  static Color get well => dark ? const Color(0xFF1C1F3E) : const Color(0xFFF1F4FF);
  static Color get laneAlt => dark ? const Color(0xFF232747) : const Color(0xFFE8EDFF);
  static Color get cardShadow => dark ? const Color(0x88000000) : const Color(0x553A2D9E);
  static Color get panelShadow => dark ? const Color(0x55000000) : const Color(0x2E3A2D9E);
  static Color get socket => dark ? const Color(0xFF30355F) : const Color(0xFFE4E9FF);

  /// Dims the screen behind a pop-up card.
  static Color get scrim => dark ? const Color(0xFF05061A) : const Color(0xFF26285A);

  /// The warm cream behind an affordable price or a coin reward.
  static Color get cream => dark ? const Color(0xFF4A3B1C) : const Color(0xFFFFF4D6);

  // Text and UI.
  static Color get ink => dark ? const Color(0xFFF0F1FF) : const Color(0xFF26285A);
  static Color get inkSoft => dark ? const Color(0xFFA3A8D6) : const Color(0xFF7B80B0);
  static Color get pipEmpty => dark ? const Color(0xFF3A3F6E) : const Color(0xFFDDE2FA);
  static const accent = Color(0xFF7B5CFF);
  static const gold = Color(0xFFFFB020);
  static const danger = Color(0xFFFF4D5E);
  static const success = Color(0xFF22C55E);
  static const coin = Color(0xFFFFB020);
  static const buttonStart = Color(0xFFFFA62B);
  static const buttonEnd = Color(0xFFFF5C8A);

  /// The ball colours in colour-index order, from the chosen ball set
  /// ([apply]). Classic: cherry, sunflower, fresh green, sky blue, grape.
  /// Every set differs in brightness as well as hue, since colour is the
  /// only cue on a ball.
  static List<Color> balls = Cosmetics.classic.colors;

  /// The outline of every piece, from the chosen shape set ([apply]).
  static PieceShape shape = PieceShape.ball;

  /// Switches to the player's chosen ball set, shape and sky.
  static void apply({required Cosmetic balls, required Cosmetic shape, required Cosmetic sky}) {
    Palette.balls = balls.colors;
    Palette.shape = shape.shape;
    _skyTop = sky.colors[0];
    _skyMid = sky.colors[1];
    _skyBottom = sky.colors[2];
  }
}
