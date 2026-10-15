import 'package:flutter_test/flutter_test.dart';
import 'package:project_pop/game/phase_queue.dart';

void main() {
  test('phases run in order and report progress', () {
    final log = <String>[];
    final queue = PhaseQueue()
      ..addAll([
        Phase(1, onStart: () => log.add('a start'), onEnd: () => log.add('a end')),
        Phase(1, onStart: () => log.add('b start'), onUpdate: (t) => log.add('b $t')),
      ]);
    queue.update(0.5);
    expect(log, ['a start']);
    queue.update(1.0);
    expect(log, ['a start', 'a end', 'b start', 'b 0.5']);
    queue.update(5);
    expect(log.last, 'b 1.0');
    expect(queue.isIdle, isTrue);
  });

  test('speed makes time pass faster and resets when idle', () {
    var ended = false;
    final queue = PhaseQueue()
      ..addAll([Phase(0.3, onEnd: () => ended = true)])
      ..speed = 3;
    queue.update(0.1);
    expect(ended, isTrue);
    queue.update(0);
    expect(queue.speed, 1);
  });

  test('zero-length phases complete immediately', () {
    var count = 0;
    final queue = PhaseQueue()..addAll([Phase(0, onEnd: () => count++), Phase(0, onEnd: () => count++)]);
    queue.update(0);
    expect(count, 2);
  });

  test('clear drops pending phases', () {
    var ran = false;
    final queue = PhaseQueue()..addAll([Phase(1, onStart: () => ran = true)]);
    queue.clear();
    queue.update(5);
    expect(ran, isFalse);
  });
}
