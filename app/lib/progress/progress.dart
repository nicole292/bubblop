import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:pop_core/pop_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'achievements.dart';
import 'cosmetics.dart';
import 'rewards.dart';

/// What finishing a level gave the player, for the victory card.
class LevelClear {
  const LevelClear({
    required this.level,
    required this.firstTime,
    required this.score,
    required this.bestScore,
    this.previousBest,
    required this.coins,
    required this.gift,
    this.giftContents,
    this.duplicateCosmetic = false,
    this.achievements = const [],
  });

  final int level;

  /// Only the first clear pays out; replays just update the best score.
  final bool firstTime;
  final int score;
  final int bestScore;

  /// The best score before this round (null on the first clear).
  final int? previousBest;

  /// A replay that beat the earlier best.
  bool get newBest => previousBest != null && score > previousBest!;

  /// Coins for the clear itself (0 on a replay).
  final int coins;
  final GiftKind gift;
  final GiftContents? giftContents;

  /// The gift's cosmetic was already owned, so it paid
  /// [LevelRewards.duplicateCosmeticCoins] extra coins instead.
  final bool duplicateCosmetic;

  /// Achievements this clear unlocked (their coins are already added).
  final List<Achievement> achievements;
}

/// The level campaign and collection, saved on the device like [Settings]:
/// levels completed (with best scores), coins, achievements, owned and
/// selected cosmetics. Every reward is granted and saved in the same call
/// that earns it, so nothing can be claimed twice.
class Progress extends ChangeNotifier {
  Progress._(this._prefs) {
    final prefs = _prefs;
    if (prefs == null) return;
    for (final entry in prefs.getStringList(_completedKey) ?? const <String>[]) {
      final parts = entry.split(':');
      final level = int.tryParse(parts.first);
      if (level != null) _best[level] = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    }
    _rewarded.addAll((prefs.getStringList(_rewardedKey) ?? const []).map(int.tryParse).whereType<int>());
    _unlocked = math.max(prefs.getInt(_unlockedKey) ?? 1, _derivedUnlocked);
    _coins = prefs.getInt(_coinsKey) ?? 0;
    for (final name in prefs.getStringList(_achievementsKey) ?? const <String>[]) {
      final id = AchievementId.values.where((a) => a.name == name).firstOrNull;
      if (id != null) _achievements.add(id);
    }
    _owned.addAll(prefs.getStringList(_ownedKey) ?? const []);
    _balls = Cosmetics.byId(prefs.getString(_ballsKey) ?? '') ?? Cosmetics.defaultBalls;
    _sky = Cosmetics.byId(prefs.getString(_skyKey) ?? '') ?? Cosmetics.defaultSky;
    if (!owns(_balls)) _balls = Cosmetics.defaultBalls;
    if (!owns(_sky)) _sky = Cosmetics.defaultSky;
  }

  static const _completedKey = 'progress.completed';
  static const _rewardedKey = 'progress.rewarded';
  static const _unlockedKey = 'progress.unlocked';
  static const _coinsKey = 'progress.coins';
  static const _achievementsKey = 'progress.achievements';
  static const _ownedKey = 'style.owned';
  static const _ballsKey = 'style.balls';
  static const _skyKey = 'style.sky';

  final SharedPreferences? _prefs;

  /// Loads saved progress. If storage is unavailable, the game still runs
  /// (progress lasts until the app closes).
  static Future<Progress> load() async {
    try {
      return Progress._(await SharedPreferences.getInstance());
    } catch (e) {
      debugPrint('Progress storage unavailable: $e');
      return Progress._(null);
    }
  }

  /// In-memory progress (tests and developer screenshot runs).
  factory Progress.memory() => Progress._(null);

  /// Reads progress back from [prefs] (tests check that it survives a
  /// restart this way).
  @visibleForTesting
  factory Progress.from(SharedPreferences prefs) => Progress._(prefs);

  final _best = <int, int>{};
  final _rewarded = <int>{};
  int _unlocked = 1;
  int _coins = 0;
  final _achievements = <AchievementId>{};
  final _owned = <String>{};
  Cosmetic _balls = Cosmetics.defaultBalls;
  Cosmetic _sky = Cosmetics.defaultSky;

  // --- Levels -------------------------------------------------------------

  int get _derivedUnlocked {
    var next = 1;
    while (_best.containsKey(next)) {
      next++;
    }
    return math.min(next, Campaign.count);
  }

  /// The highest level that can be played. Levels unlock one at a time.
  int get unlockedLevel => _unlocked;
  bool isUnlocked(int level) => level >= 1 && level <= _unlocked;
  bool isCompleted(int level) => _best.containsKey(level);
  int get completedCount => _best.length;
  bool get allCompleted => completedCount >= Campaign.count;
  int? bestScore(int level) => _best[level];

