import 'dart:math' as math;

import 'generated_tuning.dart';
import 'levels.dart';

/// Levels 61-560, built from a recipe rather than by hand. Each level number
/// always gives the same level: its board, twist and goals come from a
/// random generator seeded with the number, then the deal and a difficulty
/// scale come from [generatedTuning] (written by tool/generate_levels.dart,
/// which checks every level can be won and records a winning line).
///
/// Difficulty climbs every 50 levels. Every 10th level is a "boss" with
/// three goals; every 5th is a breather with one easier goal.
abstract final class GeneratedLevels {
  static const first = 61;
  static const count = 500;
  static int get last => first + count - 1;

  /// The boards the recipe picks from, and which of them hold shells and
  /// bombs (needed for crack and blast goals on puzzle levels).
  static const _layouts = [
    Layouts.pyramid, Layouts.stairs, Layouts.stairsRight, Layouts.towers, Layouts.valley,
    Layouts.zigzag, Layouts.checker, Layouts.centerTower, Layouts.wideBase, Layouts.shellPyramid,
    Layouts.vault, Layouts.bombNest, Layouts.bombTower, Layouts.stoneWall, Layouts.crown,
    Layouts.fortress, Layouts.twinPeaks, Layouts.shellTower, Layouts.deepVault, Layouts.bombCross,
    Layouts.stoneCage, Layouts.canyon, Layouts.bombBase,
  ];

  static const _setups = [
    LevelSetup.normal, LevelSetup.normal, LevelSetup.wall, LevelSetup.calm, LevelSetup.rush,
    LevelSetup.bombs, LevelSetup.bombWall, LevelSetup.stones,
  ];

  /// Level [number] (61-560) with the tuned deal and scale.
  static LevelDef level(int number) {
    final (seed, scale, variant) = generatedTuning[number - first];
    return build(number, seed: seed, scale: scale, variant: variant);
  }

  /// The recipe. [scale] (percent) sets the size of the targets: the tuning
  /// tool raises it for a level that is too easy and lowers it for one that
  /// is too hard. [variant] picks another board and goals for the same
  /// number when a level can't be won at all.
  static LevelDef build(int number, {required int seed, int scale = 100, int variant = 0}) {
    final k = number - first; // 0-499
    final tier = k ~/ 50; // 0-9: harder every 50 levels
    final r = math.Random(number * 7919 + 17 + variant * 104729);
    final boss = (k + 1) % 10 == 0;
    final breather = !boss && (k + 1) % 5 == 0;
    final still = !boss && !breather && r.nextInt(7) == 0;
    final layout = _layouts[r.nextInt(_layouts.length)];
    final setup = still ? LevelSetup.normal : _setups[r.nextInt(_setups.length)];

    final hasShells = layout.contains('s') ||
        (!still && setup != LevelSetup.stones) ||
        setup == LevelSetup.wall ||
        setup == LevelSetup.bombWall;
    final hasBombs = layout.contains('*') || (!still && (setup == LevelSetup.bombs || setup == LevelSetup.bombWall));

    final kinds = <GoalKind>[
      GoalKind.score,
      GoalKind.pop,
      if (!still) GoalKind.chain,
      if (hasShells) GoalKind.crack,
      if (hasBombs) GoalKind.blast,
    ]..shuffle(r);
    final goalCount = boss ? 3 : (breather ? 1 : 1 + r.nextInt(2));
    final s = scale / 100 * (breather ? 0.75 : 1.0);
    int t(num base) => math.max(1, (base * s).round());
    final goals = [
      for (final kind in kinds.take(goalCount))
        switch (kind) {
          GoalKind.score => LevelGoal.score(t(2000 + 150 * tier + r.nextInt(8) * 100) ~/ 50 * 50),
          GoalKind.pop => LevelGoal.pop(t(70 + 8 * tier + r.nextInt(5) * 10)),
          // Chains don't scale down below ×3 except on breathers.
          GoalKind.chain => LevelGoal.chain(breather ? 2 : (boss && tier >= 3 ? 4 : 3)),
          GoalKind.crack => LevelGoal.crack(t(still ? 8 + r.nextInt(6) : 15 + tier + r.nextInt(10))),
          GoalKind.blast => LevelGoal.blast(t(still ? 2 : 3 + tier ~/ 3 + r.nextInt(3))),
        },
    ];
    final int? drops = still
        ? 50 + r.nextInt(4) * 10
        : (r.nextInt(3) == 0 ? (110 - tier * 3 + r.nextInt(3) * 10) * 100 ~/ scale.clamp(60, 140) : null);
    return LevelDef(number, seed, goals, drops: drops, setup: setup, layout: layout, still: still);
  }
}
