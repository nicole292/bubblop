import 'dart:math' as math;

import 'board.dart';
import 'cell.dart';
import 'color_bag.dart';
import 'events.dart';
import 'random.dart';
import 'resolver.dart';
import 'rules_config.dart';
import 'scoring.dart';

/// The outcome of one [Game.drop] call.
class MoveResult {
  const MoveResult.rejected()
      : accepted = false,
        events = const [],
        points = 0;

  const MoveResult(this.events, this.points) : accepted = true;

  /// False when the drop was illegal (full column, game over, bad index).
  /// A rejected drop changes nothing.
  final bool accepted;
  final List<GameEvent> events;
  final int points;
}

/// One round of Project POP. All gameplay state lives here; the app reads it
/// and animates the events returned by [drop]. To restart, create a new Game.
class Game {
  Game({
    required this.seed,
    this.config = const RulesConfig(),
    Board? board,
    List<int> scriptedQueue = const [],
    this.dropLimit,
    String? layout,
  })  : _board = board?.copy() ?? Board(config.columns, config.rows),
        _bag = ColorBag(SeededRandom(seed)),
        // Rising rows use their own generator so they never shift which
        // colours the player is dealt.
        _rowRandom = SeededRandom(seed ^ 0x5BD1E995),
        _script = List.of(scriptedQueue) {
    if (_board.columns != config.columns || _board.rows != config.rows) {
      throw ArgumentError('Board size does not match RulesConfig');
    }
    _pressure = config.pressureInterval(_level);
    while (_queue.length < config.previewLength) {
      _queue.add(_nextColor());
    }
    _nextRow = _generateRow();
    // A fresh round (no board given) starts with some rows already risen,
    // or with a level's hand-built [layout].
    if (board == null && layout != null) {
      _placeLayout(layout);
    } else if (board == null) {
      for (var i = 0; i < config.startRows; i++) {
        _raiseRow();
      }
      _placeOpenRows();
    }
  }

  /// Builds the starting board from a level layout, top line first like
  /// [Board.parse]: `o` a ball and `s` a shell of a dealt colour, `#` a
  /// stone, `*` a bomb, `.` empty, or a fixed cell in [Board.parse]
  /// letters. Balls are re-dealt until no group is already complete.
  void _placeLayout(String layout) {
    final lines = layout
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final colorCount = config.colorsForLevel(_level);
    for (var i = lines.length - 1; i >= 0; i--) {
      final row = lines.length - 1 - i;
      for (var col = 0; col < config.columns; col++) {
        final ch = lines[i][col];
        switch (ch) {
          case '.':
            break;
          case 'o':
            for (var attempt = 0; attempt < 12; attempt++) {
              _board.set(col, row, Cell.orb(_rowRandom.nextInt(colorCount)));
              if (findGroups(_board, config.matchSize).isEmpty) break;
            }
          case 's':
            _board.set(col, row, Cell.shell(_rowRandom.nextInt(colorCount)));
          default:
            _board.set(col, row, Board.parse(ch, columns: 1, rows: 1).at(0, 0));
        }
      }
    }
  }

  /// Lays [RulesConfig.startOpenRows] rows of ordinary balls on top, retrying
  /// colours until no group is already complete.
  void _placeOpenRows() {
    final colorCount = config.colorsForLevel(_level);
    for (var r = 0; r < config.startOpenRows; r++) {
      for (var col = 0; col < config.columns; col++) {
        final row = _board.height(col);
        if (row >= config.rows) continue;
        for (var attempt = 0; attempt < 12; attempt++) {
          _board.set(col, row, Cell.orb(_rowRandom.nextInt(colorCount)));
          if (findGroups(_board, config.matchSize).isEmpty) break;
        }
        if (findGroups(_board, config.matchSize).isNotEmpty) _board.set(col, row, null);
      }
    }
  }

  final int seed;
  final RulesConfig config;

  /// A level's number of drops; the round ends when they are used up.
  /// Null: no limit (Endless).
  final int? dropLimit;

  final Board _board;
  final ColorBag _bag;
  final SeededRandom _rowRandom;
  final List<int> _script;
  final List<int> _queue = [];

  int _score = 0;
  int _level = 1;
  int _orbsCleared = 0;
  int _moves = 0;
  late int _pressure;
  late List<Cell> _nextRow;
  bool _isOver = false;

  /// A copy of the board; changing it does not affect the game.
  Board get board => _board.copy();
  int get score => _score;
  int get level => _level;
  int get orbsCleared => _orbsCleared;
  int get moves => _moves;

  /// Drops left before [dropLimit] ends the round, or null without a limit.
  int? get dropsLeft => dropLimit == null ? null : math.max(0, dropLimit! - _moves);

  /// Drops remaining until the next row rises.
  int get pressure => _pressure;

  /// The row that will rise next, left to right. Shown to the player so
  /// they can plan around its colours.
  List<Cell> get nextRow => List.unmodifiable(_nextRow);
  bool get isOver => _isOver;

  /// The current orb first, then the upcoming ones.
  List<int> get queue => List.unmodifiable(_queue);
  int get currentColor => _queue.first;

  bool canDrop(int column) =>
      !_isOver &&
      column >= 0 &&
      column < config.columns &&
      !_board.isColumnFull(column);

