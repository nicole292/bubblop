import 'dart:ui';

import '../progress/cosmetics.dart';

/// "Bright & Bouncy" colour tokens. Every screen uses these.
abstract final class Palette {
  // Sky behind everything: bright, airy, a little playful. Set by the
  // chosen sky cosmetic ([apply]).
  static Color skyTop = Cosmetics.day.colors[0];
  static Color skyMid = Cosmetics.day.colors[1];
  static Color skyBottom = Cosmetics.day.colors[2];

  // Board card.
  static const card = Color(0xFFFFFFFF);
  static const well = Color(0xFFF1F4FF);
  static const laneAlt = Color(0xFFE8EDFF);
  static const cardShadow = Color(0x553A2D9E);
  static const panelShadow = Color(0x2E3A2D9E);
  static const socket = Color(0xFFE4E9FF);

  // Text and UI.
  static const ink = Color(0xFF26285A);
  static const inkSoft = Color(0xFF7B80B0);
  static const accent = Color(0xFF7B5CFF);
  static const pipEmpty = Color(0xFFDDE2FA);
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

  /// Switches to the player's chosen ball set and sky.
  static void apply({required Cosmetic balls, required Cosmetic sky}) {
    Palette.balls = balls.colors;
    skyTop = sky.colors[0];
    skyMid = sky.colors[1];
    skyBottom = sky.colors[2];
  }
}
