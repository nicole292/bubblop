import 'dart:math' as math;
import 'dart:ui';

/// Converts between board cells and screen pixels for a given area.
///
/// Vertical stack: headroom (held orb) → board → tray (rise meter and the
/// next rising row, inside the board card).
class BoardLayout {
  /// [offset] is where [area] starts on the game canvas.
  factory BoardLayout(Size area,
      {required int columns, required int rows, Offset offset = Offset.zero}) {
    final cell = math.min(
      math.min(
        (area.width - padding * 2) / columns,
        (area.height - padding * 2) / (rows + headroomCells + trayCells),
      ),
      maxCell,
    );
    final width = cell * columns;
    final stack = cell * (rows + headroomCells + trayCells);
    final origin = offset +
        Offset(
          (area.width - width) / 2,
          (area.height - stack) / 2 + cell * headroomCells,
        );
    return BoardLayout._(columns, rows, cell, origin);
  }

  BoardLayout._(this.columns, this.rows, this.cell, this.origin);

  static const padding = 12.0;

  /// Room above the board for the held orb and orbs dropping in.
  static const headroomCells = 0.75;

  /// Room below the board for the tray (the card's lower part).
  static const trayCells = 1.12;

  /// Keeps orbs a comfortable size on tablets and desktop windows.
  static const maxCell = 76.0;

  /// The height the board area needs at [width], so the screen can give it
  /// exactly that and place the HUD right above it.
  static double preferredHeight(double width, {required int columns, required int rows}) {
    final cell = math.min((width - padding * 2) / columns, maxCell);
    return cell * (rows + headroomCells + trayCells) + padding * 2;
  }

  final int columns;
  final int rows;
  final double cell;

  /// Top-left corner of the board.
  final Offset origin;

  Rect get rect => origin & Size(cell * columns, cell * rows);

  /// Centre line of the rise meter, between the board and the tray.
  double get meterY => rect.bottom + cell * 0.24;

  /// Centre line of the next-row tray.
  double get trayCenterY => rect.bottom + cell * 0.66;

  /// Bottom edge of the board card (it holds the board, meter and tray).
  double get cardBottom => rect.bottom + cell * 1.02;

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
