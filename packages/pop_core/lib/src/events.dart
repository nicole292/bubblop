import 'cell.dart';

/// Something that happened during a move, in order. The app animates these;
/// they never feed back into the rules.
sealed class GameEvent {
  const GameEvent();
}

class OrbDropped extends GameEvent {
  const OrbDropped({required this.column, required this.row, required this.color});
  final int column;
  final int row;
  final int color;
}

class PoppedGroup {
  const PoppedGroup({required this.color, required this.cells});
  final int color;
  final List<CellPos> cells;
}

/// A cell that moved straight down during gravity.
class Fall {
  const Fall({required this.column, required this.fromRow, required this.toRow, required this.cell});
  final int column;
  final int fromRow;
  final int toRow;
  final Cell cell;
}

/// A bomb going off at [center] and everything it cleared, with what each
/// cell held. Other bombs in range go off as their own [Blast].
class Blast {
  const Blast({required this.center, required this.cleared});
  final CellPos center;
  final Map<CellPos, Cell> cleared;
}

/// The player dropped one of their bombs; it goes off where it lands
/// ([row] is the top cell when the column was full).
class BombDropped extends GameEvent {
  const BombDropped({required this.column, required this.row});
  final int column;
  final int row;
}

/// One round of pop → crack → blast → gravity. [step] starts at 1. A dropped
/// bomb's own blast is step 1 with no [groups].
class ChainStep extends GameEvent {
  const ChainStep({
    required this.step,
    required this.groups,
    required this.cracked,
    required this.falls,
    required this.points,
    this.blasts = const [],
  });
  final int step;
  final List<PoppedGroup> groups;

  /// Bombs that went off this step, in the order they were set off.
  final List<Blast> blasts;

  /// Shells/stones next to a popped orb, with what they were before cracking.
  final Map<CellPos, Cell> cracked;
  final List<Fall> falls;
  final int points;

  int get orbsPopped => groups.fold(0, (sum, g) => sum + g.cells.length);

  /// Balls (not shells, stones or bombs) cleared by blasts.
  int get orbsBlasted => blasts.fold(
      0, (sum, b) => sum + b.cleared.values.where((c) => c.isOrb).length);

  /// Shells cracked open or blasted away.
  int get shellsBroken =>
      cracked.values.where((c) => c.kind == CellKind.shell).length +
      blasts.fold(
          0,
          (sum, b) =>
              sum +
              b.cleared.values.where((c) => c.kind == CellKind.shell).length);
}

class BoardCleared extends GameEvent {
  const BoardCleared(this.bonus);
  final int bonus;
}

/// A new bottom row rose and pushed everything up by one.
class RowRose extends GameEvent {
  const RowRose(this.row);
  final List<Cell> row;
}

class LevelUp extends GameEvent {
  const LevelUp(this.level);
  final int level;
}

enum GameOverReason {
  /// A rising row would have pushed a cell off the top.
  overflow,

  /// Every column is full.
  boardFull,

  /// A level's drop limit was used up ([Game.dropLimit]).
  outOfDrops,
}

class GameOver extends GameEvent {
  const GameOver(this.reason);
  final GameOverReason reason;
}
