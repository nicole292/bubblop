import 'cosmetics.dart';

enum GiftKind { none, box, special }

/// What a gift holds: always some coins, sometimes a cosmetic. Rewards are
/// fixed per level (no randomness), so the player always gets exactly what
/// the level card promised.
class GiftContents {
  const GiftContents({required this.coins, this.cosmetic});
  final int coins;
  final Cosmetic? cosmetic;
}

/// The rewards for completing a level for the first time.
class LevelRewards {
  const LevelRewards({required this.coins, required this.gift, this.contents});

  /// Coins for the clear itself.
  final int coins;
  final GiftKind gift;
  final GiftContents? contents;

  /// Coins given instead when a gift's cosmetic is already owned.
  static const duplicateCosmeticCoins = 100;

  static LevelRewards forLevel(int level) {
    final coins = level <= 9
        ? 10
        : level <= 19
            ? 15
            : 20;
    // A special gift after levels 10, 20 and 30; a gift box after every
    // other third level.
    final special = switch (level) {
      10 => Cosmetics.candy,
      20 => Cosmetics.sunset,
      30 => Cosmetics.twilight,
      _ => null,
    };
    if (special != null) {
      return LevelRewards(coins: coins, gift: GiftKind.special, contents: GiftContents(coins: 100, cosmetic: special));
    }
    if (level % 3 == 0) {
      const boxCoins = [30, 30, 40, 40, 50, 50, 60, 60, 75];
      final i = (level ~/ 3 - 1).clamp(0, boxCoins.length - 1);
      return LevelRewards(coins: coins, gift: GiftKind.box, contents: GiftContents(coins: boxCoins[i]));
    }
    return LevelRewards(coins: coins, gift: GiftKind.none);
  }
}
