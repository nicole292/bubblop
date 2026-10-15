import 'package:flutter_test/flutter_test.dart';
import 'package:pop_core/pop_core.dart';
import 'package:project_pop/game/session_stats.dart';

void main() {
  test('counts chains and shell-fed chains, reports per mode', () {
    final stats = SessionStats()..startRound(const RulesConfig());

    // A 2-step chain fed by a cracked shell (same board as the pop_core test).
    final game = Game(
      seed: 1,
      board: Board.parse('''
        RrR...
        RGGG.B
      '''),
      scriptedQueue: [2],
    );
    stats.recordMove(game.drop(4));
    final summary = stats.finishRound(score: game.score, moves: game.moves);

    expect(summary.longestChain, 2);
    expect(summary.chainMoves, 1);
    expect(summary.shellChainMoves, 1);
    expect(stats.bestScore, game.score);
    expect(stats.report(), contains('[shells, 4-match] rounds: 1'));
  });
}
