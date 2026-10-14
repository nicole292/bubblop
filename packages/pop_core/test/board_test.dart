import 'package:pop_core/pop_core.dart';
import 'package:test/test.dart';

void main() {
  test('parse and toPicture round-trip, top line first', () {
    final board = Board.parse('''
      .r....
      RG#B.P
    ''');
    expect(board.at(0, 0), const Cell.orb(0));
    expect(board.at(1, 1), const Cell.shell(0));
    expect(board.at(2, 0), const Cell.stone());
    expect(board.at(4, 0), isNull);
    expect(board.toPicture().split('\n').last, 'RG#B.P');
    expect(Board.parse(board.toPicture()).toPicture(), board.toPicture());
  });

  test('height is the landing row; full columns are detected', () {
    final board = Board.parse('''
      R.....
      R.....
    ''', rows: 2);
    expect(board.height(0), 2);
    expect(board.height(1), 0);
    expect(board.isColumnFull(0), isTrue);
    expect(board.isFull, isFalse);
  });

  test('copy is independent', () {
    final board = Board.parse('R.....');
    final copy = board.copy()..set(0, 0, null);
    expect(board.at(0, 0), isNotNull);
    expect(copy.at(0, 0), isNull);
  });

  test('rejects malformed pictures', () {
    expect(() => Board.parse('RRR'), throwsArgumentError);
    expect(() => Board.parse('RRRRRX'), throwsArgumentError);
  });
}
