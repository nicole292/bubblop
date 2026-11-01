import 'package:pop_core/pop_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('bombs on the board', () {
    test(
      'a pop beside a bomb sets it off and clears the 3×3 square around it',
      () {
        // Red at column 3 completes the four reds; the bomb above column 1 goes
        // off and takes the balls around it.
        final game = gameOn(
          '''
        YBG...
        G*Y...
        RRR...
      ''',
          queue: [r],
        );
        final result = game.drop(3);
        final step = stepsOf(result).first;
        expect(step.groups.single.cells, hasLength(4));
        expect(step.blasts, hasLength(1));
        expect(step.blasts.single.center, (col: 1, row: 1));
        // Bomb, its two side balls and the three balls above it.
        expect(step.blasts.single.cleared, hasLength(6));
        expect(step.orbsBlasted, 5);
        expect(game.board.isEmpty, isTrue);
        expect(game.orbsCleared, 9);
      },
    );

    test('a bomb caught in a blast goes off too', () {
      final game = gameOn(
        '''
        ...Y..
        G**...
        RRR...
      ''',
        queue: [r],
      );
      final step = stepsOf(game.drop(3)).first;
      expect(step.blasts.map((b) => b.center), [
        (col: 1, row: 1),
        (col: 2, row: 1),
      ]);
      expect(
        game.board.isEmpty,
        isTrue,
        reason: 'the second blast reaches the yellow at column 3',
      );
    });

    test('a blast breaks shells and stones instead of cracking them', () {
      final game = gameOn(
        '''
        y#....
        *.....
        RRR...
      ''',
        queue: [r],
      );
      final step = stepsOf(game.drop(3)).first;
      expect(step.shellsBroken, 1);
      expect(game.board.isEmpty, isTrue);
    });

    test('blasted cells score points', () {
      final quiet = gameOn('RRR...', queue: [r]).drop(3).points;
      final loud = gameOn(
        '''
        Y.....
        *.....
        RRR...
      ''',
        queue: [r],
      ).drop(3).points;
      // The bomb's own cell does not count; the yellow above it does.
      expect(loud - quiet, blastCellPoints);
    });
  });

  group("the player's bombs", () {
    test(
      'a dropped bomb clears the square where it lands, then the board chains',
      () {
        // The bomb lands on column 2 and clears the greens, so the reds fall
        // together and pop as step 2.
        final game = gameOn(
          '''
        .RG...
        RGGR..
        RYYRR.
      ''',
          queue: [b],
        );
        final result = game.dropBomb(2);
        expect(result.accepted, isTrue);
        expect(result.events.first, isA<BombDropped>());
        final steps = stepsOf(result);
        expect(steps.first.step, 1);
        expect(steps.first.groups, isEmpty);
        expect(steps.first.blasts.single.center, (col: 2, row: 3));
        expect(game.queue.first, b, reason: 'the ball queue is untouched');
        expect(game.moves, 1);
      },
    );

    test('a bomb fits a full column and goes off on its top cell', () {
      const config = RulesConfig(rows: 3);
      final game = gameOn('''
        R.....
        Y.....
        G.....
      ''', config: config);
      expect(game.canDrop(0), isFalse);
      final result = game.dropBomb(0);
      expect(result.accepted, isTrue);
      expect(stepsOf(result).first.blasts.single.center, (col: 0, row: 2));
      expect(bottom(game, 1), 'G.....');
    });

    test('a bomb is rejected after the round ends or outside the board', () {
      final game = gameOn('R.....');
      expect(game.dropBomb(-1).accepted, isFalse);
      expect(game.dropBomb(6).accepted, isFalse);
    });
  });

  group('bomb rows', () {
    test('every bombEvery-th rising row carries exactly one bomb', () {
      final game = Game(
        seed: 5,
        config: const RulesConfig(bombEvery: 2, startRows: 0, startOpenRows: 0),
      );
      final risen = <List<Cell>>[];
      for (var i = 0; i < 200 && !game.isOver && risen.length < 6; i++) {
        // Spread the drops so no column fills up.
        final column = [for (var c = 0; c < 6; c++) (i + c) % 6]
            .firstWhere(game.canDrop);
        risen.addAll(
          game.drop(column).events.whereType<RowRose>().map((e) => e.row),
        );
      }
      expect(risen.length, greaterThanOrEqualTo(4));
      for (final (i, row) in risen.indexed) {
        expect(
          row.where((c) => c.isBomb).length,
          i.isOdd ? 1 : 0,
          reason: 'row ${i + 1}',
        );
      }
    });

    test('rounds without bombs deal exactly the rows they always did', () {
      String rows(RulesConfig config) {
        final game = Game(seed: 9, config: config);
        return game.board.toPicture() + game.nextRow.join();
      }

      expect(rows(const RulesConfig()), rows(const RulesConfig(bombEvery: 0)));
    });
  });
}
