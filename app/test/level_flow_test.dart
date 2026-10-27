import 'package:flutter_test/flutter_test.dart';
import 'package:pop_core/pop_core.dart';
import 'package:project_pop/game/pop_game.dart';
import 'package:project_pop/game/tutorial.dart';
import 'package:project_pop/progress/progress.dart';
import 'package:project_pop/services/haptics.dart';
import 'package:project_pop/services/settings.dart';
import 'package:project_pop/services/sfx.dart';

import '../../packages/pop_core/test/level_solutions.dart';

/// A game with silent audio (Sfx is never initialised) and in-memory saves.
PopGame makeGame({Settings? settings, Progress? progress}) {
  final s = settings ?? (Settings.memory()..tutorialDone = true);
  return PopGame(settings: s, progress: progress ?? Progress.memory(), sfx: Sfx(s), haptics: Haptics(s));
}

/// Plays every queued animation phase to the end.
void finishAnimations(PopGame game) {
  for (var i = 0; i < 2000 && !game.phases.isIdle; i++) {
    game.phases.update(0.05);
  }
}

void main() {
  // Vibration calls go through the platform channel.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('winning a level records it once, unlocks the next and stops input', () {
    final progress = Progress.memory();
    final game = makeGame(progress: progress);
    final level = Campaign.level(1);
    game.restart(level: level);
    expect(game.hud.value.levelNumber, 1);
    expect(game.hud.value.goals.single.progress, 0);

    for (final column in levelSolutions[1]!) {
      game.dropAt(column);
    }
    finishAnimations(game);

    final hud = game.hud.value;
    expect(hud.isOver, isTrue);
    expect(hud.levelClear, isNotNull);
    expect(hud.levelClear!.firstTime, isTrue);
    expect(hud.goals.single.met, isTrue);
    expect(progress.isCompleted(1), isTrue);
    expect(progress.unlockedLevel, 2);
    final coins = progress.coins;

    // Further taps do nothing once the level is won.
    final moves = game.rules.moves;
    game.dropAt(0);
    expect(game.rules.moves, moves);

    // Replaying wins again but pays nothing more.
    game.restart(level: level);
    for (final column in levelSolutions[1]!) {
      game.dropAt(column);
    }
    finishAnimations(game);
    expect(game.hud.value.levelClear!.firstTime, isFalse);
    expect(progress.coins, coins);
  });

  test('a lost level records nothing and leaves the Endless best alone', () {
    final settings = Settings.memory()..tutorialDone = true;
    final progress = Progress.memory();
    final game = makeGame(settings: settings, progress: progress);
    game.restart(level: Campaign.level(1));
    // Always drop in the leftmost open column. Level 1's deal is fixed, so
    // this plays out the same every time: the board fills before 8 balls pop.
    var guard = 0;
    while (!game.rules.isOver && !(game.hud.value.levelClear != null) && guard++ < 400) {
      for (var c = 0; c < 6 && !game.rules.isOver; c++) {
        if (game.rules.canDrop(c)) {
          game.dropAt(c);
          break;
        }
      }
      finishAnimations(game);
    }
    final hud = game.hud.value;
    expect(hud.levelClear, isNull, reason: 'this play should lose level 1');
    expect(hud.isOver, isTrue);
    expect(hud.isLevel, isTrue);
    expect(progress.isCompleted(1), isFalse);
    expect(progress.unlockedLevel, 1);
    expect(settings.best, 0, reason: 'level rounds never set the Endless best');
    expect(settings.gamesPlayed, 0);
  });

  test('a new player starting level 1 gets the tutorial board, and its lesson wins the level', () {
    final settings = Settings.memory();
    final progress = Progress.memory();
    final game = makeGame(settings: settings, progress: progress);
    game.restart(level: Campaign.level(1));
    expect(game.hud.value.hint, Tutorial.dropHint);
    game.dropAt(Tutorial.dropColumn);
    finishAnimations(game);
    expect(game.hud.value.levelClear, isNotNull);
    expect(progress.isCompleted(1), isTrue);
    expect(settings.tutorialDone, isTrue);
  });

  test('Endless still works: no goals, and game over records the best', () {
    final settings = Settings.memory()..tutorialDone = true;
    final game = makeGame(settings: settings);
    game.restart();
    expect(game.hud.value.isLevel, isFalse);
    expect(game.hud.value.goals, isEmpty);
    var guard = 0;
    while (!game.rules.isOver && guard++ < 600) {
      for (var c = 0; c < 6; c++) {
        if (game.rules.canDrop(c)) {
          game.dropAt(c);
          break;
        }
      }
      finishAnimations(game);
    }
    expect(game.hud.value.isOver, isTrue);
    expect(game.hud.value.levelClear, isNull);
    expect(settings.gamesPlayed, 1);
    expect(settings.best, game.rules.score);
  });
}
