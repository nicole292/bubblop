import 'board.dart';
import 'cell.dart';
import 'events.dart';
import 'rules_config.dart';
import 'scoring.dart';

/// Repeatedly pops groups, cracks neighbours and applies gravity until the
/// board is stable. Mutates [board] and returns one [ChainStep] per round.
List<ChainStep> resolveChains(Board board, RulesConfig config) {
  final steps = <ChainStep>[];
  for (var step = 1;; step++) {
    final groups = findGroups(board, config.matchSize);
    if (groups.isEmpty) return steps;

    final popped = {for (final g in groups) ...g.cells};
    final cracked = <CellPos, Cell>{};
    for (final pos in popped) {
      for (final n in _neighbours(board, pos)) {
        final cell = board.atPos(n);
        if (cell != null && cell.isBreakable) cracked[n] = cell;
      }
    }

    for (final pos in popped) {
      board.set(pos.col, pos.row, null);
    }
    cracked.forEach((pos, cell) {
      board.set(pos.col, pos.row,
          cell.kind == CellKind.shell ? Cell.orb(cell.color) : null);
    });

    final falls = applyGravity(board);
    final points = chainStepPoints(
      groupSizes: [for (final g in groups) g.cells.length],
      distinctColors: groups.map((g) => g.color).toSet().length,
      cracked: cracked.length,
      step: step,
    );
    steps.add(ChainStep(
      step: step,
      groups: groups,
      cracked: cracked,
      falls: falls,
      points: points,
    ));
  }
}

/// All groups of at least [minSize] orthogonally connected same-colour orbs.
/// Shells and stones never belong to a group.
List<PoppedGroup> findGroups(Board board, int minSize) {
  final seen = <CellPos>{};
  final groups = <PoppedGroup>[];
  for (var row = 0; row < board.rows; row++) {
    for (var col = 0; col < board.columns; col++) {
      final start = (col: col, row: row);
      final cell = board.atPos(start);
      if (cell == null || !cell.isOrb || seen.contains(start)) continue;

      final members = <CellPos>[];
      final queue = [start];
      seen.add(start);
      while (queue.isNotEmpty) {
        final pos = queue.removeLast();
        members.add(pos);
        for (final n in _neighbours(board, pos)) {
          final other = board.atPos(n);
          if (other != null &&
              other.isOrb &&
              other.color == cell.color &&
              seen.add(n)) {
            queue.add(n);
          }
        }
      }
      if (members.length >= minSize) {
        groups.add(PoppedGroup(color: cell.color, cells: members));
      }
    }
  }
  return groups;
}

/// Drops every cell straight down to close gaps. Returns the moves made.
List<Fall> applyGravity(Board board) {
  final falls = <Fall>[];
  for (var col = 0; col < board.columns; col++) {
    var target = 0;
    for (var row = 0; row < board.rows; row++) {
      final cell = board.at(col, row);
      if (cell == null) continue;
      if (row != target) {
        board.set(col, target, cell);
        board.set(col, row, null);
        falls.add(Fall(column: col, fromRow: row, toRow: target, cell: cell));
      }
      target++;
    }
  }
  return falls;
}

Iterable<CellPos> _neighbours(Board board, CellPos p) sync* {
  if (p.col > 0) yield (col: p.col - 1, row: p.row);
  if (p.col < board.columns - 1) yield (col: p.col + 1, row: p.row);
  if (p.row > 0) yield (col: p.col, row: p.row - 1);
  if (p.row < board.rows - 1) yield (col: p.col, row: p.row + 1);
}
