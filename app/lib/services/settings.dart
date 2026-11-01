import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Light or dark look: [auto] follows the phone.
enum ThemeChoice { auto, light, dark }

/// Everything saved between launches: player preferences, best score and
/// whether the tutorial has been seen. Reads once at start-up; every change
/// is written straight away.
class Settings extends ChangeNotifier {
  Settings._(this._prefs);

  static const _soundKey = 'sound';
  static const _musicKey = 'music';
  static const _hapticsKey = 'haptics';
  static const _bestKey = 'best';
  static const _bestLevelKey = 'bestLevel';
  static const _tutorialKey = 'tutorialDone';
  static const _gamesKey = 'gamesPlayed';
  static const _themeKey = 'theme';
  static const _facesKey = 'faces';

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

  /// In-memory settings (tests and developer screenshot runs).
  factory Settings.memory() => Settings._(null);

  late bool _sound = _prefs?.getBool(_soundKey) ?? true;
  late bool _music = _prefs?.getBool(_musicKey) ?? true;
  late bool _haptics = _prefs?.getBool(_hapticsKey) ?? true;
  late int _best = _prefs?.getInt(_bestKey) ?? 0;
  late int _bestLevel = _prefs?.getInt(_bestLevelKey) ?? 0;
  late bool _tutorialDone = _prefs?.getBool(_tutorialKey) ?? false;
  late int _gamesPlayed = _prefs?.getInt(_gamesKey) ?? 0;
  late bool _faces = _prefs?.getBool(_facesKey) ?? true;
  late ThemeChoice _theme =
      ThemeChoice.values.where((t) => t.name == _prefs?.getString(_themeKey)).firstOrNull ?? ThemeChoice.auto;

  bool get sound => _sound;

  /// Quiet background music, separate from the sound effects.
  bool get music => _music;
  bool get haptics => _haptics;
  int get best => _best;

  /// The highest level reached in a Classic round (0 before the first).
  int get bestLevel => _bestLevel;
  bool get tutorialDone => _tutorialDone;
  int get gamesPlayed => _gamesPlayed;
  ThemeChoice get theme => _theme;

  /// Cute faces on the balls that react to the game.
  bool get faces => _faces;

  set faces(bool value) {
    _faces = value;
    _prefs?.setBool(_facesKey, value);
    notifyListeners();
  }

  set sound(bool value) {
    _sound = value;
    _prefs?.setBool(_soundKey, value);
    notifyListeners();
  }

  set music(bool value) {
    _music = value;
    _prefs?.setBool(_musicKey, value);
    notifyListeners();
  }

  set haptics(bool value) {
    _haptics = value;
    _prefs?.setBool(_hapticsKey, value);
    notifyListeners();
  }

  set theme(ThemeChoice value) {
    _theme = value;
    _prefs?.setString(_themeKey, value.name);
    notifyListeners();
  }

  set tutorialDone(bool value) {
    _tutorialDone = value;
    _prefs?.setBool(_tutorialKey, value);
    notifyListeners();
  }

  /// Records a finished round and the level it reached. Returns true if it
  /// set a new best score.
  bool recordRound(int score, {int level = 0}) {
    _gamesPlayed++;
    _prefs?.setInt(_gamesKey, _gamesPlayed);
    if (level > _bestLevel) {
      _bestLevel = level;
      _prefs?.setInt(_bestLevelKey, level);
    }
    final isBest = score > _best;
    if (isBest) {
      _best = score;
      _prefs?.setInt(_bestKey, score);
    }
    notifyListeners();
    return isBest;
  }
}
