import 'dart:ui';

enum CosmeticKind { balls, shape, sky }

/// The outline of every piece on the board. Colour still tells pieces apart;
/// the shape is purely decorative and the same for all five colours.
enum PieceShape { ball, jelly, heart, star, flower }

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

/// A ball colour set (5 colours, in colour-index order), a piece shape
/// ([shape], no colours) or a sky (top, middle, bottom of the background
/// gradient). Purely decorative.
class Cosmetic {
  const Cosmetic(this.id, this.kind, this.name, this.colors, this.unlock, {this.shape = PieceShape.ball});

  final String id;
  final CosmeticKind kind;
  final String name;
  final List<Color> colors;
  final Unlock unlock;
  final PieceShape shape;
}

/// Everything a player can collect. Shapes change only the piece outline,
/// never the colours. Each ball set has its own character
/// (Classic bright, Candy soft and light, Jewel deep with amber and jade,
/// Neon electric with lime, cyan and orange) so the sets look clearly
/// different, while the five colours within a set stay far apart in hue and
/// brightness, because colour is the only cue on a ball
/// (test/cosmetics_test.dart measures both). Skies stay light enough for the
/// white board card and white text.
abstract final class Cosmetics {
  static const classic = Cosmetic('balls.classic', CosmeticKind.balls, 'Classic', [
    Color(0xFFFF4757),
    Color(0xFFFFC312),
    Color(0xFF2ED573),
    Color(0xFF1E90FF),
    Color(0xFF9B59F6),
  ], FreeUnlock());

  static const candy = Cosmetic('balls.candy', CosmeticKind.balls, 'Candy', [
    Color(0xFFFF7EB6),
    Color(0xFFFFE07A),
    Color(0xFF6BE3B4),
    Color(0xFF7CC2FF),
    Color(0xFFC59BFF),
  ], GiftUnlock(10));

  static const jewel = Cosmetic('balls.jewel', CosmeticKind.balls, 'Jewel', [
    Color(0xFFC8143F),
    Color(0xFFF28C00),
    Color(0xFF00A38A),
    Color(0xFF1F5FE0),
    Color(0xFFA23BE0),
  ], CoinUnlock(250));

  static const neon = Cosmetic('balls.neon', CosmeticKind.balls, 'Neon', [
    Color(0xFFFF2D95),
    Color(0xFFB8FF1F),
    Color(0xFF14E8FF),
    Color(0xFFFF8A1A),
    Color(0xFF7A3CFF),
  ], CoinUnlock(400));

  static const bubbles =
      Cosmetic('shape.bubbles', CosmeticKind.shape, 'Bubbles', [], FreeUnlock(), shape: PieceShape.ball);
  static const jelly =
      Cosmetic('shape.jelly', CosmeticKind.shape, 'Jelly', [], CoinUnlock(150), shape: PieceShape.jelly);
  static const hearts =
      Cosmetic('shape.hearts', CosmeticKind.shape, 'Hearts', [], CoinUnlock(250), shape: PieceShape.heart);
  static const stars =
      Cosmetic('shape.stars', CosmeticKind.shape, 'Stars', [], CoinUnlock(300), shape: PieceShape.star);
  static const flowers =
      Cosmetic('shape.flowers', CosmeticKind.shape, 'Flowers', [], CoinUnlock(350), shape: PieceShape.flower);

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

  static const all = [
    classic, candy, jewel, neon, //
    bubbles, jelly, hearts, stars, flowers,
    day, mint, sunset, twilight,
  ];

  static const defaultBalls = classic;
  static const defaultShape = bubbles;
  static const defaultSky = day;

  static List<Cosmetic> ofKind(CosmeticKind kind) => [for (final c in all) if (c.kind == kind) c];

  static Cosmetic? byId(String id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }
}
