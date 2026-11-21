import 'package:flutter_test/flutter_test.dart';
import 'package:pop_core/pop_core.dart';
import 'package:project_pop/progress/achievements.dart';
import 'package:project_pop/progress/boosters.dart';
import 'package:project_pop/progress/progress.dart';

import 'level_flow_test.dart' show makeGame;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('spending coins pays only when the player can afford it', () {
    final p = Progress.memory()..completeLevel(1, score: 100);
    final coins = p.coins;
    expect(coins, greaterThan(0));
    expect(p.spend(coins + 1), isFalse);
    expect(p.coins, coins);
    expect(p.spend(coins), isTrue);
    expect(p.coins, 0);
  });

  test('Bomb ready starts the level with the bomb charged, once', () {
    final game = makeGame();
    game.restart(level: Campaign.level(5), boosters: {Booster.bomb});
    expect(game.bombReady, isTrue);
    expect(game.hud.value.bombCharge, 1);
    // Playing it again without the booster starts empty.
    game.restart(level: Campaign.level(5));
    expect(game.bombReady, isFalse);
  });

  test('+5 drops adds drops only to a level with a drop limit', () {
    final limited = Campaign.levels.firstWhere((l) => l.drops != null);
    final game = makeGame();
    game.restart(level: limited, boosters: {Booster.drops});
    expect(game.level!.drops, limited.drops! + Booster.extraDrops);
    expect(game.level!.number, limited.number);

    final open = Campaign.levels.firstWhere((l) => l.drops == null);
    game.restart(level: open, boosters: {Booster.drops});
    expect(game.level!.drops, isNull);
  });

  test('the all-levels award needs exactly every level', () {
    expect(Achievements.of(AchievementId.allLevels).target, Campaign.count);
  });
}
