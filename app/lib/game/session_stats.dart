import 'dart:math' as math;

import 'package:pop_core/pop_core.dart';

/// One finished round, for the shells-vs-stones experiment.
class RoundSummary {
  const RoundSummary({
    required this.mode,
    required this.score,
    required this.moves,
    required this.longestChain,
    required this.chainMoves,
    required this.shellChainMoves,
  });

  final String mode;
  final int score;
  final int moves;
  final int longestChain;

  /// Moves that produced a chain of 2+ steps.
  final int chainMoves;

  /// Chains where a shell cracked before the final step, so the revealed
  /// orb could have fed the chain. An approximation; good enough to compare.
  final int shellChainMoves;
}

/// In-memory stats for this play session (not saved yet).
class SessionStats {
  final List<RoundSummary> rounds = [];

  String _mode = '';
  int _longest = 0;
  int _chainMoves = 0;
  int _shellChainMoves = 0;

  static String modeName(RulesConfig config) =>
      '${config.risingRowKind.name}, ${config.matchSize}-match';

  void startRound(RulesConfig config) {
    _mode = modeName(config);
    _longest = 0;
    _chainMoves = 0;
    _shellChainMoves = 0;
  }

  void recordMove(MoveResult result) {
    final steps = result.events.whereType<ChainStep>().toList();
    _longest = math.max(_longest, steps.length);
    if (steps.length < 2) return;
    _chainMoves++;
    final fedByShell = steps
        .take(steps.length - 1)
        .any((s) => s.cracked.values.any((c) => c.kind == CellKind.shell));
    if (fedByShell) _shellChainMoves++;
  }

  RoundSummary finishRound({required int score, required int moves}) {
    final summary = RoundSummary(
      mode: _mode,
      score: score,
      moves: moves,
      longestChain: _longest,
      chainMoves: _chainMoves,
      shellChainMoves: _shellChainMoves,
    );
    rounds.add(summary);
    return summary;
  }

  int get bestScore => rounds.fold(0, (best, r) => math.max(best, r.score));

  /// A plain-text table per mode, easy to paste into a chat.
  String report() {
    if (rounds.isEmpty) return 'No finished rounds yet.';
    final byMode = <String, List<RoundSummary>>{};
    for (final r in rounds) {
      byMode.putIfAbsent(r.mode, () => []).add(r);
    }
    final buf = StringBuffer();
    byMode.forEach((mode, list) {
      double avg(num Function(RoundSummary) f) =>
          list.fold<num>(0, (sum, r) => sum + f(r)) / list.length;
      final chains = list.fold(0, (sum, r) => sum + r.chainMoves);
      final shellChains = list.fold(0, (sum, r) => sum + r.shellChainMoves);
      buf
        ..writeln('[$mode] rounds: ${list.length}')
        ..writeln('  avg score ${avg((r) => r.score).round()}, '
            'avg moves ${avg((r) => r.moves).round()}, '
            'best chain ${list.map((r) => r.longestChain).reduce(math.max)}')
        ..writeln('  chains: $chains, fed by a shell: $shellChains');
    });
    return buf.toString().trimRight();
  }
}
