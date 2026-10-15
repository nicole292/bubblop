import 'package:flutter_test/flutter_test.dart';
import 'package:pop_core/pop_core.dart';
import 'package:project_pop/game/board_scene.dart';
import 'package:project_pop/game/phase_queue.dart';

/// Event types seen across all games, to prove the tests exercise them.
final seen = <String, int>{};

/// Plays a seeded game; after each drop, animates for [frameSeconds]
/// (possibly not long enough to finish) before the next drop.
({Game rules, BoardScene scene, PhaseQueue phases, int points}) play({
  required int seed,
  required RulesConfig config,
  required double frameSeconds,
  int maxMoves = 300,
}) {
  final rules = Game(seed: seed, config: config);
  // Rounds start with balls on the board; the app loads them the same way.
  final scene = BoardScene(config.columns, config.rows)..load(rules.board);
  final phases = PhaseQueue();
  var points = 0;
  scene.onPoints = (p) => points += p;

  for (var move = 0; move < maxMoves && !rules.isOver; move++) {
    // Pick the lowest column so games run long and chain often.
    var column = 0;
    for (var c = 1; c < config.columns; c++) {
      if (rules.board.height(c) < rules.board.height(column)) column = c;
    }
    if (!phases.isIdle) phases.speed = 3;
    final result = rules.drop((column + move) % config.columns);
    final events = result.accepted ? result.events : rules.drop(column).events;
    for (final e in events) {
      seen[e is ChainStep && e.step > 1 ? 'chain2+' : e.runtimeType.toString()] =
          (seen[e.runtimeType.toString()] ?? 0) + 1;
      if (e is ChainStep && e.cracked.isNotEmpty) seen['crack'] = 1;
      phases.addAll(scene.phasesFor(e));
    }
    phases.update(frameSeconds);
  }
  phases.update(1000); // let everything finish
  return (rules: rules, scene: scene, phases: phases, points: points);
}

void main() {
  tearDownAll(() {
    for (final kind in ['ChainStep', 'chain2+', 'crack', 'RowRose', 'GameOver', 'LevelUp']) {
      expect(seen.keys, contains(kind), reason: 'no game produced $kind');
    }
  });

  test('load shows a pre-filled board exactly, including shells', () {
    final board = Board.parse('''
      GG....
      YRR...
      RgGR..
      RBBB..
    ''');
    final scene = BoardScene(6, 10)..load(board);
    expect(scene.toBoard().toPicture(), board.toPicture());
  });

  test('a pre-filled board plays through to the same picture', () {
    final rules = Game(
      seed: 1,
      board: Board.parse('''
        GG....
        YRR...
        RgGR..
        RBBB..
      '''),
      scriptedQueue: [3],
    );
    final scene = BoardScene(6, 10)..load(rules.board);
    final phases = PhaseQueue();
    for (final e in rules.drop(4).events) {
      phases.addAll(scene.phasesFor(e));
    }
    phases.update(1000);
    expect(scene.toBoard().toPicture(), rules.board.toPicture());
  });

  for (final kind in RisingRowKind.values) {
    group('${kind.name}:', () {
      // Fast levelling so level-ups, faster pressure and colour 5 all occur.
      final config = RulesConfig(risingRowKind: kind, orbsPerLevel: 8);

      test('after animations finish, the scene equals the rules board', () {
        for (var seed = 1; seed <= 20; seed++) {
          final r = play(seed: seed, config: config, frameSeconds: 1000);
          expect(r.scene.toBoard().toPicture(), r.rules.board.toPicture(),
              reason: 'seed $seed');
        }
      });

      test('moves made mid-animation still end in the same picture', () {
        for (var seed = 1; seed <= 20; seed++) {
          for (final frame in [0.0, 0.016, 0.05, 0.12]) {
            final r = play(seed: seed, config: config, frameSeconds: frame);
            expect(r.scene.toBoard().toPicture(), r.rules.board.toPicture(),
                reason: 'seed $seed, frame $frame');
            expect(r.points, r.rules.score, reason: 'displayed score');
            expect(r.phases.isIdle, isTrue);
          }
        }
      });
    });
  }
}
