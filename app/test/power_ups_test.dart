import 'package:flutter_test/flutter_test.dart';
import 'package:pop_core/pop_core.dart';
import 'package:project_pop/progress/achievements.dart';
import 'package:project_pop/progress/power_ups.dart';
import 'package:project_pop/progress/progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'level_flow_test.dart' show makeGame, finishAnimations;

/// Progress with some coins, from finishing levels.
Progress withCoins() {
  final p = Progress.memory();
  for (var l = 1; l <= 15; l++) {
    p.completeLevel(l, score: 100);
  }
  return p;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('buying several pays for all of them, or for none', () {
    final p = withCoins();
    final coins = p.coins;
    expect(p.buyPowerUp(PowerUp.bomb, 3), isTrue);
    expect(p.stock(PowerUp.bomb), 3);
    expect(p.coins, coins - 3 * PowerUp.bomb.price);
    final left = p.coins;
    expect(p.buyPowerUp(PowerUp.rainbow, left ~/ PowerUp.rainbow.price + 1), isFalse);
    expect(p.coins, left);
    expect(p.stock(PowerUp.rainbow), 0);
    expect(p.usePowerUp(PowerUp.bomb), isTrue);
    expect(p.stock(PowerUp.bomb), 2);
  });

  test('power-ups are saved between launches', () async {
    SharedPreferences.setMockInitialValues({});
    final p = await Progress.load();
    for (var l = 1; l <= 15; l++) {
      p.completeLevel(l, score: 100);
    }
    expect(p.buyPowerUp(PowerUp.freeze, 2), isTrue);
    final again = await Progress.load();
    expect(again.stock(PowerUp.freeze), 2);
  });

  test('a bought bomb blasts without charging, and is used up', () {
    final progress = withCoins()..buyPowerUp(PowerUp.bomb, 1);
    final game = makeGame(progress: progress);
    game.restart(level: Campaign.level(5));
    expect(game.bombReady, isFalse);
    expect(game.usePowerUp(PowerUp.bomb), isTrue);
    expect(game.stockBombArmed, isTrue);
    game.dropAt(2);
    finishAnimations(game);
    expect(progress.stock(PowerUp.bomb), 0);
    expect(game.bombArmed, isFalse);
  });

  test('rainbow pop, freeze and extra drops work in a round', () {
    final progress = withCoins()
      ..buyPowerUp(PowerUp.rainbow, 1)
      ..buyPowerUp(PowerUp.freeze, 1)
      ..buyPowerUp(PowerUp.drops, 1);
    final game = makeGame(progress: progress);
    final limited = Campaign.levels.firstWhere((l) => l.drops != null && !l.still);
    game.restart(level: limited);
    final drops = game.hud.value.dropsLeft!;
    expect(game.usePowerUp(PowerUp.drops), isTrue);
    expect(game.hud.value.dropsLeft, drops + PowerUp.extraDrops);
    final pressure = game.rules.pressure;
    expect(game.usePowerUp(PowerUp.freeze), isTrue);
    expect(game.rules.pressure, pressure + PowerUp.freezeDrops);
    final score = game.rules.score;
    expect(game.usePowerUp(PowerUp.rainbow), isTrue);
    finishAnimations(game);
    expect(game.rules.score, greaterThan(score));
    for (final p in PowerUp.values) {
      expect(progress.stock(p), 0, reason: p.name);
    }
    // With none left, nothing happens.
    expect(game.usePowerUp(PowerUp.rainbow), isFalse);
  });

  test('extra drops are not offered on a level without a drop limit', () {
    final game = makeGame();
    game.restart(level: Campaign.levels.firstWhere((l) => l.drops == null));
    expect(game.powerUpsHere, isNot(contains(PowerUp.drops)));
  });

  test('the all-levels award needs exactly every level', () {
    expect(Achievements.of(AchievementId.allLevels).target, Campaign.count);
  });
}
