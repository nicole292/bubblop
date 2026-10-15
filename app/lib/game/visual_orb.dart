import 'package:pop_core/pop_core.dart';

/// How one cell currently looks on screen. Purely visual; the rules never
/// read this.
class VisualOrb {
  VisualOrb(this.cell, this.col, this.row);

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

  /// Seconds of landing squash left.
  double squash = 0;
}