  /// The level to offer next: the first one not yet completed.
  int get currentLevel => allCompleted ? Campaign.count : _derivedUnlocked;

  /// Records a won level. The first clear pays coins and its gift and
  /// unlocks the next level; replays only keep the best score. Ignored for
  /// levels that are not unlocked.
  LevelClear? completeLevel(int level, {required int score}) {
    if (!isUnlocked(level) || level > Campaign.count) return null;
    final firstTime = !_rewarded.contains(level);
    final previousBest = _best[level];
    _best[level] = math.max(_best[level] ?? 0, score);
    var coins = 0;
    var gift = GiftKind.none;
    GiftContents? contents;
    var duplicate = false;
    final achievements = <Achievement>[];
    if (firstTime) {
      _rewarded.add(level);
      final rewards = LevelRewards.forLevel(level);
      coins = rewards.coins;
      gift = rewards.gift;
      contents = rewards.contents;
      _coins += coins;
      if (contents != null) {
        _coins += contents.coins;
        final cosmetic = contents.cosmetic;
        if (cosmetic != null) {
          if (owns(cosmetic)) {
            duplicate = true;
            _coins += LevelRewards.duplicateCosmeticCoins;
          } else {
            _owned.add(cosmetic.id);
          }
        }
      }
      _unlocked = math.max(_unlocked, math.min(level + 1, Campaign.count));
      for (final a in Achievements.all) {
        final target = a.target;
        if (target != null && completedCount >= target) {
          final unlocked = _unlockAchievement(a.id);
          if (unlocked != null) achievements.add(unlocked);
        }
      }
    }
    _save();
    notifyListeners();
    return LevelClear(
      level: level,
      firstTime: firstTime,
      score: score,
      bestScore: _best[level]!,
      previousBest: previousBest,
      coins: coins,
      gift: gift,
      giftContents: contents,
      duplicateCosmetic: duplicate,
      achievements: achievements,
    );
  }

  // --- Coins and achievements ----------------------------------------------

  int get coins => _coins;

  bool hasAchievement(AchievementId id) => _achievements.contains(id);

  /// A drop set off a chain of [steps] (any mode). Returns the achievement
  /// it unlocked, if any.
  Achievement? recordChain(int steps) {
    if (steps < 2) return null;
    final a = _unlockAchievement(AchievementId.firstChain);
    if (a != null) {
      _save();
      notifyListeners();
    }
    return a;
  }

  /// An Endless round set a new best score.
  Achievement? recordPersonalBest() {
    final a = _unlockAchievement(AchievementId.personalBest);
    if (a != null) {
      _save();
      notifyListeners();
    }
    return a;
  }

  /// Unlocks [id] and pays its coins, once. Returns null if already had.
  Achievement? _unlockAchievement(AchievementId id) {
    if (!_achievements.add(id)) return null;
    final a = Achievements.of(id);
    _coins += a.coins;
    return a;
  }

  /// Progress towards an achievement, as (have, need).
  (int, int) achievementProgress(Achievement a) {
    final target = a.target;
    if (target != null) return (math.min(completedCount, target), target);
    return (hasAchievement(a.id) ? 1 : 0, 1);
  }

  // --- Cosmetics -----------------------------------------------------------

  bool owns(Cosmetic c) => c.unlock is FreeUnlock || _owned.contains(c.id);

  Cosmetic get balls => _balls;
  Cosmetic get sky => _sky;
  Cosmetic selected(CosmeticKind kind) => kind == CosmeticKind.balls ? _balls : _sky;

  /// Unlocks a coin cosmetic. Returns false if it isn't for sale, is
  /// already owned, or the player can't afford it.
  bool buy(Cosmetic c) {
    final unlock = c.unlock;
    if (unlock is! CoinUnlock || owns(c) || _coins < unlock.price) return false;
    _coins -= unlock.price;
    _owned.add(c.id);
    _save();
    notifyListeners();
    return true;
  }

  /// Uses an owned cosmetic. Returns false if it isn't owned.
  bool select(Cosmetic c) {
    if (!owns(c)) return false;
    if (c.kind == CosmeticKind.balls) {
      _balls = c;
    } else {
      _sky = c;
    }
    _save();
    notifyListeners();
    return true;
  }

  void _save() {
    final prefs = _prefs;
    if (prefs == null) return;
    prefs.setStringList(_completedKey, [for (final e in _best.entries) '${e.key}:${e.value}']);
    prefs.setStringList(_rewardedKey, [for (final l in _rewarded) '$l']);
    prefs.setInt(_unlockedKey, _unlocked);
    prefs.setInt(_coinsKey, _coins);
    prefs.setStringList(_achievementsKey, [for (final a in _achievements) a.name]);
    prefs.setStringList(_ownedKey, _owned.toList());
    prefs.setString(_ballsKey, _balls.id);
    prefs.setString(_skyKey, _sky.id);
  }
}
