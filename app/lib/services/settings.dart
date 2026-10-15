import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Everything saved between launches: player preferences, best score and
/// whether the tutorial has been seen. Reads once at start-up; every change
/// is written straight away.
class Settings extends ChangeNotifier {
  Settings._(this._prefs);

  static const _soundKey = 'sound';
  static const _hapticsKey = 'haptics';
  static const _bestKey = 'best';
  static const _tutorialKey = 'tutorialDone';
  static const _gamesKey = 'gamesPlayed';

  final SharedPreferences? _prefs;

  /// Loads saved settings. If storage is unavailable, the game still runs
  /// with defaults (nothing is saved).
  static Future<Settings> load() async {
    try {
      return Settings._(await SharedPreferences.getInstance());
    } catch (e) {
      debugPrint('Settings storage unavailable: $e');
      return Settings._(null);
    }
  }

  /// In-memory settings for tests.
  @visibleForTesting
  factory Settings.memory() => Settings._(null);

  late bool _sound = _prefs?.getBool(_soundKey) ?? true;
  late bool _haptics = _prefs?.getBool(_hapticsKey) ?? true;
  late int _best = _prefs?.getInt(_bestKey) ?? 0;
  late bool _tutorialDone = _prefs?.getBool(_tutorialKey) ?? false;
  late int _gamesPlayed = _prefs?.getInt(_gamesKey) ?? 0;

  bool get sound => _sound;
  bool get haptics => _haptics;
  int get best => _best;
  bool get tutorialDone => _tutorialDone;
  int get gamesPlayed => _gamesPlayed;

  set sound(bool value) {
    _sound = value;
    _prefs?.setBool(_soundKey, value);
    notifyListeners();
  }

  set haptics(bool value) {
    _haptics = value;
    _prefs?.setBool(_hapticsKey, value);
    notifyListeners();
  }

  set tutorialDone(bool value) {
    _tutorialDone = value;
    _prefs?.setBool(_tutorialKey, value);
    notifyListeners();
  }

  /// Records a finished round. Returns true if it set a new best.
  bool recordRound(int score) {
    _gamesPlayed++;
    _prefs?.setInt(_gamesKey, _gamesPlayed);
    final isBest = score > _best;
    if (isBest) {
      _best = score;
      _prefs?.setInt(_bestKey, score);
    }
    notifyListeners();
    return isBest;
  }
}
