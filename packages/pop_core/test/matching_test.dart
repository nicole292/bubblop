import 'package:pop_core/pop_core.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('matching', () {
    test('4 in a row horizontally pops', () {
      final game = gameOn('RRR..B', queue: [r]);
      final steps = stepsOf(game.drop(3));
      expect(steps, hasLength(1));
      expect(steps.single.orbsPopped, 4);
      expect(bottom(game, 1), '.....B');
    });

    test('4 in a column pops', () {
      final game = gameOn('''
        R....B
        R....B
        R....B
      ''', queue: [r]);
      expect(stepsOf(game.drop(0)).single.orbsPopped, 4);
      expect(game.board.height(0), 0);
    });

    test('3 connected does not pop', () {
      final game = gameOn('RR...B', queue: [r]);
      expect(stepsOf(game.drop(2)), isEmpty);
      expect(bottom(game, 1), 'RRR..B');
    });

    test('diagonal neighbours do not connect', () {
      final game = gameOn('''
        .RR...
        RBG...
      ''', queue: [r]);
      expect(stepsOf(game.drop(3)), isEmpty);
    });

    test('an L-shaped group of 5 pops as one group', () {
      final game = gameOn('''
        R.....
        RRR..B
      ''', queue: [r]);
      final step = stepsOf(game.drop(3)).single;
      expect(step.groups, hasLength(1));
      expect(step.groups.single.cells, hasLength(5));
      expect(step.points, groupPoints(5));
    });

    test('shells never join a group', () {
      final game = gameOn('RRr..B', queue: [r]);
      expect(stepsOf(game.drop(3)), isEmpty);
    });

    test('matchSize is configurable (3-match experiment)', () {
      final game = gameOn('RR...B',
          queue: [r], config: const RulesConfig(matchSize: 3));
      expect(stepsOf(game.drop(2)).single.orbsPopped, 3);
    });
  });

  group('chains', () {
    test('orbs falling after a pop can form the next group', () {
      // Dropping G at col 4 pops the bottom G row; the R row falls onto the
      // floor next to the R at col 0 and pops as step 2.
      final game = gameOn('''
        .RRR..
        RGGG.B
      ''', queue: [g]);
      final steps = stepsOf(game.drop(4));
      expect(steps.map((s) => s.step), [1, 2]);
      expect(steps[0].points, 40); // 4 orbs × step² 1
      expect(steps[1].points, 160); // 4 orbs × step² 4
      expect(game.score, 200);
      expect(bottom(game, 1), '.....B');
    });

    test('a cracked shell becomes an orb and continues the chain', () {
      final game = gameOn('''
        RrR...
        RGGG.B
      ''', queue: [g]);
      final steps = stepsOf(game.drop(4));
      expect(steps, hasLength(2));
      expect(steps[0].cracked, {(col: 1, row: 1): const Cell.shell(r)});
      expect(steps[0].points, 40 + 5);
      expect(steps[1].groups.single.color, r);
      expect(steps[1].points, 160);
      expect(bottom(game, 1), '.....B');
    });

    test('a cracked stone vanishes and gives no colour', () {
      final game = gameOn('''
        R#R...
        RGGG.B
      ''', queue: [g]);
      final steps = stepsOf(game.drop(4));
      expect(steps, hasLength(1));
      expect(steps.single.cracked.values.single, const Cell.stone());
      expect(bottom(game, 2), 'R.....\nR.R..B');
    });

    test('shells only crack from orthogonal neighbours', () {
      final game = gameOn('''
        .....r
        RRR..B
      ''', queue: [r]);
      final step = stepsOf(game.drop(3)).single;
      expect(step.cracked, isEmpty);
      expect(game.board.at(5, 1), const Cell.shell(r));
    });

    test('a 3-step chain fed by a cracked shell scores 1×, 4×, 9×', () {
      // Found by search: dropping B completes the bottom row, which cracks
      // the green shell and sets off two more steps.
      final game = gameOn('''
        GG....
        YRR...
        RgGR..
        RBBB..
      ''', queue: [b]);
      final steps = stepsOf(game.drop(4));
      expect(steps.map((s) => s.step), [1, 2, 3]);
      expect(steps[0].cracked.values.single, const Cell.shell(g));
      expect(steps.map((s) => s.points), [40 + 5, 40 * 4, 40 * 9]);
      expect(game.score, 45 + 160 + 360);
    });

    test('a shell touching several popped orbs cracks once and scores once', () {
      final game = gameOn('''
        .r....
        RRR..B
      ''', queue: [r]);
      final step = stepsOf(game.drop(3)).single;
      expect(step.cracked, hasLength(1));
      expect(step.points, 40 + 5);
    });

    test('shells and stones fall with gravity like orbs', () {
      final game = gameOn('''
        .#....
        .y....
        .B....
        RRR..B
      ''', queue: [r]);
      final step = stepsOf(game.drop(3)).single;
      expect(step.cracked, isEmpty, reason: 'only the B orb touches the pop');
      expect(bottom(game, 3), '.#....\n.y....\n.B...B');
    });

    test('gravity reports every fall', () {
      final game = gameOn('''
        Y.....
        RRR..B
      ''', queue: [r]);
      final step = stepsOf(game.drop(3)).single;
      expect(step.falls.single.column, 0);
      expect(step.falls.single.fromRow, 1);
      expect(step.falls.single.toRow, 0);
    });
  });
}
