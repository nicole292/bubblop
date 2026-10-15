/// Everything the Flutter HUD shows, published by [PopGame].
class HudState {
  const HudState({
    this.score = 0,
    this.best = 0,
    this.level = 1,
    this.queue = const [],
    this.pressure = 0,
    this.pressureMax = 0,
    this.banner,
    this.bannerId = 0,
    this.isOver = false,
    this.longestChain = 0,
    this.moves = 0,
    this.spritesVersion = 0,
  });

  /// Displayed score: grows as each chain step finishes animating.
  final int score;
  final int best;
  final int level;

  /// Colour indices: current orb first.
  final List<int> queue;

  /// Drops left until the next row rises.
  final int pressure;
  final int pressureMax;

  /// Short announcement ("Board clear!"); [bannerId] changes each time.
  final String? banner;
  final int bannerId;

  /// True once the game-over moment has finished animating.
  final bool isOver;

  /// Round summary for the results panel.
  final int longestChain;
  final int moves;

  /// Bumped when orb sprites are rebaked, so HUD icons redraw.
  final int spritesVersion;

  HudState copyWith({
    int? score,
    int? best,
    int? level,
    List<int>? queue,
    int? pressure,
    int? pressureMax,
    String? banner,
    int? bannerId,
    bool? isOver,
    int? longestChain,
    int? moves,
    int? spritesVersion,
  }) {
    return HudState(
      score: score ?? this.score,
      best: best ?? this.best,
      level: level ?? this.level,
      queue: queue ?? this.queue,
      pressure: pressure ?? this.pressure,
      pressureMax: pressureMax ?? this.pressureMax,
      banner: banner ?? this.banner,
      bannerId: bannerId ?? this.bannerId,
      isOver: isOver ?? this.isOver,
      longestChain: longestChain ?? this.longestChain,
      moves: moves ?? this.moves,
      spritesVersion: spritesVersion ?? this.spritesVersion,
    );
  }
}
