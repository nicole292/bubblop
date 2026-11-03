import 'dart:math' as math;

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

  /// Crack [LevelGoal.target] shells open (a blast breaking one counts too).
  crack,

  /// Set off [LevelGoal.target] bombs that rose with the rows (the player's
  /// own bombs don't count).
  blast,
}

class LevelGoal {
  const LevelGoal(this.kind, this.target);
  const LevelGoal.score(int points) : this(GoalKind.score, points);
  const LevelGoal.pop(int balls) : this(GoalKind.pop, balls);
  const LevelGoal.chain(int steps) : this(GoalKind.chain, steps);
  const LevelGoal.crack(int shells) : this(GoalKind.crack, shells);
  const LevelGoal.blast(int bombs) : this(GoalKind.blast, bombs);

  final GoalKind kind;
  final int target;

  /// Short, plain wording for the goal card ("Pop 40 balls").
  String get text => switch (kind) {
        GoalKind.score => 'Score $target points',
        GoalKind.pop => 'Pop $target balls',
        GoalKind.chain => 'Make a ×$target chain',
        GoalKind.crack => 'Crack $target shells',
        GoalKind.blast => 'Blast $target bombs',
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
  rush('Fast rows', 'Rows rise faster'),

  /// Every other rising row carries a bomb.
  bombs('Bomb rows', 'Bombs rise with the rows'),

  /// Three rows to start, each with a bomb, and a bomb in every row after.
  bombWall('Bomb wall', 'Starts full of bombs'),

  /// Grey stones rise instead of shells: pop beside them to clear them.
  stones('Stone rows', 'Stones rise instead of shells');

  const LevelSetup(this.label, this.about);

  final String label;
  final String about;

  RulesConfig apply(RulesConfig base) => switch (this) {
        normal => base,
        wall => base.copyWith(startRows: 3, startOpenRows: 1),
        calm => base.copyWith(startColors: 3, extraColorLevel: 1 << 30),
        rush => base.copyWith(startPressure: 6),
        bombs => base.copyWith(bombEvery: 2),
        bombWall =>
          base.copyWith(startRows: 3, startOpenRows: 1, bombEvery: 1),
        stones => base.copyWith(risingRowKind: RisingRowKind.stones),
      };
}

/// One level of the campaign: a fixed deal ([seed]) and one or two goals,
/// all of which must be met before the round ends, sometimes within a
/// number of [drops] and with a [setup] twist. A fixed deal means every
/// attempt gets the same balls and rising rows, so each level has a known
/// winning line (test/levels_test.dart replays one for every level).
class LevelDef {
  const LevelDef(this.number, this.seed, this.goals,
      {this.drops, this.setup = LevelSetup.normal, this.layout, this.still = false});

  final int number;
  final int seed;
  final List<LevelGoal> goals;

  /// The drop limit, or null for none.
  final int? drops;
  final LevelSetup setup;

  /// The hand-built starting board ([Layouts]), or null for the usual
  /// start of a shell row and two open rows.
  final String? layout;

  /// A puzzle: rows never rise, the board changes only by what is dropped.
  final bool still;

  /// A fresh round of this level on top of [base] (the usual rules).
  Game newGame({RulesConfig base = const RulesConfig()}) {
    final config = setup.apply(base);
    return Game(
        seed: seed,
        config: still ? config.copyWith(rowsRise: false) : config,
        dropLimit: drops,
        layout: layout);
  }
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
  int blasted = 0;

  void record(MoveResult result) {
    if (!result.accepted) return;
    score += result.points;
    final steps = result.events.whereType<ChainStep>();
    for (final step in steps) {
      popped += step.orbsPopped + step.orbsBlasted;
      cracked += step.shellsBroken;
      blasted += step.blasts
          .where((b) => b.cleared[b.center]?.isBomb ?? false)
          .length;
    }
    // A player's bomb sets off its blast as a step of its own; only real
    // pops make a chain.
    bestChain = math.max(
        bestChain, steps.where((s) => s.groups.isNotEmpty).length);
  }

  /// Progress towards [goal], never above its target.
  int progress(LevelGoal goal) => math.min(goal.target, switch (goal.kind) {
        GoalKind.score => score,
        GoalKind.pop => popped,
        GoalKind.chain => bestChain,
        GoalKind.crack => cracked,
        GoalKind.blast => blasted,
      });

  bool isMet(LevelGoal goal) => progress(goal) >= goal.target;

