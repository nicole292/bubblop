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

  /// POP_SKIP=bg,blur,floor,fx,board : turns layers off to find what costs
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
