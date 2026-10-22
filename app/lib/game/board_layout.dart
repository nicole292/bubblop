import 'dart:math' as math;
import 'dart:ui';

/// Converts between board cells and screen pixels for a given area.
///
/// One card fills the area: header (score and next balls) → headroom (held
/// orb) → board → tray (rise meter and the next rising row).
///
/// [cell] is a row's height and sets the ball size. Columns ([columnWidth])
/// may be a little wider than that, so on short screens (a phone browser
/// with its toolbars) the card still fills the width and looks the same as
/// everywhere else.
class BoardLayout {
  /// [offset] is where [area] starts on the game canvas.
  factory BoardLayout(Size area, {required int columns, required int rows, Offset offset = Offset.zero}) {
    final cells = rows + headerCells + headroomCells + trayCells;
    final innerWidth = area.width - padding * 2;
    final cell = math.min(
      math.min(innerWidth / (columns + sideCells * 2), (area.height - padding * 2) / cells),
      maxCell,
    );
    final columnWidth = math.min((innerWidth - cell * sideCells * 2) / columns, cell * maxStretch);
    final width = columnWidth * columns;
    // The card takes the height it is given (up to some spare, which goes
    // to the headroom), so it covers most of the screen.
    final spare = math.max(0.0, math.min(area.height - padding * 2 - cell * cells, cell * maxSpareCells));
    final cardHeight = cell * cells + spare;
    final cardTop = offset.dy + (area.height - cardHeight) / 2;
    final origin = Offset(offset.dx + (area.width - width) / 2, cardTop + cell * (headerCells + headroomCells) + spare);
    return BoardLayout._(columns, rows, cell, columnWidth, origin, cardTop);
  }

  BoardLayout._(this.columns, this.rows, this.cell, this.columnWidth, this.origin, this.cardTop);

  static const padding = 8.0;

  /// Card margin beside the board.
  static const sideCells = 0.2;

  /// Room at the top of the card for the score and the next balls.
  static const headerCells = 1.3;

  /// Room above the board for the held orb and orbs dropping in.
  static const headroomCells = 1.0;

  /// Room below the board for the tray (the card's lower part).
  static const trayCells = 1.12;

  /// Extra headroom the card may take on tall screens.
  static const maxSpareCells = 2.0;

  /// How much wider than tall a column may get.
  static const maxStretch = 1.4;

  /// Keeps orbs a comfortable size on tablets and desktop windows.
  static const maxCell = 76.0;

  final int columns;
  final int rows;

  /// Row height; balls are sized from it.
  final double cell;

  /// Column width (at least [cell]).
  final double columnWidth;

  /// Top-left corner of the board.
  final Offset origin;

  /// Top edge of the card.
  final double cardTop;

  Rect get rect => origin & Size(columnWidth * columns, cell * rows);

  /// One column's lane, top to bottom of the board.
  Rect lane(int column) => Rect.fromLTWH(rect.left + column * columnWidth, rect.top, columnWidth, rect.height);

  /// Centre line of the rise meter, between the board and the tray.
  double get meterY => rect.bottom + cell * 0.24;

  /// Centre line of the next-row tray.
  double get trayCenterY => rect.bottom + cell * 0.66;

  /// Bottom edge of the card (it holds the header, board, meter and tray).
  double get cardBottom => rect.bottom + cell * 1.02;

  /// The whole card.
  Rect get cardRect => Rect.fromLTRB(rect.left - cell * sideCells, cardTop, rect.right + cell * sideCells, cardBottom);

  /// The card's header strip (score and next balls).
  Rect get headerRect => Rect.fromLTWH(cardRect.left, cardTop, cardRect.width, cell * headerCells);

  /// Screen centre of a cell. Fractional values are used while animating;
  /// row 0 is the bottom.
  Offset center(double col, double row) =>
      Offset(origin.dx + (col + 0.5) * columnWidth, origin.dy + (rows - row - 0.5) * cell);

  /// The column under screen x, clamped so dragging past an edge still aims
  /// at the edge column.
  int columnAt(double x) => ((x - origin.dx) / columnWidth).floor().clamp(0, columns - 1);
}
