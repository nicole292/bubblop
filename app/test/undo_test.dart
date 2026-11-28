import 'package:flutter_test/flutter_test.dart';
import 'package:pop_core/pop_core.dart';
import 'package:project_pop/game/pop_game.dart';
import 'package:project_pop/progress/power_ups.dart';
import 'package:project_pop/progress/progress.dart';

import '../../packages/pop_core/test/level_solutions.dart';
import 'level_flow_test.dart' show makeGame, finishAnimations;

Progress withCoins() {
  final p = Progress.memory();
  for (var l = 1; l <= 15; l++) {
    p.completeLevel(l, score: 100);
  }
  return p;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the first undo is free, the next ones cost coins', () {
    final progress = withCoins();
    final game = makeGame(progress: progress);
    game.restart(level: Campaign.level(4));
    expect(game.canUndo, isFalse);
    final start = game.rules.board.toPicture();
    game.dropAt(0);
    finishAnimations(game);
    expect(game.undoCost, 0);
    final coins = progress.coins;
    expect(game.undo(), isTrue);
    expect(progress.coins, coins, reason: 'free');
    expect(game.rules.board.toPicture(), start);
    expect(game.rules.moves, 0);

    game.dropAt(1);
    finishAnimations(game);
    expect(game.undoCost, PopGame.undoPrice);
    expect(game.undo(), isTrue);
    expect(progress.coins, coins - PopGame.undoPrice);
  });

  test('without enough coins a paid undo does nothing', () {
    final progress = Progress.memory();
    final game = makeGame(progress: progress);
    game.restart(level: Campaign.level(4));
    game.dropAt(0);
    game.dropAt(1);
    finishAnimations(game);
    expect(game.undo(), isTrue); // the free one
    final moves = game.rules.moves;
    expect(game.undo(), isFalse);
    expect(game.rules.moves, moves);
  });

  test('undo after running out of drops brings the round back', () {
    final game = makeGame(progress: withCoins());
    final level = Campaign.levels.firstWhere((l) => l.drops != null && l.still);
    game.restart(level: level);
    var guard = 0;
    while (!game.rules.isOver && guard++ < 500) {
      final c = [for (var i = 0; i < 6; i++) i].firstWhere(game.rules.canDrop, orElse: () => -1);
      if (c < 0) break;
      game.dropAt(c);
      finishAnimations(game);
      if (game.hud.value.levelClear != null) return; // won by chance: nothing to test
    }
    expect(game.hud.value.isOver, isTrue);
    expect(game.undo(), isTrue);
    expect(game.rules.isOver, isFalse);
    expect(game.hud.value.isOver, isFalse);
    expect(game.hud.value.dropsLeft, 1);
  });

  test('undoing a bought bomb gives it back', () {
    final progress = withCoins()..buyPowerUp(PowerUp.bomb, 1);
    final game = makeGame(progress: progress);
    game.restart(level: Campaign.level(5));
    game.usePowerUp(PowerUp.bomb);
    game.dropAt(2);
    finishAnimations(game);
    expect(progress.stock(PowerUp.bomb), 0);
    expect(game.undo(), isTrue);
    expect(progress.stock(PowerUp.bomb), 1);
  });

  test('a won level cannot be undone', () {
    final game = makeGame(progress: withCoins());
    game.restart(level: Campaign.level(1));
    for (final c in levelSolutions[1]!) {
      game.dropAt(c);
    }
    finishAnimations(game);
    expect(game.hud.value.levelClear, isNotNull);
    expect(game.canUndo, isFalse);
  });
}