  bool get complete => level.goals.every(isMet);
}

/// Starting boards for levels, top line first (see [Game] for the letters:
/// `o` ball, `s` shell, `#` stone, `*` bomb). Every column is a stack, so
/// nothing floats.
abstract final class Layouts {
  static const pyramid = """
..oo..
.oooo.
oooooo""";
  static const stairs = """
o.....
oo....
ooo...
oooo..""";
  static const stairsRight = """
.....o
....oo
...ooo
..oooo""";
  static const towers = """
o....o
o....o
oo..oo
oo..oo""";
  static const valley = """
o....o
oo..oo
ooo.oo
oooooo""";
  static const zigzag = """
o.o.o.
oooooo
ssssss""";
  static const checker = """
sosoos
ososso""";
  static const centerTower = """
..oo..
..oo..
..ss..
.ssss.
ssssss""";
  static const wideBase = """
oooooo
ssssss
ssssss""";
  static const shellPyramid = """
..ss..
.ssss.
ssssss""";
  static const vault = """
.ssss.
#ssss#
#ssss#
######""";
  static const bombNest = """
..**..
.oooo.
ssssss""";
  static const bombTower = """
*....*
s*..*s
ssosss""";
  static const stoneWall = """
o.oo.o
oooooo
######""";
}

/// The 40 levels. Every one starts its own way: a hand-built board
/// ([Layouts]: pyramids, towers, stairs, shell vaults, bomb nests, stone
/// walls) or a [LevelSetup] twist, and some are puzzles whose rows never
/// rise ([LevelDef.still]): a fixed board and a number of drops. Early
/// levels teach one goal at a time; later ones raise the targets and
/// combine two. The targets were set from the greedy bot in tool/levels.dart,
/// and each seed was chosen so the bot wins its level at the intended rate.
abstract final class Campaign {
  static const levels = <LevelDef>[
    LevelDef(1, 1101, [LevelGoal.pop(8)], layout: Layouts.pyramid),
    LevelDef(2, 1201, [LevelGoal.score(300)], layout: Layouts.stairs),
    LevelDef(3, 1301, [LevelGoal.chain(2)], layout: Layouts.towers),
    LevelDef(4, 1401, [LevelGoal.pop(20)], layout: Layouts.valley),
    LevelDef(5, 1501, [LevelGoal.crack(6)], layout: Layouts.checker),
    LevelDef(6, 1601, [LevelGoal.crack(9)], drops: 30, still: true, layout: Layouts.shellPyramid),
    LevelDef(7, 1701, [LevelGoal.pop(35)], layout: Layouts.zigzag),
    LevelDef(8, 1801, [LevelGoal.crack(15)], setup: LevelSetup.wall),
    LevelDef(9, 1901, [LevelGoal.chain(2)], layout: Layouts.centerTower),
    LevelDef(10, 2001, [LevelGoal.chain(3)], setup: LevelSetup.calm, layout: Layouts.pyramid),
    LevelDef(11, 2103, [LevelGoal.score(1200)], layout: Layouts.stairsRight),
    LevelDef(12, 2204, [LevelGoal.pop(50)], drops: 50, layout: Layouts.towers),
    LevelDef(13, 2301, [LevelGoal.crack(10)], drops: 45, still: true, layout: Layouts.vault),
    LevelDef(14, 2401, [LevelGoal.score(900)], setup: LevelSetup.rush, layout: Layouts.valley),
    LevelDef(15, 2502, [LevelGoal.chain(3)], layout: Layouts.wideBase),
    LevelDef(16, 3001, [LevelGoal.blast(2)], layout: Layouts.bombNest),
    LevelDef(17, 2701, [LevelGoal.chain(3)], drops: 80, setup: LevelSetup.calm),
    LevelDef(18, 2801, [LevelGoal.score(1800)], drops: 100, layout: Layouts.checker),
    LevelDef(19, 2901, [LevelGoal.crack(30)], setup: LevelSetup.wall),
    LevelDef(20, 3001, [LevelGoal.pop(60)], setup: LevelSetup.rush, layout: Layouts.stoneWall),
    LevelDef(21, 3101, [LevelGoal.score(1200), LevelGoal.chain(2)], layout: Layouts.pyramid),
    LevelDef(22, 3202, [LevelGoal.crack(20), LevelGoal.chain(2)], setup: LevelSetup.wall),
    LevelDef(23, 3302, [LevelGoal.crack(12), LevelGoal.pop(30)], drops: 70, still: true, layout: Layouts.vault),
    LevelDef(24, 3403, [LevelGoal.pop(50), LevelGoal.chain(3)], layout: Layouts.towers),
    LevelDef(25, 3501, [LevelGoal.chain(4)], setup: LevelSetup.calm),
    LevelDef(26, 3601, [LevelGoal.score(1500)], setup: LevelSetup.rush, layout: Layouts.stairs),
    LevelDef(27, 3901, [LevelGoal.blast(3)], drops: 18, layout: Layouts.bombTower),
    LevelDef(28, 3801, [LevelGoal.pop(100), LevelGoal.chain(3)], layout: Layouts.zigzag),
    LevelDef(29, 3902, [LevelGoal.score(2400)], drops: 120, layout: Layouts.wideBase),
    LevelDef(30, 4056, [LevelGoal.score(2000), LevelGoal.chain(3)], setup: LevelSetup.rush, layout: Layouts.centerTower),
    // Bombs rise with the rows and go off when a ball beside them pops.
    LevelDef(31, 4104, [LevelGoal.blast(2)], setup: LevelSetup.bombs),
    LevelDef(32, 4201, [LevelGoal.pop(100)], setup: LevelSetup.bombs, layout: Layouts.bombNest),
    LevelDef(33, 4315, [LevelGoal.crack(25)], setup: LevelSetup.bombWall),
    LevelDef(34, 4401, [LevelGoal.score(1500)], setup: LevelSetup.stones, layout: Layouts.stoneWall),
    LevelDef(35, 4501, [LevelGoal.blast(4)], drops: 80, setup: LevelSetup.bombs),
    LevelDef(36, 4603, [LevelGoal.chain(3)], setup: LevelSetup.bombWall),
    LevelDef(37, 4901, [LevelGoal.blast(3), LevelGoal.pop(60)], drops: 65, setup: LevelSetup.bombs, layout: Layouts.bombTower),
    LevelDef(38, 4802, [LevelGoal.pop(80), LevelGoal.chain(2)], setup: LevelSetup.stones, layout: Layouts.valley),
    LevelDef(39, 4911, [LevelGoal.blast(5)], drops: 90, setup: LevelSetup.bombWall),
    LevelDef(40, 5001, [LevelGoal.score(2500), LevelGoal.blast(4)], setup: LevelSetup.bombs, layout: Layouts.bombNest),
  ];

  static int get count => levels.length;

  static LevelDef level(int number) => levels[number - 1];
}
