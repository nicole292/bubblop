import 'package:pop_core/pop_core.dart';

/// The guided first round. The opening board is set up so that the very
/// first drop (blue, into column 5) sets off a 3-step chain that frees a
/// shell's ball: the most satisfying thing in the game, in the first
/// seconds. After that it continues as a normal round.
abstract final class Tutorial {
  static const dropColumn = 4;

  static Game game(RulesConfig config, int seed) => Game(
        seed: seed,
        config: config,
        board: Board.parse(board),
        // Blue until the lesson lands: a miss never touches the bottom row,
        // so the next blue in the same column still makes the match.
        scriptedQueue: const [3, 3, 3],
      );

  static const board = '''
    GG....
    YRR...
    RgGR..
    RBBB..
  ''';

  static const dropHint = 'Drop the blue ball here to make 4 in a row!';
  static const chainHint = 'Chain reaction! Popping next to a bubble frees the ball inside.';
  static const riseHint = 'A new row rises from below soon. Keep the balls under the top!';
  static const retryHint = 'Almost! Try dropping it here.';
}

enum TutorialStep { off, drop, chain, waitForRise, rise }
