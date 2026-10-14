import 'package:pop_core/pop_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('randomness', () {
    test('the same seed gives the same sequence', () {
      final a = SeededRandom(42), b = SeededRandom(42);
      expect([for (var i = 0; i < 20; i++) a.nextInt(5)],
          [for (var i = 0; i < 20; i++) b.nextInt(5)]);
    });

    test('nearby seeds give different sequences', () {
      final a = SeededRandom(1), b = SeededRandom(2);
      expect([for (var i = 0; i < 20; i++) a.nextInt(5)],
          isNot([for (var i = 0; i < 20; i++) b.nextInt(5)]));
    });

    test('every bag contains each colour exactly twice', () {
      final bag = ColorBag(SeededRandom(7));
      for (var round = 0; round < 5; round++) {
        final dealt = [for (var i = 0; i < 8; i++) bag.next(4)]..sort();
        expect(dealt, [0, 0, 1, 1, 2, 2, 3, 3]);
      }
    });

    test('two games with the same seed play identically', () {
      String play(int seed) {
        final game = Game(seed: seed);
        for (var i = 0; i < 60 && !game.isOver; i++) {
          game.drop(i % 6);
        }
        return '${game.board.toPicture()}|${game.score}|${game.moves}';
      }

      expect(play(123), play(123));
    });
  });

  group('drops', () {
    test('the queue shows current + 2 and advances on each drop', () {
      final game = gameOn('', queue: [r, y, g, b]);
      expect(game.queue, [r, y, g]);
      game.drop(0);
      expect(game.queue, [y, g, b]);
      expect(game.board.at(0, 0), const Cell.orb(r));
    });

    test('an orb lands on top of the column stack', () {
      final game = gameOn('''
        Y.....
        B.....
      ''', queue: [g]);
      expect(game.landingRow(0), 2);
      final dropped = game.drop(0).events.first as OrbDropped;
      expect(dropped.row, 2);
    });

    test('dropping into a full column is rejected and changes nothing', () {
      final full = List.filled(10, 'RYRYRY').join('\n');
      final game = gameOn(full.replaceFirst('RYRYRY', 'RYRYR.'), queue: [g, b]);
      final before = game.board.toPicture();
      final result = game.drop(0);
      expect(result.accepted, isFalse);
      expect(game.board.toPicture(), before);
      expect(game.queue.first, g);
      expect(game.moves, 0);
      expect(game.canDrop(0), isFalse);
      expect(game.landingRow(0), isNull);
    });

    test('out-of-range columns are rejected', () {
      final game = gameOn('');
      expect(game.drop(-1).accepted, isFalse);
      expect(game.drop(6).accepted, isFalse);
    });
  });

  group('pressure and rising rows', () {
    const fast = RulesConfig(startPressure: 3, minPressure: 1);

    test('a shell row rises after the countdown and pushes everything up', () {
      final game = gameOn('', queue: [r, y, g, b, r, y], config: fast);
      game.drop(0);
      game.drop(1);
      expect(game.pressure, 1);
      final events = game.drop(2).events;
      final rose = events.whereType<RowRose>().single;
      expect(rose.row.every((c) => c.kind == CellKind.shell), isTrue);
      expect(game.board.at(0, 1), const Cell.orb(r));
      expect(game.board.at(0, 0)!.kind, CellKind.shell);
      expect(game.pressure, 3);
    });

    test('stone mode raises stones', () {
      final game = gameOn('',
          queue: [r],
          config: const RulesConfig(
              startPressure: 1, minPressure: 1, risingRowKind: RisingRowKind.stones));
      final rose = game.drop(0).events.whereType<RowRose>().single;
      expect(rose.row, everyElement(const Cell.stone()));
    });

    test('the row rises only after the whole chain resolves', () {
      final game = gameOn('RRR..B',
          queue: [r], config: const RulesConfig(startPressure: 1, minPressure: 1));
      final events = game.drop(3).events;
      expect(events.indexWhere((e) => e is RowRose),
          greaterThan(events.lastIndexWhere((e) => e is ChainStep)));
    });

    test('pressure interval shrinks with level but not below the minimum', () {
      const config = RulesConfig();
      expect(config.pressureInterval(1), 8);
      expect(config.pressureInterval(3), 6);
      expect(config.pressureInterval(20), 4);
    });
  });

  group('game over', () {
    test('a row rising under a full column ends the game', () {
      final column = List.filled(5, 'R.....\nY.....').join('\n');
      final game = gameOn(column,
          queue: [b, b], config: const RulesConfig(startPressure: 1, minPressure: 1));
      final events = game.drop(1).events;
      expect(events.last, isA<GameOver>());
      expect((events.last as GameOver).reason, GameOverReason.overflow);
      expect(events.whereType<RowRose>(), isEmpty);
      expect(game.isOver, isTrue);
      expect(game.drop(2).accepted, isFalse);
    });

    test('filling the last cell ends the game', () {
      // Colour (col + 2·row) % 4 never puts two equal colours side by side.
      final lines = [
        for (var row = 9; row >= 0; row--)
          [
            for (var col = 0; col < 6; col++)
              row == 9 && col == 5 ? '.' : colorLetters[(col + 2 * row) % 4],
          ].join(),
      ];
      final game = gameOn(lines.join('\n'), queue: [(5 + 18) % 4]);
      final result = game.drop(5);
      expect(stepsOf(result), isEmpty);
      expect((result.events.last as GameOver).reason, GameOverReason.boardFull);
      expect(game.isOver, isTrue);
    });
  });

  group('score and progress', () {
    test('clearing the whole board earns the bonus', () {
      final game = gameOn('RRR...', queue: [r]);
      final result = game.drop(3);
      expect(result.events.whereType<BoardCleared>().single.bonus, 1000);
      expect(game.score, 40 + 1000);
    });

    test('clearing enough orbs levels up', () {
      final game = gameOn('RRR..B',
          queue: [r], config: const RulesConfig(orbsPerLevel: 4));
      final result = game.drop(3);
      expect(result.events.whereType<LevelUp>().single.level, 2);
      expect(game.level, 2);
      expect(game.orbsCleared, 4);
    });

    test('a fifth colour is dealt from the extra-colour level', () {
      const config = RulesConfig();
      expect(config.colorsForLevel(3), 4);
      expect(config.colorsForLevel(4), 5);
    });

    test('a restart is just a new Game: same seed, fresh state', () {
      final first = Game(seed: 9);
      final firstQueue = first.queue;
      first.drop(0);
      final restarted = Game(seed: 9);
      expect(restarted.queue, firstQueue);
      expect(restarted.score, 0);
      expect(restarted.moves, 0);
      expect(restarted.board.isEmpty, isTrue);
    });
  });
}
