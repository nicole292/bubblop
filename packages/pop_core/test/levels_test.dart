import 'package:pop_core/pop_core.dart';
import 'package:test/test.dart';

import 'level_solutions.dart';

void main() {
  group('LevelTracker', () {
    test('counts score, popped balls and the longest chain from moves', () {
      // The 3-step chain board from game_test: column 5 sets it off.
      final game = Game(
        seed: 1,
        board: Board.parse('''
          GG....
          YRR...
          RgGR..
          RBBB..
        '''),
        scriptedQueue: const [3],
      );
      final tracker = LevelTracker(const LevelDef(0, 1, [LevelGoal.chain(3)]));
      final result = game.drop(4);
      tracker.record(result);

      final steps = result.events.whereType<ChainStep>().toList();
      expect(tracker.score, result.points);
      expect(tracker.score, game.score);
      expect(tracker.popped, steps.fold(0, (sum, s) => sum + s.orbsPopped));
      expect(tracker.popped, game.orbsCleared);
      expect(tracker.bestChain, steps.length);
    });

    test('the longest chain is kept; a later shorter chain does not lower it', () {
      final tracker = LevelTracker(const LevelDef(0, 1, [LevelGoal.chain(2)]));
      tracker.bestChain = 3;
      tracker.record(const MoveResult([], 0));
      expect(tracker.bestChain, 3);
    });

    test('rejected moves change nothing', () {
      final tracker = LevelTracker(const LevelDef(0, 1, [LevelGoal.pop(4)]));
      tracker.record(const MoveResult.rejected());
      expect((tracker.score, tracker.popped, tracker.bestChain), (0, 0, 0));
    });

    test('a level is complete only when every goal is met', () {
      final tracker = LevelTracker(const LevelDef(0, 1, [LevelGoal.score(100), LevelGoal.chain(2)]));
      expect(tracker.complete, isFalse);
      tracker.score = 150;
      expect(tracker.complete, isFalse, reason: 'chain still missing');
      tracker.bestChain = 2;
      expect(tracker.complete, isTrue);
    });

    test('progress never shows more than the target', () {
      final tracker = LevelTracker(const LevelDef(0, 1, [LevelGoal.pop(10)]))..popped = 37;
      expect(tracker.progress(tracker.level.goals.single), 10);
    });

    test('goal wording', () {
      expect(const LevelGoal.score(600).text, 'Score 600 points');
      expect(const LevelGoal.pop(40).text, 'Pop 40 balls');
      expect(const LevelGoal.chain(3).text, 'Make a ×3 chain');
    });
  });

  group('Campaign', () {
    test('30 levels, numbered in order, each with one or two goals', () {
      expect(Campaign.count, 30);
      for (var i = 0; i < Campaign.count; i++) {
        final level = Campaign.levels[i];
        expect(level.number, i + 1);
        expect(level.goals.length, inInclusiveRange(1, 2));
        expect(level.goals.every((g) => g.target > 0), isTrue);
      }
      expect(Campaign.level(7).number, 7);
    });

    test('each goal type is introduced alone before levels combine them', () {
      final singles = Campaign.levels.take(20);
      for (final kind in GoalKind.values) {
        expect(singles.any((l) => l.goals.length == 1 && l.goals.single.kind == kind), isTrue);
      }
      expect(Campaign.levels.take(20).every((l) => l.goals.length == 1), isTrue);
    });

    test('every level can be won: a recorded winning line meets its goals', () {
      for (final level in Campaign.levels) {
        final moves = levelSolutions[level.number];
        expect(moves, isNotNull, reason: 'no solution for level ${level.number}');
        final game = Game(seed: level.seed);
        final tracker = LevelTracker(level);
        for (final (i, column) in moves!.indexed) {
          expect(game.isOver, isFalse, reason: 'level ${level.number}: round over before move ${i + 1}');
          expect(tracker.complete, isFalse, reason: 'level ${level.number}: won before the line ended');
          final result = game.drop(column);
          expect(result.accepted, isTrue, reason: 'level ${level.number}: move ${i + 1} rejected');
          tracker.record(result);
        }
        expect(tracker.complete, isTrue, reason: 'level ${level.number} not won by its line');
      }
    });
  });

}
