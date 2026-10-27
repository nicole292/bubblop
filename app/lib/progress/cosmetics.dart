import 'dart:ui';

enum CosmeticKind { balls, sky }

/// How a cosmetic is obtained: free from the start, from a level's special
/// gift, or with coins.
sealed class Unlock {
  const Unlock();
}

class FreeUnlock extends Unlock {
  const FreeUnlock();
}

class GiftUnlock extends Unlock {
  const GiftUnlock(this.level);
  final int level;
}

class CoinUnlock extends Unlock {
  const CoinUnlock(this.price);
  final int price;
}

/// A ball colour set (5 colours, in colour-index order) or a sky (top,
/// middle, bottom of the background gradient). Purely decorative.
class Cosmetic {
  const Cosmetic(this.id, this.kind, this.name, this.colors, this.unlock);

  final String id;
  final CosmeticKind kind;
  final String name;
  final List<Color> colors;
  final Unlock unlock;
}

/// Everything a player can collect. Ball sets keep five clearly different
/// hues that also differ in brightness, because colour is the only cue on a
/// ball; skies stay light enough for the white board card and white text.
abstract final class Cosmetics {
  static const classic = Cosmetic('balls.classic', CosmeticKind.balls, 'Classic', [
    Color(0xFFFF4757),
    Color(0xFFFFC312),
    Color(0xFF2ED573),
    Color(0xFF1E90FF),
    Color(0xFF9B59F6),
  ], FreeUnlock());

  static const candy = Cosmetic('balls.candy', CosmeticKind.balls, 'Candy', [
    Color(0xFFFF5FA2),
    Color(0xFFFFD93D),
    Color(0xFF3DDC97),
    Color(0xFF4CC9F0),
    Color(0xFFB388FF),
  ], GiftUnlock(10));

  static const jewel = Cosmetic('balls.jewel', CosmeticKind.balls, 'Jewel', [
    Color(0xFFE0245E),
    Color(0xFFFF9F1C),
    Color(0xFF0FA968),
    Color(0xFF2D5BFF),
    Color(0xFF8E44D9),
  ], CoinUnlock(250));

  static const neon = Cosmetic('balls.neon', CosmeticKind.balls, 'Neon', [
    Color(0xFFFF2E63),
    Color(0xFFFFE600),
    Color(0xFF00E08A),
    Color(0xFF00B4FF),
    Color(0xFFC84BFF),
  ], CoinUnlock(400));

  static const day = Cosmetic('sky.day', CosmeticKind.sky, 'Day', [
    Color(0xFF5CC8FF),
    Color(0xFF7FA8FF),
    Color(0xFFA98BFF),
  ], FreeUnlock());

  static const mint = Cosmetic('sky.mint', CosmeticKind.sky, 'Mint', [
    Color(0xFF4FD8C4),
    Color(0xFF6CC3E8),
    Color(0xFF8FA8F0),
  ], CoinUnlock(200));

  static const sunset = Cosmetic('sky.sunset', CosmeticKind.sky, 'Sunset', [
    Color(0xFFFFA36B),
    Color(0xFFFF8BA0),
    Color(0xFFB98CF2),
  ], GiftUnlock(20));

  static const twilight = Cosmetic('sky.twilight', CosmeticKind.sky, 'Twilight', [
    Color(0xFF6F8BFF),
    Color(0xFF8A72F0),
    Color(0xFFC77DDB),
  ], GiftUnlock(30));

  static const all = [classic, candy, jewel, neon, day, mint, sunset, twilight];

  static const defaultBalls = classic;
  static const defaultSky = day;

  static List<Cosmetic> ofKind(CosmeticKind kind) => [for (final c in all) if (c.kind == kind) c];

  static Cosmetic? byId(String id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }
}
