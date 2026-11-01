import 'dart:ui';

enum CosmeticKind { balls, shape, sky }

/// The outline of every piece on the board. Colour still tells pieces apart;
/// the shape is purely decorative and the same for all five colours. The
/// first five are drawn as outlines (render/piece_shapes.dart); the rest are
/// 3D pieces rendered in Blender (tools/blender/, render/piece_art.dart).
enum PieceShape {
  ball,
  jelly,
  heart,
  star,
  flower,
  kitty,
  bunny,
  bear,
  frog,
  donut,
  cupcake,
  macaron,
  planet,
  gem,
  moon,
  strawberry,
  apple,
  cherry;

  /// Drawn from Blender layers in assets/pieces/ rather than an outline.
  bool get isArt => index > PieceShape.flower.index;
}

/// The surface of a ball set, painted over every ball so sets differ in
/// more than colour (render/orb_material.dart, paintFinish).
enum Finish {
  /// Plain candy gloss.
  gloss,

  /// Soft, with a dusting of sugar sparkles.
  sugar,

  /// Fresh fruit: a few dewdrops.
  dew,

  /// Pearly: a shimmer that shifts from pink to aqua.
  pearl,

  /// Glowing: a bright rim and an inner light.
  glow,

  /// Starry: tiny stars and a nebula swirl inside.
  cosmic,
}

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
  const Cosmetic(this.id, this.kind, this.name, this.colors, this.unlock,
      {this.shape = PieceShape.ball, this.finish = Finish.gloss, this.family});

  final String id;
  final CosmeticKind kind;
  final String name;
  final List<Color> colors;
  final Unlock unlock;
  final PieceShape shape;

  /// A ball set's surface.
  final Finish finish;

  /// The group a shape is listed under in the Style screen ("Animals").
  final String? family;
}

/// Everything a player can collect. Shapes change only the piece outline
/// (or, for the 3D families, the whole piece), never the colours. Each ball set has its own theme rather than another
/// rainbow (Candy with chocolate, Fruit with orange and blueberry, Ocean
/// with coral, sand and anemone pink, Neon electric, Galaxy with nebula
/// magenta and sunset orange), each with its own [Finish], so the sets look
/// clearly different, while the
/// five colours within a set stay far apart in hue and brightness, because
/// colour is the only cue on a ball, and stand out on both the light and the
/// dark board (test/cosmetics_test.dart measures all three). Skies stay light
/// enough for the white board card and white text.
abstract final class Cosmetics {
  static const classic = Cosmetic('balls.classic', CosmeticKind.balls, 'Classic', [
    Color(0xFFFF4757),
    Color(0xFFFFC312),
    Color(0xFF2ED573),
    Color(0xFF1E90FF),
    Color(0xFF9B59F6),
  ], FreeUnlock(), finish: Finish.gloss);






  /// Items no longer in the game, with the coins they cost: owners get them
  /// back (gift items cost nothing). Only Classic balls and the Day sky are
  /// left; the Style screen is about shapes.
  static const retired = [
    ('balls.jewel', 250),
    ('balls.candy', 0),
    ('balls.fruit', 200),
    ('balls.ocean', 300),
    ('balls.neon', 400),
    ('balls.galaxy', 500),
    ('sky.mint', 200),
    ('sky.sunset', 0),
    ('sky.twilight', 0),
  ];

  static const bubbles = Cosmetic(
    'shape.bubbles',
    CosmeticKind.shape,
    'Bubbles',
    [],
    FreeUnlock(),
    shape: PieceShape.ball,
  );
  static const jelly = Cosmetic(
    'shape.jelly',
    CosmeticKind.shape,
    'Jelly',
    [],
    CoinUnlock(150),
    shape: PieceShape.jelly,
  );
  static const hearts = Cosmetic(
    'shape.hearts',
    CosmeticKind.shape,
    'Hearts',
    [],
    CoinUnlock(250),
    shape: PieceShape.heart,
  );
  static const stars = Cosmetic(
    'shape.stars',
    CosmeticKind.shape,
    'Stars',
    [],
    CoinUnlock(300),
    shape: PieceShape.star,
  );
  static const flowers = Cosmetic(
    'shape.flowers',
    CosmeticKind.shape,
    'Flowers',
    [],
    CoinUnlock(350),
    shape: PieceShape.flower,
  );

  // 3D pieces, rendered in Blender. Each family has a cheaper and a
  // fancier piece, so there is always something new to save up for.
  static const kitties = Cosmetic('shape.kitty', CosmeticKind.shape, 'Kitties', [], GiftUnlock(10),
      shape: PieceShape.kitty, family: 'Animals');
  static const bunnies = Cosmetic('shape.bunny', CosmeticKind.shape, 'Bunnies', [], CoinUnlock(400),
      shape: PieceShape.bunny, family: 'Animals');
  static const bears = Cosmetic('shape.bear', CosmeticKind.shape, 'Bears', [], CoinUnlock(450),
      shape: PieceShape.bear, family: 'Animals');
  static const frogs = Cosmetic('shape.frog', CosmeticKind.shape, 'Frogs', [], CoinUnlock(450),
      shape: PieceShape.frog, family: 'Animals');
  static const donuts = Cosmetic('shape.donut', CosmeticKind.shape, 'Donuts', [], GiftUnlock(20),
      shape: PieceShape.donut, family: 'Treats');
  static const cupcakes = Cosmetic('shape.cupcake', CosmeticKind.shape, 'Cupcakes', [], CoinUnlock(550),
      shape: PieceShape.cupcake, family: 'Treats');
  static const macarons = Cosmetic('shape.macaron', CosmeticKind.shape, 'Macarons', [], CoinUnlock(500),
      shape: PieceShape.macaron, family: 'Treats');
  static const planets = Cosmetic('shape.planet', CosmeticKind.shape, 'Planets', [], GiftUnlock(30),
      shape: PieceShape.planet, family: 'Space');
  static const gems = Cosmetic('shape.gem', CosmeticKind.shape, 'Gems', [], CoinUnlock(750),
      shape: PieceShape.gem, family: 'Space');
  static const moons = Cosmetic('shape.moon', CosmeticKind.shape, 'Moons', [], CoinUnlock(600),
      shape: PieceShape.moon, family: 'Space');
  static const strawberries = Cosmetic('shape.strawberry', CosmeticKind.shape, 'Strawberries', [], CoinUnlock(450),
      shape: PieceShape.strawberry, family: 'Fruits');
  static const apples = Cosmetic('shape.apple', CosmeticKind.shape, 'Apples', [], CoinUnlock(400),
      shape: PieceShape.apple, family: 'Fruits');
  static const cherries = Cosmetic('shape.cherry', CosmeticKind.shape, 'Cherries', [], GiftUnlock(40),
      shape: PieceShape.cherry, family: 'Fruits');

  static const day = Cosmetic('sky.day', CosmeticKind.sky, 'Day', [
    Color(0xFF5CC8FF),
    Color(0xFF7FA8FF),
    Color(0xFFA98BFF),
  ], FreeUnlock());




  static const all = [
    classic, //
    bubbles, jelly, hearts, stars, flowers,
    kitties, bunnies, bears, frogs,
    donuts, cupcakes, macarons,
    planets, gems, moons,
    strawberries, apples, cherries,
    day,
  ];

  static const defaultBalls = classic;
  static const defaultShape = bubbles;
  static const defaultSky = day;

  static List<Cosmetic> ofKind(CosmeticKind kind) => [
    for (final c in all)
      if (c.kind == kind) c,
  ];

  static Cosmetic? byId(String id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }
}