  /// The row the current orb would land in, or null if [column] is not legal.
  int? landingRow(int column) => canDrop(column) ? _board.height(column) : null;

  /// Whether one of the player's bombs can go into [column]. Unlike a ball,
  /// a bomb also fits a full column: it goes off on the top cell.
  bool canBomb(int column) =>
      !_isOver && column >= 0 && column < config.columns;

  MoveResult drop(int column) {
    if (!canDrop(column)) return const MoveResult.rejected();

    final events = <GameEvent>[];
    _moves++;

    final color = _queue.removeAt(0);
    _queue.add(_nextColor());
    final row = _board.height(column);
    _board.set(column, row, Cell.orb(color));
    events.add(OrbDropped(column: column, row: row, color: color));

    return _settle(events, resolveChains(_board, config));
  }

  /// Drops one of the player's bombs into [column]. It goes off where it
  /// lands, clearing the 3×3 square around it (bombs in range go off too),
  /// then everything falls and chains as usual. Uses a drop like a ball, but
  /// leaves the ball queue alone.
  MoveResult dropBomb(int column) {
    if (!canBomb(column)) return const MoveResult.rejected();

    final events = <GameEvent>[];
    _moves++;
    final row = math.min(_board.height(column), config.rows - 1);
    events.add(BombDropped(column: column, row: row));
    final blasts = detonate(_board, [(col: column, row: row)]);
    final falls = applyGravity(_board);
    final steps = [
      ChainStep(
        step: 1,
        groups: const [],
        cracked: const {},
        falls: falls,
        points: chainStepPoints(
            groupSizes: const [],
            distinctColors: 0,
            cracked: 0,
            step: 1,
            blasted: blastedCount(blasts)),
        blasts: blasts,
      ),
      ...resolveChains(_board, config, firstStep: 2),
    ];
    return _settle(events, steps);
  }

  /// Scores [steps], then levels, rising rows and the end of the round, as
  /// after every drop.
  MoveResult _settle(List<GameEvent> events, List<ChainStep> steps) {
    var points = 0;
    for (final step in steps) {
      points += step.points;
      _orbsCleared += step.orbsPopped + step.orbsBlasted;
      events.add(step);
    }

    if (steps.isNotEmpty && _board.isEmpty) {
      final bonus = boardClearBonus(_level);
      points += bonus;
      events.add(BoardCleared(bonus));
    }

    final newLevel = 1 + _orbsCleared ~/ config.orbsPerLevel;
    if (newLevel > _level) {
      _level = newLevel;
      events.add(LevelUp(_level));
    }

    final interval = config.pressureInterval(_level);
    if (steps.length >= 2 && config.chainRelief > 0) {
      _pressure = math.min(_pressure + config.chainRelief, interval);
    }
    // Rows that stay still never count down.
    if (config.rowsRise) _pressure--;
    if (!config.rowsRise) {
      // Nothing rises.
    } else if (_pressure <= 0 && steps.isNotEmpty && _anyColumnFull()) {
      // The row would push a full column off the top, but this drop popped:
      // it waits one more drop, a last chance to make room.
      _pressure = 1;
    } else if (_pressure <= 0) {
      _pressure = config.pressureInterval(_level);
      if (_anyColumnFull()) {
        _isOver = true;
        events.add(const GameOver(GameOverReason.overflow));
      } else {
        events.add(RowRose(_raiseRow()));
      }
    }

    if (!_isOver && _board.isFull) {
      _isOver = true;
      events.add(const GameOver(GameOverReason.boardFull));
    }

    if (!_isOver && dropsLeft == 0) {
      _isOver = true;
      events.add(const GameOver(GameOverReason.outOfDrops));
    }

    _score += points;
    return MoveResult(events, points);
  }

  int _nextColor() => _script.isNotEmpty
      ? _script.removeAt(0)
      : _bag.next(config.colorsForLevel(_level));

  bool _anyColumnFull() {
    for (var c = 0; c < config.columns; c++) {
      if (_board.isColumnFull(c)) return true;
    }
    return false;
  }

  /// Rows are generated one rise ahead so [nextRow] can be shown. A level-up
  /// therefore affects the row after the one already previewed. Every
  /// [RulesConfig.bombEvery]th row carries one bomb.
  List<Cell> _generateRow() {
    final colorCount = config.colorsForLevel(_level);
    final row = [
      for (var c = 0; c < config.columns; c++)
        config.risingRowKind == RisingRowKind.shells
            ? Cell.shell(_rowRandom.nextInt(colorCount))
            : const Cell.stone(),
    ];
    _rowsMade++;
    // Only draws from the generator when bombs are on, so other rounds deal
    // exactly the same rows as before.
    if (config.bombEvery > 0 && _rowsMade % config.bombEvery == 0) {
      row[_rowRandom.nextInt(config.columns)] = const Cell.bomb();
    }
    return row;
  }

  int _rowsMade = 0;

  List<Cell> _raiseRow() {
    final newRow = _nextRow;
    _nextRow = _generateRow();
    for (var c = 0; c < config.columns; c++) {
      for (var r = config.rows - 1; r > 0; r--) {
        _board.set(c, r, _board.at(c, r - 1));
      }
      _board.set(c, 0, newRow[c]);
    }
    return newRow;
  }
}
