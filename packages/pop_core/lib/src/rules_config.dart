import 'dart:math' as math;

/// What a risen row is made of. Used for the shells-vs-stones experiment.
enum RisingRowKind {
  /// Encased orbs: a pop next to one cracks it into a normal orb of its colour.
  shells,

  /// Grey blocks: a pop next to one simply removes it.
  stones,
}

/// Every tunable gameplay number. See docs/rules.md.
class RulesConfig {
  const RulesConfig({
    this.columns = 6,
    this.rows = 10,
    this.matchSize = 4,
    this.startColors = 4,
    this.maxColors = 5,
    this.extraColorLevel = 5,
    this.orbsPerLevel = 30,
    this.startPressure = 8,
    this.minPressure = 4,
    this.previewLength = 3,
    this.risingRowKind = RisingRowKind.shells,
    this.chainRelief = 0,
    this.levelsPerPressureStep = 2,
  });

  final int columns;
  final int rows;

  /// Minimum number of connected same-colour orbs that pop.
  final int matchSize;

  final int startColors;
  final int maxColors;

  /// Level at which the game switches from [startColors] to [maxColors].
  final int extraColorLevel;

  final int orbsPerLevel;

  /// Drops between rising rows at level 1. Shrinks by one per level.
  final int startPressure;
  final int minPressure;

  /// How many upcoming orbs are visible, including the current one.
  final int previewLength;

  final RisingRowKind risingRowKind;

  /// Drops added back to the countdown by a chain of 2+ steps, never above
  /// the current interval. 0 turns it off.
  final int chainRelief;

  /// The countdown shortens by one every [levelsPerPressureStep] levels.
  final int levelsPerPressureStep;

  int pressureInterval(int level) => math.max(
      minPressure, startPressure - (level - 1) ~/ levelsPerPressureStep);

  int colorsForLevel(int level) =>
      level >= extraColorLevel ? maxColors : startColors;

  RulesConfig copyWith({
    int? matchSize,
    int? orbsPerLevel,
    int? startPressure,
    int? minPressure,
    RisingRowKind? risingRowKind,
    int? chainRelief,
    int? levelsPerPressureStep,
    int? extraColorLevel,
  }) {
    return RulesConfig(
      columns: columns,
      rows: rows,
      matchSize: matchSize ?? this.matchSize,
      startColors: startColors,
      maxColors: maxColors,
      extraColorLevel: extraColorLevel ?? this.extraColorLevel,
      orbsPerLevel: orbsPerLevel ?? this.orbsPerLevel,
      startPressure: startPressure ?? this.startPressure,
      minPressure: minPressure ?? this.minPressure,
      previewLength: previewLength,
      risingRowKind: risingRowKind ?? this.risingRowKind,
      chainRelief: chainRelief ?? this.chainRelief,
      levelsPerPressureStep: levelsPerPressureStep ?? this.levelsPerPressureStep,
    );
  }
}
