import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:pop_core/pop_core.dart';

/// Developer-only launch options, set with --dart-define. None of these are
/// reachable by players.
///
///   flutter run -d windows --dart-define=POP_DEMO=chain
///     Starts on a board where the first drop (column 5) sets off a 3-step
///     chain fed by a cracked shell, to review chain effects.
///
///   flutter run -d windows --profile --dart-define=POP_BENCH=60
///     Auto-plays quickly for 60 seconds and prints frame-time statistics.
abstract final class DevOptions {
  static const demo = String.fromEnvironment('POP_DEMO');
  static const benchSeconds = int.fromEnvironment('POP_BENCH');

  static bool get isBench => benchSeconds > 0;

  /// POP_PLAY=true skips the home screen (screenshot runs).
  static const startPlaying = bool.fromEnvironment('POP_PLAY');

  /// POP_SEED=n deals the same round every time (for comparing screenshots).
  static const _seed = int.fromEnvironment('POP_SEED', defaultValue: -1);
  static int? get seed => _seed < 0 ? null : _seed;

  /// POP_SHOT_SCALE=3 saves screenshots at 3× and bakes images for it, so
  /// store screenshots come out at exact pixel sizes (phone-frame runs only).
  static const shotScale = int.fromEnvironment('POP_SHOT_SCALE', defaultValue: 2);
  static const _bakeScale = int.fromEnvironment('POP_SHOT_SCALE');

  /// Resolution for baked images: the screen's, or the screenshot scale.
  static double get pixelRatio => _bakeScale > 0
      ? _bakeScale.toDouble()
      : WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;

  /// POP_PROGRESS=n starts phone-frame screenshot runs with levels 1..n
  /// completed (in memory only; a player's saved progress is never used).
  static const progressLevels = int.fromEnvironment('POP_PROGRESS');

  /// POP_DEV=true shows the developer bar (4/3-match switch, session stats).
  static const showDevBar = bool.fromEnvironment('POP_DEV');

  /// POP_SKIP=bg,board,fx,orbs,dock,hud : turns layers off to find what costs
  /// raster time (profiling only).
  static const _skip = String.fromEnvironment('POP_SKIP');
  static bool skip(String layer) => _skip.split(',').contains(layer);

  /// Board and queue for the chain demo (same board as the 3-step chain
  /// test in pop_core).
  static Game? demoGame(RulesConfig config) {
    if (demo != 'chain') return null;
    return Game(
      seed: 1,
      config: config,
      board: Board.parse('''
        GG....
        YRR...
        RgGR..
        RBBB..
      '''),
      scriptedQueue: const [3, 1, 2, 0],
    );
  }
}
