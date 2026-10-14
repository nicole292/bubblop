import 'cell.dart';

/// Letters used by [Board.parse] and [Board.toPicture] for colours 0–4.
const colorLetters = ['R', 'Y', 'G', 'B', 'P'];

/// The grid of cells. Cells always rest on the floor or on another cell
/// (gravity is applied after every change), so each column is a stack.
class Board {
  Board(this.columns, this.rows)
      : _cells = List<Cell?>.filled(columns * rows, null);

  Board._(this.columns, this.rows, this._cells);

  /// Builds a board from a text picture, top line first, bottom line last.
  /// `R Y G B P` are orbs, lowercase letters are shells, `#` is a stone and
  /// `.` is empty. Missing top lines are treated as empty.
  ///
  /// ```
  /// .r....
  /// RGGB..
  /// ```
  factory Board.parse(String picture, {int columns = 6, int rows = 10}) {
    final lines = picture
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.length > rows) {
      throw ArgumentError('Picture has ${lines.length} lines, board has $rows rows');
    }
    final board = Board(columns, rows);
    for (var i = 0; i < lines.length; i++) {
      final row = lines.length - 1 - i;
      final line = lines[i];
      if (line.length != columns) {
        throw ArgumentError('Line "$line" must have $columns characters');
      }
      for (var col = 0; col < columns; col++) {
        board.set(col, row, _parseCell(line[col]));
      }
    }
    return board;
  }

  final int columns;
  final int rows;
  final List<Cell?> _cells;

  Cell? at(int col, int row) => _cells[row * columns + col];

  Cell? atPos(CellPos p) => at(p.col, p.row);

  void set(int col, int row, Cell? cell) => _cells[row * columns + col] = cell;

  /// Number of occupied cells in [col]; also the row a dropped orb lands in.
  int height(int col) {
    var h = 0;
    while (h < rows && at(col, h) != null) {
      h++;
    }
    return h;
  }

  bool isColumnFull(int col) => height(col) >= rows;

  bool get isFull {
    for (var c = 0; c < columns; c++) {
      if (!isColumnFull(c)) return false;
    }
    return true;
  }

  bool get isEmpty => _cells.every((c) => c == null);

  Board copy() => Board._(columns, rows, List.of(_cells));

  /// The inverse of [Board.parse]; prints every row, top first.
  String toPicture() {
    final buf = StringBuffer();
    for (var row = rows - 1; row >= 0; row--) {
      for (var col = 0; col < columns; col++) {
        buf.write(_cellChar(at(col, row)));
      }
      if (row > 0) buf.write('\n');
    }
    return buf.toString();
  }

  @override
  String toString() => toPicture();

  static Cell? _parseCell(String ch) {
    if (ch == '.') return null;
    if (ch == '#') return const Cell.stone();
    final upper = ch.toUpperCase();
    final color = colorLetters.indexOf(upper);
    if (color < 0) throw ArgumentError('Unknown cell character "$ch"');
    return ch == upper ? Cell.orb(color) : Cell.shell(color);
  }

  static String _cellChar(Cell? cell) {
    if (cell == null) return '.';
    return switch (cell.kind) {
      CellKind.orb => colorLetters[cell.color],
      CellKind.shell => colorLetters[cell.color].toLowerCase(),
      CellKind.stone => '#',
    };
  }
}
