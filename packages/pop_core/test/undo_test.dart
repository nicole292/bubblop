import 'package:pop_core/pop_core.dart';
import 'package:test/test.dart';

String describe(Game g) => [
      g.board.toPicture(),
      g.score,
      g.moves,
      g.level,
      g.pressure,
      g.queue.join(),
      g.nextRow.map((c) => '${c.kind.name}${c.color}').join(),
      g.isOver,
      g.dropsLeft,
    ].join('|');

void main() {
  test('restoring a snapshot puts the round back exactly, and the future plays out the same', () {
    for (final level in [Campaign.level(1), Campaign.level(33), Campaign.level(120)]) {
      final game = level.newGame();
      // Some moves first.
      for (final c in [0, 1, 2, 3, 4, 5, 0, 1]) {
        if (game.canDrop(c)) game.drop(c);
      }
      final saved = game.snapshot();
      final before = describe(game);
      final moves = [2, 3, 2, 3, 5, 1, 0, 4, 4, 2, 3, 1];
      final first = <String>[];
      for (final c in moves) {
        if (game.canDrop(c)) game.drop(c);
        first.add(describe(game));
      }
      game.restore(saved);
      expect(describe(game), before, reason: 'level ${level.number}');
      final second = <String>[];
      for (final c in moves) {
        if (game.canDrop(c)) game.drop(c);
        second.add(describe(game));
      }
      expect(second, first, reason: 'level ${level.number}: the same balls and rows come again');
    }
  });

  test('undo also brings back a round that just ended', () {
    final game = Game(seed: 2, dropLimit: 3);
    late GameSnapshot saved;
    for (var i = 0; i < 3; i++) {
      saved = game.snapshot();
      game.drop(i);
    }
    expect(game.isOver, isTrue);
    game.restore(saved);
    expect(game.isOver, isFalse);
    expect(game.dropsLeft, 1);
  });
}
