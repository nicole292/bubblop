import 'dart:math' as math;
import 'dart:ui';

/// Converts between board cells and screen pixels for a given area.
class BoardLayout {
  factory BoardLayout(Size area, {required int columns, required int rows}) {
    const padding = 12.0;
    // Extra room above the board for the held orb and falling-in orbs.
    const headroomCells = 1.2;
    final cell = math.min(
      (area.width - padding * 2) / columns,
      (area.height - padding * 2) / (rows + headroomCells),
    );
    final width = cell * columns;
    final height = cell * rows;
    final origin = Offset(
      (area.width - width) / 2,
      (area.height - height) / 2 + cell * headroomCells / 2,
    );
    return BoardLayout._(columns, rows, cell, origin);
  }

  BoardLayout._(this.columns, this.rows, this.cell, this.origin);

  final int columns;
  final int rows;
  final double cell;

  /// Top-left corner of the board.
  final Offset origin;

  Rect get rect => origin & Size(cell * columns, cell * rows);

  /// Screen centre of a cell. Fractional values are used while animating;
  /// row 0 is the bottom.
  Offset center(double col, double row) => Offset(
        origin.dx + (col + 0.5) * cell,
        origin.dy + (rows - row - 0.5) * cell,
      );

  /// The column under screen x, clamped so dragging past an edge still aims
  /// at the edge column.
  int columnAt(double x) =>
      ((x - origin.dx) / cell).floor().clamp(0, columns - 1);
}
