import 'dart:math' as math;

import 'cell.dart';
import 'events.dart';
import 'game.dart';
import 'rules_config.dart';

/// What a level asks for. All of them use numbers the rules already produce.
enum GoalKind {
  /// Reach [LevelGoal.target] points before the round ends.
  score,

  /// Pop [LevelGoal.target] balls in total (cracked shells don't count).
  pop,

  /// Set off a chain of [LevelGoal.target] steps in a single drop.
  chain,

  /// Crack [LevelGoal.target] shells open.
  crack,
}

class LevelGoal {
  const LevelGoal(this.kind, this.target);
  const LevelGoal.score(int points) : this(GoalKind.score, points);
  const LevelGoal.pop(int balls) : this(GoalKind.pop, balls);
  const LevelGoal.chain(int steps) : this(GoalKind.chain, steps);
  const LevelGoal.crack(int shells) : this(GoalKind.crack, shells);

  final GoalKind kind;
  final int target;

  /// Short, plain wording for the goal card ("Pop 40 balls").
  String get text => switch (kind) {
        GoalKind.score => 'Score $target points',
        GoalKind.pop => 'Pop $target balls',
        GoalKind.chain => 'Make a ×$target chain',
        GoalKind.crack => 'Crack $target shells',
      };
}

/// A level's twist on the usual round, shown on the level card.
enum LevelSetup {
  normal('', ''),

  /// Three rows of shells to start, so there is lots to crack.
  wall('Shell wall', 'Starts with a wall of shells'),

  /// Only three colours all round: big groups and long chains come easier.
  calm('Three colours', 'Only three colours'),

  /// Rows rise sooner (every 6 drops at first instead of 9).
  rush('Fast rows', 'Rows rise faster');

  const LevelSetup(this.label, this.about);

  final String label;
  final String about;

  RulesConfig apply(RulesConfig base) => switch (this) {
        normal => base,
        wall => base.copyWith(startRows: 3, startOpenRows: 1),
        calm => base.copyWith(startColors: 3, extraColorLevel: 1 << 30),
        rush => base.copyWith(startPressure: 6),
      };
}

/// One level of the campaign: a fixed deal ([seed]) and one or two goals,
/// all of which must be met before the round ends, sometimes within a
/// number of [drops] and with a [setup] twist. A fixed deal means every
/// attempt gets the same balls and rising rows, so each level has a known
/// winning line (test/levels_test.dart replays one for every level).
class LevelDef {
  const LevelDef(this.number, this.seed, this.goals, {this.drops, this.setup = LevelSetup.normal});

  final int number;
  final int seed;
  final List<LevelGoal> goals;

  /// The drop limit, or null for none.
  final int? drops;
  final LevelSetup setup;

  /// A fresh round of this level on top of [base] (the usual rules).
  Game newGame({RulesConfig base = const RulesConfig()}) =>
      Game(seed: seed, config: setup.apply(base), dropLimit: drops);
}

/// Tracks a level's goals from the moves of a round. Feed it every accepted
/// [MoveResult]; it reads only what the rules report.
class LevelTracker {
  LevelTracker(this.level);

  final LevelDef level;
  int score = 0;
  int popped = 0;
  int bestChain = 0;
  int cracked = 0;

  void record(MoveResult result) {
    if (!result.accepted) return;
    score += result.points;
    final steps = result.events.whereType<ChainStep>();
    for (final step in steps) {
      popped += step.orbsPopped;
      cracked += step.cracked.values.where((c) => c.kind == CellKind.shell).length;
    }
    bestChain = math.max(bestChain, steps.length);
  }

  /// Progress towards [goal], never above its target.
  int progress(LevelGoal goal) => math.min(goal.target, switch (goal.kind) {
        GoalKind.score => score,
        GoalKind.pop => popped,
        GoalKind.chain => bestChain,
        GoalKind.crack => cracked,
      });

  bool isMet(LevelGoal goal) => progress(goal) >= goal.target;

  bool get complete => level.goals.every(isMet);
}

/// The 30 levels. Early ones teach one goal at a time with small targets;
/// later ones raise the targets and then combine two familiar goals. Along
/// the way some levels add a drop limit or a [LevelSetup] twist, so rounds
/// play differently: a shell wall to crack through, three colours for long
/// chains, fast rows. The targets were set from the greedy bot in
/// tool/levels.dart (a typical bot round scores ~2400 and pops ~150 balls;
/// ×3 chains are uncommon, ×4 rare), and each seed was chosen so the bot
/// wins its level at the intended rate.
abstract final class Campaign {
  static const levels = <LevelDef>[
    LevelDef(1, 1101, [LevelGoal.pop(8)]),
    LevelDef(2, 1201, [LevelGoal.score(300)]),
    LevelDef(3, 1301, [LevelGoal.chain(2)]),
    LevelDef(4, 1401, [LevelGoal.pop(20)]),
    LevelDef(5, 1501, [LevelGoal.crack(6)]),
    LevelDef(6, 1601, [LevelGoal.score(600)], drops: 45),
    LevelDef(7, 1701, [LevelGoal.pop(35)]),
    LevelDef(8, 1801, [LevelGoal.crack(15)], setup: LevelSetup.wall),
    LevelDef(9, 1902, [LevelGoal.chain(2)]),
    LevelDef(10, 2007, [LevelGoal.chain(3)], setup: LevelSetup.calm),
    LevelDef(11, 2101, [LevelGoal.score(1200)]),
    LevelDef(12, 2206, [LevelGoal.pop(50)], drops: 50),
    LevelDef(13, 2301, [LevelGoal.crack(20)], setup: LevelSetup.wall),
    LevelDef(14, 2403, [LevelGoal.score(900)], setup: LevelSetup.rush),
    LevelDef(15, 2501, [LevelGoal.chain(3)]),
    LevelDef(16, 2601, [LevelGoal.pop(70)], drops: 60),
    LevelDef(17, 2701, [LevelGoal.chain(3)], drops: 80, setup: LevelSetup.calm),
    LevelDef(18, 2801, [LevelGoal.score(1800)], drops: 100),
    LevelDef(19, 2901, [LevelGoal.crack(30)], setup: LevelSetup.wall),
    LevelDef(20, 3002, [LevelGoal.pop(60)], setup: LevelSetup.rush),
    LevelDef(21, 3101, [LevelGoal.score(1200), LevelGoal.chain(2)]),
    LevelDef(22, 3202, [LevelGoal.crack(20), LevelGoal.chain(2)], setup: LevelSetup.wall),
    LevelDef(23, 3301, [LevelGoal.crack(30), LevelGoal.pop(40)], setup: LevelSetup.wall),
    LevelDef(24, 3404, [LevelGoal.pop(50), LevelGoal.chain(3)]),
    LevelDef(25, 3501, [LevelGoal.chain(4)], setup: LevelSetup.calm),
    LevelDef(26, 3602, [LevelGoal.score(1500)], setup: LevelSetup.rush),
    LevelDef(27, 3702, [LevelGoal.crack(25), LevelGoal.chain(3)], setup: LevelSetup.wall),
    LevelDef(28, 3801, [LevelGoal.pop(100), LevelGoal.chain(3)]),
    LevelDef(29, 3901, [LevelGoal.score(2400)], drops: 120),
    LevelDef(30, 4001, [LevelGoal.score(2000), LevelGoal.chain(3)], setup: LevelSetup.rush),
  ];


  static int get count => levels.length;

  static LevelDef level(int number) => levels[number - 1];
}
