import 'package:pop_core/pop_core.dart';
import 'package:test/test.dart';

void main() {
  test('group points grow faster than group size', () {
    expect(groupPoints(4), 40);
    expect(groupPoints(5), 80);
    expect(groupPoints(6), 150);
    expect(groupPoints(7), 250);
  });

  test('chain step multiplies by step squared', () {
    int at(int step) => chainStepPoints(
        groupSizes: [4], distinctColors: 1, cracked: 0, step: step);
    expect([at(1), at(2), at(3)], [40, 160, 360]);
  });

  test('each extra colour in the same step adds 50%', () {
    expect(
        chainStepPoints(groupSizes: [4, 4], distinctColors: 1, cracked: 0, step: 1),
        80);
    expect(
        chainStepPoints(groupSizes: [4, 4], distinctColors: 2, cracked: 0, step: 1),
        120);
  });

  test('cracked shells add 5 each before the multiplier', () {
    expect(
        chainStepPoints(groupSizes: [4], distinctColors: 1, cracked: 2, step: 2),
        (40 + 10) * 4);
  });

  test('board clear bonus scales with level', () {
    expect(boardClearBonus(1), 1000);
    expect(boardClearBonus(3), 3000);
  });
}
