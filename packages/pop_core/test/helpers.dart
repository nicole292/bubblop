import 'package:pop_core/pop_core.dart';

const r = 0, y = 1, g = 2, b = 3, p = 4;

/// A game on a hand-drawn board (see [Board.parse]) with a fixed queue.
Game gameOn(
  String picture, {
  List<int> queue = const [],
  RulesConfig config = const RulesConfig(),
  int seed = 1,
}) =>
    Game(
      seed: seed,
      config: config,
      board: Board.parse(picture, columns: config.columns, rows: config.rows),
      scriptedQueue: queue,
    );

List<ChainStep> stepsOf(MoveResult result) =>
    result.events.whereType<ChainStep>().toList();

/// The bottom [lines] rows of the board as a picture, for short assertions.
String bottom(Game game, int lines) =>
    game.board.toPicture().split('\n').reversed.take(lines).toList().reversed.join('\n');
