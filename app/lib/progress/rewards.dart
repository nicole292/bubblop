import 'cosmetics.dart';

enum GiftKind { none, box, special }

/// What a gift holds: always some coins, sometimes a cosmetic. Rewards are
/// fixed per level (no randomness), so the player always gets exactly what
/// the level card promised.
class GiftContents {
  const GiftContents({required this.coins, this.cosmetic, this.bombs = 0});
  final int coins;
  final Cosmetic? cosmetic;

  /// Bombs for the player's supply.
  final int bombs;
}

/// Bombs sold for coins in the Style screen; the bigger pack is cheaper per
/// bomb.
enum BombPack {
  one(1, 40),
  five(5, 160);

  const BombPack(this.bombs, this.price);
  final int bombs;
  final int price;
}

/// A drop that sets off a chain of this many steps or more earns a bomb.
const bombChainSteps = 4;

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
        : level <= 29
        ? 20
        : 25;
    // A special gift after levels 10, 20, 30 and 40; a gift box after every
    // other third level. Every gift holds bombs too.
    final special = switch (level) {
      10 => Cosmetics.kitties,
      20 => Cosmetics.donuts,
      30 => Cosmetics.planets,
      40 => Cosmetics.cherries,
      _ => null,
    };
    if (special != null) {
      return LevelRewards(
        coins: coins,
        gift: GiftKind.special,
        contents: GiftContents(coins: 100, cosmetic: special, bombs: 3),
      );
    }
    if (level % 3 == 0) {
      const boxCoins = [30, 30, 40, 40, 50, 50, 60, 60, 75, 80, 90, 100, 120];
      final i = (level ~/ 3 - 1).clamp(0, boxCoins.length - 1);
      return LevelRewards(
        coins: coins,
        gift: GiftKind.box,
        contents: GiftContents(coins: boxCoins[i], bombs: 1),
      );
    }
    return LevelRewards(coins: coins, gift: GiftKind.none);
  }
}
