import 'dart:math' as math;

import 'events.dart';
import 'game.dart';

/// What a level asks for. All three use numbers the rules already produce.
enum GoalKind {
  /// Reach [LevelGoal.target] points before the round ends.
  score,

  /// Pop [LevelGoal.target] balls in total (cracked shells don't count).
  pop,

  /// Set off a chain of [LevelGoal.target] steps in a single drop.
  chain,
}

class LevelGoal {
  const LevelGoal(this.kind, this.target);
  const LevelGoal.score(int points) : this(GoalKind.score, points);
  const LevelGoal.pop(int balls) : this(GoalKind.pop, balls);
  const LevelGoal.chain(int steps) : this(GoalKind.chain, steps);

  final GoalKind kind;
  final int target;

  /// Short, plain wording for the goal card ("Pop 40 balls").
  String get text => switch (kind) {
        GoalKind.score => 'Score $target points',
        GoalKind.pop => 'Pop $target balls',
        GoalKind.chain => 'Make a ×$target chain',
      };
}

/// One level of the campaign: a fixed deal ([seed]) and one or two goals,
/// all of which must be met before the round ends. A fixed deal means every
/// attempt gets the same balls and rising rows, so each level has a known
/// winning line (test/levels_test.dart replays one for every level).
class LevelDef {
  const LevelDef(this.number, this.seed, this.goals);

  final int number;
  final int seed;
  final List<LevelGoal> goals;
}

/// Tracks a level's goals from the moves of a round. Feed it every accepted
/// [MoveResult]; it reads only what the rules report.
class LevelTracker {
  LevelTracker(this.level);

  final LevelDef level;
  int score = 0;
  int popped = 0;
  int bestChain = 0;

  void record(MoveResult result) {
    if (!result.accepted) return;
    score += result.points;
    final steps = result.events.whereType<ChainStep>();
    for (final step in steps) {
      popped += step.orbsPopped;
    }
    bestChain = math.max(bestChain, steps.length);
  }

  /// Progress towards [goal], never above its target.
  int progress(LevelGoal goal) => math.min(goal.target, switch (goal.kind) {
        GoalKind.score => score,
        GoalKind.pop => popped,
        GoalKind.chain => bestChain,
      });

  bool isMet(LevelGoal goal) => progress(goal) >= goal.target;

  bool get complete => level.goals.every(isMet);
}

/// The 30 levels. Early ones teach one goal at a time with small targets;
/// later ones raise the targets and then combine two familiar goals. The
/// targets were set from the greedy bot in tool/levels.dart (a typical bot
/// round scores ~2400 and pops ~150 balls; ×3 chains are uncommon, ×4 rare),
/// and each seed was chosen so the bot wins its level at the intended rate.
abstract final class Campaign {
  static const levels = <LevelDef>[
    LevelDef(1, 1101, [LevelGoal.pop(8)]),
    LevelDef(2, 1201, [LevelGoal.score(300)]),
    LevelDef(3, 1301, [LevelGoal.chain(2)]),
    LevelDef(4, 1401, [LevelGoal.pop(20)]),
    LevelDef(5, 1501, [LevelGoal.score(600)]),
    LevelDef(6, 1601, [LevelGoal.chain(2)]),
    LevelDef(7, 1701, [LevelGoal.pop(35)]),
    LevelDef(8, 1801, [LevelGoal.score(900)]),
    LevelDef(9, 1901, [LevelGoal.pop(45)]),
    LevelDef(10, 2007, [LevelGoal.chain(3)]),
    LevelDef(11, 2101, [LevelGoal.score(1200)]),
    LevelDef(12, 2206, [LevelGoal.pop(65)]),
    LevelDef(13, 2301, [LevelGoal.score(1400)]),
    LevelDef(14, 2402, [LevelGoal.pop(80)]),
    LevelDef(15, 2501, [LevelGoal.chain(3)]),
    LevelDef(16, 2601, [LevelGoal.score(1700)]),
    LevelDef(17, 2701, [LevelGoal.pop(85)]),
    LevelDef(18, 2801, [LevelGoal.score(2000)]),
    LevelDef(19, 2901, [LevelGoal.pop(100)]),
    LevelDef(20, 3002, [LevelGoal.chain(3)]),
    LevelDef(21, 3101, [LevelGoal.score(1200), LevelGoal.chain(2)]),
    LevelDef(22, 3202, [LevelGoal.pop(90), LevelGoal.chain(2)]),
    LevelDef(23, 3301, [LevelGoal.score(2200)]),
    LevelDef(24, 3404, [LevelGoal.pop(50), LevelGoal.chain(3)]),
    LevelDef(25, 3501, [LevelGoal.pop(115)]),
    LevelDef(26, 3602, [LevelGoal.score(1800), LevelGoal.chain(3)]),
    LevelDef(27, 3701, [LevelGoal.score(2400)]),
    LevelDef(28, 3801, [LevelGoal.pop(100), LevelGoal.chain(3)]),
    LevelDef(29, 3901, [LevelGoal.score(2600)]),
    LevelDef(30, 4001, [LevelGoal.score(2500), LevelGoal.chain(3)]),
  ];

  static int get count => levels.length;

  static LevelDef level(int number) => levels[number - 1];
}
