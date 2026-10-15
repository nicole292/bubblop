// Headless balance simulator. Plays many seeded games with a simple bot and
// prints how each rule configuration behaves.
//
//   cd packages/pop_core
//   dart run tool/simulate.dart            (300 games per config)
//   dart run tool/simulate.dart 1000
//
// The bot is a greedy one-move player (no deliberate chain building), so
// absolute numbers are lower than a skilled human's. Use it to COMPARE
// configurations, not to predict real scores.

import 'dart:math' as math;

import 'package:pop_core/pop_core.dart';

void main(List<String> args) {
  final games = args.isEmpty ? 300 : int.parse(args.first);
  final configs = <String, RulesConfig>{
    'shells 4-match (default)': const RulesConfig(),
    'stones 4-match': const RulesConfig(risingRowKind: RisingRowKind.stones),
    'start with 1 shell row': const RulesConfig(startRows: 1),
    'start with 2 shell rows': const RulesConfig(startRows: 2),
    '1 shell + 1 open row': const RulesConfig(startRows: 1, startOpenRows: 1),
    '1 shell + 2 open rows': const RulesConfig(startRows: 1, startOpenRows: 2),
    '1 shell + 2 open, pressure 9': const RulesConfig(startRows: 1, startOpenRows: 2, startPressure: 9),
  };

  print('Games per config: $games (seeds 1..$games)\n');
  print('${'config'.padRight(32)}  moves(med)  score(med)  pop%  chain/100  best  fill%  shell-fed%  lvl(med)  early-pop%');
  configs.forEach((name, config) {
    final r = _run(config, games);
    print('${name.padRight(32)}  '
        '${r.medianMoves.toString().padLeft(10)}  '
        '${r.medianScore.toString().padLeft(10)}  '
        '${r.popPct.toStringAsFixed(0).padLeft(4)}  '
        '${r.chainsPer100.toStringAsFixed(1).padLeft(9)}  '
        '${r.bestChain.toString().padLeft(4)}  '
        '${r.fillPct.toStringAsFixed(0).padLeft(5)}  '
        '${r.shellFedPct.toStringAsFixed(0).padLeft(10)}  '
        '${r.medianLevel.toString().padLeft(8)}  '
        '${r.earlyPopPct.toStringAsFixed(0).padLeft(10)}');
  });
}

class _Result {
  _Result(this.medianMoves, this.medianScore, this.popPct, this.chainsPer100,
      this.bestChain, this.fillPct, this.shellFedPct, this.medianLevel, this.earlyPopPct);
  final int medianMoves, medianScore, bestChain, medianLevel;
  final double popPct, chainsPer100, fillPct, shellFedPct;

  /// Games with a pop within the first 5 moves (the "fun in 10 seconds" test).
  final double earlyPopPct;
}

_Result _run(RulesConfig config, int games) {
  final moves = <int>[], scores = <int>[], levels = <int>[];
  var totalMoves = 0, popMoves = 0, chainMoves = 0, shellFed = 0, best = 0;
  var fillSum = 0.0;
  var earlyPops = 0;

  for (var seed = 1; seed <= games; seed++) {
    final game = Game(seed: seed, config: config);
    final bot = math.Random(seed);
    var poppedEarly = false;
    while (!game.isOver && game.moves < 3000) {
      final result = game.drop(_choose(game, bot));
      final steps = result.events.whereType<ChainStep>().toList();
      if (steps.isNotEmpty) popMoves++;
      if (steps.isNotEmpty && game.moves <= 5) poppedEarly = true;
      if (steps.length >= 2) {
        chainMoves++;
        if (steps.take(steps.length - 1).any((s) => s.cracked.values.any((c) => c.kind == CellKind.shell))) {
          shellFed++;
        }
      }
      best = math.max(best, steps.length);
      final board = game.board;
      var filled = 0;
      for (var c = 0; c < board.columns; c++) {
        filled += board.height(c);
      }
      fillSum += filled / (board.columns * board.rows);
    }
    if (poppedEarly) earlyPops++;
    totalMoves += game.moves;
    moves.add(game.moves);
    scores.add(game.score);
    levels.add(game.level);
  }
  int median(List<int> xs) => (xs..sort())[xs.length ~/ 2];
  return _Result(
    median(moves),
    median(scores),
    100 * popMoves / totalMoves,
    100 * chainMoves / totalMoves,
    best,
    100 * fillSum / totalMoves,
    chainMoves == 0 ? 0 : 100 * shellFed / chainMoves,
    median(levels),
    100 * earlyPops / games,
  );
}

/// Greedy: immediate points, plus building same-colour clusters, minus height.
int _choose(Game game, math.Random random) {
  final config = game.config;
  final color = game.currentColor;
  var bestColumn = 0;
  var bestValue = double.negativeInfinity;
  for (var col = 0; col < config.columns; col++) {
    if (!game.canDrop(col)) continue;
    final board = game.board;
    final row = board.height(col);
    board.set(col, row, Cell.orb(color));
    final steps = resolveChains(board, config);
    final points = steps.fold(0, (sum, s) => sum + s.points);

    var friends = 0;
    if (steps.isEmpty) {
      for (final (dc, dr) in const [(-1, 0), (1, 0), (0, -1)]) {
        final c = col + dc, r = row + dr;
        if (c < 0 || c >= config.columns || r < 0) continue;
        final n = board.at(c, r);
        if (n != null && n.isOrb && n.color == color) friends++;
      }
    }
    var maxHeight = 0;
    for (var c = 0; c < config.columns; c++) {
      maxHeight = math.max(maxHeight, board.height(c));
    }
    final value = points + friends * 25 - maxHeight * maxHeight * 3 - board.height(col) * 4 + random.nextDouble();
    if (value > bestValue) {
      bestValue = value;
      bestColumn = col;
    }
  }
  return bestColumn;
}
