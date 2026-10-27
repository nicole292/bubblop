import 'dart:math' as math;

/// Animation durations in seconds, from docs/rules.md.
/// Presentation only: none of these affect the rules.
abstract final class Timings {
  static double drop(double rowsFallen) => 0.090 + 0.015 * rowsFallen;
  static const squash = 0.090;
  static const highlight = 0.100;
  static const pop = 0.150;
  static const gravity = 0.150;
  static const rowRise = 0.250;
  static const shake = 0.200;
  static const gameOverDelay = 0.300;

  /// Pause after a level's winning move before the victory card.
  static const levelWinDelay = 0.450;

  /// Bright flash on a shell's core after it breaks free (non-blocking).
  static const revealFlash = 0.45;

  /// Playback speed while the player has made a move before the previous
  /// one finished animating.
  static const fastForward = 3.0;

  /// Later chain steps run 15% faster each, never below ~250 ms per step.
  static double chainFactor(int step) =>
      math.max(0.625, math.pow(0.85, step - 1).toDouble());
}
