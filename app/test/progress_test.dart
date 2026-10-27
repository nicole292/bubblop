import 'package:flutter_test/flutter_test.dart';
import 'package:pop_core/pop_core.dart';
import 'package:project_pop/progress/achievements.dart';
import 'package:project_pop/progress/cosmetics.dart';
import 'package:project_pop/progress/progress.dart';
import 'package:project_pop/progress/rewards.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Completes levels 1..[count] in order.
void clearUpTo(Progress p, int count) {
  for (var level = 1; level <= count; level++) {
    p.completeLevel(level, score: 100);
  }
}

void main() {
  group('levels', () {
    test('a new player can only play level 1', () {
      final p = Progress.memory();
      expect(p.unlockedLevel, 1);
      expect(p.isUnlocked(1), isTrue);
      expect(p.isUnlocked(2), isFalse);
      expect(p.currentLevel, 1);
    });

    test('levels unlock one at a time, in order', () {
      final p = Progress.memory();
      expect(p.completeLevel(2, score: 500), isNull, reason: 'level 2 is still locked');
      expect(p.isCompleted(2), isFalse);
      p.completeLevel(1, score: 100);
      expect(p.unlockedLevel, 2);
      expect(p.isUnlocked(3), isFalse);
      p.completeLevel(2, score: 100);
      expect(p.unlockedLevel, 3);
      expect(p.currentLevel, 3);
    });

    test('a failed run changes nothing (only wins are recorded)', () {
      final p = Progress.memory();
      // The game calls completeLevel only when the goals are met; a lost
      // round never calls it, so level 2 stays locked.
      expect(p.unlockedLevel, 1);
      expect(p.completedCount, 0);
      expect(p.coins, 0);
    });

    test('replaying keeps the best score but pays nothing again', () {
      final p = Progress.memory();
      final first = p.completeLevel(1, score: 300)!;
      expect(first.firstTime, isTrue);
      expect(first.coins, LevelRewards.forLevel(1).coins);
      final coinsAfterFirst = p.coins;

      final replay = p.completeLevel(1, score: 500)!;
      expect(replay.firstTime, isFalse);
      expect(replay.newBest, isTrue);
      expect(first.newBest, isFalse, reason: 'a first clear is not a "new best"');
      expect(replay.coins, 0);
      expect(replay.gift, GiftKind.none);
      expect(replay.achievements, isEmpty);
      expect(p.coins, coinsAfterFirst);
      expect(p.bestScore(1), 500);

      expect(p.completeLevel(1, score: 500)!.newBest, isFalse, reason: 'a tie is not a new best');
      p.completeLevel(1, score: 200);
      expect(p.bestScore(1), 500, reason: 'a lower replay keeps the best');
      expect(p.coins, coinsAfterFirst);
    });

    test('after all 30 levels the current level stays at 30', () {
      final p = Progress.memory();
      clearUpTo(p, Campaign.count);
      expect(p.allCompleted, isTrue);
      expect(p.currentLevel, Campaign.count);
      expect(p.unlockedLevel, Campaign.count);
    });
  });

  group('rewards', () {
    test('a gift box every third level, special gifts at 10, 20 and 30', () {
      for (var level = 1; level <= 30; level++) {
        final gift = LevelRewards.forLevel(level).gift;
        if (level == 10 || level == 20 || level == 30) {
          expect(gift, GiftKind.special, reason: 'level $level');
        } else if (level % 3 == 0) {
          expect(gift, GiftKind.box, reason: 'level $level');
        } else {
          expect(gift, GiftKind.none, reason: 'level $level');
        }
      }
    });

    test('special gifts unlock a cosmetic and add their coins', () {
      final p = Progress.memory();
      clearUpTo(p, 9);
      expect(p.owns(Cosmetics.candy), isFalse);
      final before = p.coins;
      final clear = p.completeLevel(10, score: 100)!;
      expect(clear.gift, GiftKind.special);
      expect(clear.giftContents!.cosmetic, Cosmetics.candy);
      expect(p.owns(Cosmetics.candy), isTrue);
      final achievementCoins = clear.achievements.fold(0, (sum, a) => sum + a.coins);
      expect(p.coins, before + clear.coins + clear.giftContents!.coins + achievementCoins);
    });

    test('total coins match everything the campaign promises', () {
      final p = Progress.memory();
      clearUpTo(p, 30);
      var expected = 0;
      for (var level = 1; level <= 30; level++) {
        final r = LevelRewards.forLevel(level);
        expected += r.coins + (r.contents?.coins ?? 0);
      }
      for (final a in Achievements.all) {
        if (a.target != null) expected += a.coins;
      }
      expect(p.coins, expected);
    });
  });

  group('achievements', () {
    test('level milestones unlock exactly when reached, once', () {
      final p = Progress.memory();
      final first = p.completeLevel(1, score: 100)!;
      expect(first.achievements.map((a) => a.id), [AchievementId.firstLevel]);
      clearUpTo(p, 4);
      expect(p.hasAchievement(AchievementId.fiveLevels), isFalse);
      final fifth = p.completeLevel(5, score: 100)!;
      expect(fifth.achievements.map((a) => a.id), [AchievementId.fiveLevels]);
      // Replaying level 5 does not unlock it again.
      expect(p.completeLevel(5, score: 100)!.achievements, isEmpty);
    });

    test('chain and personal-best achievements pay once', () {
      final p = Progress.memory();
      expect(p.recordChain(1), isNull, reason: 'a single pop is not a chain');
      expect(p.recordChain(2)?.id, AchievementId.firstChain);
      final coins = p.coins;
      expect(p.recordChain(3), isNull);
      expect(p.coins, coins);
      expect(p.recordPersonalBest()?.id, AchievementId.personalBest);
      expect(p.recordPersonalBest(), isNull);
      expect(p.coins, coins + Achievements.of(AchievementId.personalBest).coins);
    });

    test('progress towards counted achievements', () {
      final p = Progress.memory();
      clearUpTo(p, 3);
      expect(p.achievementProgress(Achievements.of(AchievementId.fiveLevels)), (3, 5));
      expect(p.achievementProgress(Achievements.of(AchievementId.firstChain)), (0, 1));
    });
  });

  group('cosmetics', () {
    test('defaults are owned and selected', () {
      final p = Progress.memory();
      expect(p.balls, Cosmetics.classic);
      expect(p.sky, Cosmetics.day);
      expect(p.owns(Cosmetics.classic), isTrue);
      expect(p.owns(Cosmetics.jewel), isFalse);
    });

    test('coin items need enough coins and are paid once', () {
      final p = Progress.memory();
      expect(p.buy(Cosmetics.mint), isFalse, reason: 'no coins yet');
      clearUpTo(p, 12);
      final coins = p.coins;
      expect(coins, greaterThanOrEqualTo(200));
      expect(p.buy(Cosmetics.mint), isTrue);
      expect(p.coins, coins - 200);
      expect(p.buy(Cosmetics.mint), isFalse, reason: 'already owned');
      expect(p.coins, coins - 200);
    });

    test('gift-only items cannot be bought, and locked items cannot be used', () {
      final p = Progress.memory();
      clearUpTo(p, 20);
      expect(p.buy(Cosmetics.twilight), isFalse);
      expect(p.select(Cosmetics.twilight), isFalse);
      expect(p.sky, Cosmetics.day);
      expect(p.select(Cosmetics.sunset), isTrue, reason: 'won at level 20');
      expect(p.sky, Cosmetics.sunset);
    });
  });

  group('saving', () {
    test('progress, coins, achievements and cosmetics survive a restart', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final p = Progress.from(prefs);
      clearUpTo(p, 12);
      p.completeLevel(3, score: 999);
      p.recordChain(2);
      p.buy(Cosmetics.mint);
      p.select(Cosmetics.mint);
      p.select(Cosmetics.candy);

      final again = Progress.from(prefs);
      expect(again.unlockedLevel, 13);
      expect(again.completedCount, 12);
      expect(again.bestScore(3), 999);
      expect(again.coins, p.coins);
      expect(again.hasAchievement(AchievementId.firstChain), isTrue);
      expect(again.hasAchievement(AchievementId.tenLevels), isTrue);
      expect(again.owns(Cosmetics.mint), isTrue);
      expect(again.owns(Cosmetics.candy), isTrue);
      expect(again.sky, Cosmetics.mint);
      expect(again.balls, Cosmetics.candy);

      // Rewards stay claimed after the restart.
      final coins = again.coins;
      expect(again.completeLevel(3, score: 1)!.firstTime, isFalse);
      expect(again.coins, coins);
    });

    test('a damaged selection falls back to the defaults', () async {
      SharedPreferences.setMockInitialValues({'style.balls': 'balls.neon', 'style.sky': 'nonsense'});
      final p = Progress.from(await SharedPreferences.getInstance());
      expect(p.balls, Cosmetics.classic, reason: 'neon is not owned');
      expect(p.sky, Cosmetics.day);
    });
  });
}
