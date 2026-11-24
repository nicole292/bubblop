// Lists levels whose card could mislead the player: twists that never
// happen, or goals that need something the level doesn't have.
//
//   cd packages/pop_core
//   dart run tool/audit_levels.dart

import 'package:pop_core/pop_core.dart';

void main() {
  final counts = <String, int>{};
  void flag(LevelDef l, String why) {
    counts[why] = (counts[why] ?? 0) + 1;
    if (counts[why]! <= 4) {
      print('${l.number}: $why  [${l.goals.map((g) => g.text).join(', ')}; '
          '${l.setup.name}; still=${l.still}; layout=${l.layout != null}]');
    }
  }

  for (final l in Campaign.levels) {
    final game = l.newGame();
    final pic = game.board.toPicture();
    final kinds = l.goals.map((g) => g.kind).toList();
    final twist = l.twist;
    if (twist != null && twist.$2.startsWith('Starts') && l.layout != null) {
      flag(l, 'card says how it starts, but the layout replaces that');
    }
    if (l.still && l.setup != LevelSetup.normal) flag(l, 'puzzle with a rising-row twist');
    if (kinds.toSet().length != kinds.length) flag(l, 'same goal twice');
    final shellsOnBoard = pic.contains(RegExp('[a-z]'));
    final shellsRise = game.config.rowsRise && game.config.risingRowKind == RisingRowKind.shells;
    if (kinds.contains(GoalKind.crack) && !shellsOnBoard && !shellsRise) flag(l, 'crack goal without shells');
    if (kinds.contains(GoalKind.blast) && !pic.contains('*') && (game.config.bombEvery == 0 || !game.config.rowsRise)) {
      flag(l, 'blast goal without bombs');
    }
    final chain = l.goals.where((g) => g.kind == GoalKind.chain).firstOrNull;
    if (chain != null && chain.target < 2) flag(l, 'chain of 1');
  }
  print(counts.isEmpty ? 'No problems found.' : counts);
}
