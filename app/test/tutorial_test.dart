import 'package:flutter_test/flutter_test.dart';
import 'package:pop_core/pop_core.dart';
import 'package:project_pop/game/tutorial.dart';

void main() {
  test('the first drop in the hinted column sets off a chain', () {
    final game = Tutorial.game(const RulesConfig(), 1);
    final result = game.drop(Tutorial.dropColumn);
    expect(result.events.whereType<ChainStep>(), isNotEmpty);
  });

  test('after one miss, the next drop in the hinted column still pops', () {
    for (var miss = 0; miss < const RulesConfig().columns; miss++) {
      if (miss == Tutorial.dropColumn) continue;
      final game = Tutorial.game(const RulesConfig(), 1);
      final first = game.drop(miss);
      expect(first.events.whereType<ChainStep>(), isEmpty, reason: 'miss in column $miss');
      final retry = game.drop(Tutorial.dropColumn);
      expect(retry.events.whereType<ChainStep>(), isNotEmpty, reason: 'retry after column $miss');
    }
  });
}
