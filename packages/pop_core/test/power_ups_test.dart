import 'package:pop_core/pop_core.dart';
import 'package:test/test.dart';

void main() {
  group('Power-ups', () {
    test('rainbow pop clears every ball of the current colour without using a drop', () {
      final game = Game(seed: 3, board: Board.parse('''
        R.....
        RG.B..
        GRBGR.
      '''), scriptedQueue: const [0, 1, 2]);
      expect(game.currentColor, 0);
      final moves = game.moves;
      final result = game.rainbowPop();
      expect(result.accepted, isTrue);
      expect(game.moves, moves, reason: 'not a drop');
      expect(game.board.toPicture().contains('R'), isFalse);
      expect(game.currentColor, 0, reason: 'the queue stays');
      final first = result.events.whereType<ChainStep>().first;
      expect(first.orbsPopped, 4);
      expect(result.points, greaterThan(0));
    });

    test('rainbow pop is refused when no ball has the colour', () {
      final game = Game(seed: 3, board: Board.parse('''
        GB....
      '''), scriptedQueue: const [0]);
      expect(game.rainbowPop().accepted, isFalse);
    });

    test('freeze holds the rising rows back for that many drops', () {
      final game = Game(seed: 5);
      final before = game.pressure;
      expect(game.freezeRows(5), isTrue);
      expect(game.pressure, before + 5);
      final still = Game(seed: 5, config: const RulesConfig(rowsRise: false));
      expect(still.freezeRows(5), isFalse, reason: 'nothing rises on a puzzle level');
    });

    test('extra drops only for a level with a drop limit', () {
      final limited = Game(seed: 5, dropLimit: 10);
      expect(limited.addDrops(5), isTrue);
      expect(limited.dropsLeft, 15);
      expect(Game(seed: 5).addDrops(5), isFalse);
    });
  });
}
