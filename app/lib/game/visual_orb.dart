import 'package:pop_core/pop_core.dart';

/// How one cell currently looks on screen. Purely visual; the rules never
/// read this.
class VisualOrb {
  VisualOrb(this.cell, this.col, this.row) : seed = _nextSeed++;

  static int _nextSeed = 1;

  Cell cell;

  /// Position in cell units (fractional while moving). Row 0 is the bottom.
  double col;
  double row;

  double scale = 1;
  double alpha = 1;

  /// 0–1: highlight before popping.
  double glow = 0;

  /// 0–1: a shell turning into a plain orb.
  double reveal = 0;

  /// 0–1: cracks spreading over a shell that is about to break.
  double crack = 0;

  /// Direction (radians, screen space) the crack starts from: toward the
  /// popped neighbour that broke it.
  double crackAngle = 0;

  /// Seconds left of the bright flash after a shell's core is freed.
  double flash = 0;

  /// Seconds of landing squash left.
  double squash = 0;

  /// Stable per-orb random seed (crack pattern, idle shimmer phase).
  final int seed;
}
