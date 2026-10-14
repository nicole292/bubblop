/// A board coordinate. Column 0 is the left edge, row 0 is the bottom.
typedef CellPos = ({int col, int row});

enum CellKind { orb, shell, stone }

/// The contents of one occupied board cell. Empty cells are `null`.
class Cell {
  const Cell.orb(this.color) : kind = CellKind.orb;
  const Cell.shell(this.color) : kind = CellKind.shell;
  const Cell.stone()
      : kind = CellKind.stone,
        color = -1;

  final CellKind kind;

  /// Colour index (0 = first colour). -1 for stones, which have no colour.
  final int color;

  bool get isOrb => kind == CellKind.orb;

  /// Shells and stones: things that crack when a neighbour pops.
  bool get isBreakable => kind != CellKind.orb;

  @override
  bool operator ==(Object other) =>
      other is Cell && other.kind == kind && other.color == color;

  @override
  int get hashCode => Object.hash(kind, color);

  @override
  String toString() => switch (kind) {
        CellKind.orb => 'Orb($color)',
        CellKind.shell => 'Shell($color)',
        CellKind.stone => 'Stone',
      };
}
