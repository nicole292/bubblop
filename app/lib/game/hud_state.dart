/// Everything the Flutter HUD shows, published by [PopGame].
class HudState {
  const HudState({
    this.score = 0,
    this.gain = 0,
    this.gainId = 0,
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
    this.hint,
    this.hintColumn,
    this.newBest = false,
  });

  /// Displayed score: grows as each chain step finishes animating.
  final int score;

  /// The latest points added to [score]; [gainId] changes with each gain.
  final int gain;
  final int gainId;
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

  /// Tutorial hint text, and the column it points at (if any).
  final String? hint;
  final int? hintColumn;

  /// True when the finished round set a new best score.
  final bool newBest;

  HudState copyWith({
    int? score,
    int? gain,
    int? gainId,
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
    String? hint,
    int? hintColumn,
    bool clearHint = false,
    bool? newBest,
  }) {
    return HudState(
      score: score ?? this.score,
      gain: gain ?? this.gain,
      gainId: gainId ?? this.gainId,
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
      hint: clearHint ? null : hint ?? this.hint,
      hintColumn: clearHint ? null : hintColumn ?? this.hintColumn,
      newBest: newBest ?? this.newBest,
    );
  }
}
