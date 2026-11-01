import 'dart:ui';

import '../progress/cosmetics.dart';

/// "Bright & Bouncy" colour tokens. Every screen uses these. The surfaces
/// and text switch with [dark]; the bright accents stay the same in both.
abstract final class Palette {
  /// Dark mode: night skies, deep indigo cards, light text. Set from the
  /// Light / Dark / Auto setting (see ThemeSwitch in ui/theme_switch.dart).
  static bool dark = false;

  // Sky behind everything: bright, airy, a little playful. Set by the
  // chosen sky cosmetic ([apply]). At night: a deep blue-to-violet sky with
  // a hint of the chosen sky's colours (stars are drawn by SkyBackground).
  static Color _skyTop = Cosmetics.day.colors[0];
  static Color _skyMid = Cosmetics.day.colors[1];
  static Color _skyBottom = Cosmetics.day.colors[2];
  static Color get skyTop => dark ? Color.lerp(const Color(0xFF0C1449), _skyTop, 0.18)! : _skyTop;
  static Color get skyMid => dark ? Color.lerp(const Color(0xFF231A63), _skyMid, 0.18)! : _skyMid;
  static Color get skyBottom => dark ? Color.lerp(const Color(0xFF431B6B), _skyBottom, 0.18)! : _skyBottom;

  // Board card.
  static Color get card => dark ? const Color(0xFF20265E) : const Color(0xFFFFFFFF);
  static Color get well => dark ? const Color(0xFF151A47) : const Color(0xFFF1F4FF);
  static Color get laneAlt => dark ? const Color(0xFF1B2152) : const Color(0xFFE8EDFF);
  static Color get cardShadow => dark ? const Color(0x99050320) : const Color(0x553A2D9E);
  static Color get panelShadow => dark ? const Color(0x80050320) : const Color(0x2E3A2D9E);
  static Color get socket => dark ? const Color(0xFF2B3270) : const Color(0xFFE4E9FF);

  /// A faint lit rim around cards at night, so they stand off the sky.
  /// Invisible by day.
  static Color get edge => dark ? const Color(0x38B9C3FF) : const Color(0x00FFFFFF);

  /// Dims the screen behind a pop-up card.
  static Color get scrim => dark ? const Color(0xFF05061A) : const Color(0xFF26285A);

  /// The warm cream behind an affordable price or a coin reward.
  static Color get cream => dark ? const Color(0xFF4A3B1C) : const Color(0xFFFFF4D6);

  // Text and UI.
  static Color get ink => dark ? const Color(0xFFF0F1FF) : const Color(0xFF26285A);
  static Color get inkSoft => dark ? const Color(0xFFAEB4E8) : const Color(0xFF7B80B0);
  static Color get pipEmpty => dark ? const Color(0xFF333B7A) : const Color(0xFFDDE2FA);
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

  /// The surface of the chosen ball set ([apply]).
  static Finish finish = Finish.gloss;

  /// Switches to the player's chosen ball set, shape and sky.
  static void apply({required Cosmetic balls, required Cosmetic shape, required Cosmetic sky}) {
    Palette.balls = balls.colors;
    Palette.shape = shape.shape;
    Palette.finish = balls.finish;
    _skyTop = sky.colors[0];
    _skyMid = sky.colors[1];
    _skyBottom = sky.colors[2];
  }
}
