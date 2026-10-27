enum AchievementId { firstLevel, firstChain, fiveLevels, tenLevels, personalBest, allLevels }

/// A milestone. Each unlocks once and pays its coins once, at that moment.
/// [target] is the number of completed levels it needs (null when it is a
/// one-off event instead).
class Achievement {
  const Achievement(this.id, this.title, this.description, this.coins, {this.target});

  final AchievementId id;
  final String title;
  final String description;
  final int coins;
  final int? target;
}

abstract final class Achievements {
  static const all = [
    Achievement(AchievementId.firstLevel, 'First win', 'Complete your first level', 20, target: 1),
    Achievement(AchievementId.firstChain, 'Chain reaction', 'Set off a chain of 2 or more', 20),
    Achievement(AchievementId.fiveLevels, 'Getting going', 'Complete 5 levels', 40, target: 5),
    Achievement(AchievementId.tenLevels, 'On a roll', 'Complete 10 levels', 60, target: 10),
    Achievement(AchievementId.personalBest, 'Personal best', 'Set a new best score in Endless', 30),
    Achievement(AchievementId.allLevels, 'Bubblop master', 'Complete all 30 levels', 250, target: 30),
  ];

  static Achievement of(AchievementId id) => all.firstWhere((a) => a.id == id);
}
