/// Points for one popped group of [size] orbs: 4 → 40, 5 → 80, 6 → 150.
int groupPoints(int size) => 10 * size + 15 * (size - 4) * (size - 3);

const shellCrackPoints = 5;

/// Points for one chain step. Groups are summed, +50% per extra distinct
/// colour, cracked shells are added, then everything is multiplied by step².
int chainStepPoints({
  required List<int> groupSizes,
  required int distinctColors,
  required int cracked,
  required int step,
}) {
  final base = groupSizes.fold(0, (sum, size) => sum + groupPoints(size));
  final withColorBonus = base * (1 + distinctColors) ~/ 2;
  return (withColorBonus + cracked * shellCrackPoints) * step * step;
}

int boardClearBonus(int level) => 1000 * level;
