import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:project_pop/game/board_layout.dart';

void main() {
  for (final size in const [Size(360, 640), Size(430, 760), Size(1024, 700), Size(320, 480)]) {
    test('board fits inside $size', () {
      final layout = BoardLayout(size, columns: 6, rows: 10);
      final area = Offset.zero & size;
      expect(area.contains(layout.rect.topLeft), isTrue);
      expect(layout.rect.right, lessThanOrEqualTo(size.width));
      expect(layout.rect.bottom, lessThanOrEqualTo(size.height));
      // Room for the held orb above the board.
      expect(layout.rect.top, greaterThanOrEqualTo(layout.cell));
    });
  }

  test('columnAt maps x to columns and clamps at the edges', () {
    final layout = BoardLayout(const Size(400, 800), columns: 6, rows: 10);
    expect(layout.columnAt(layout.center(0, 0).dx), 0);
    expect(layout.columnAt(layout.center(3, 0).dx), 3);
    expect(layout.columnAt(-50), 0);
    expect(layout.columnAt(5000), 5);
  });

  test('row 0 is at the bottom', () {
    final layout = BoardLayout(const Size(400, 800), columns: 6, rows: 10);
    expect(layout.center(0, 0).dy, greaterThan(layout.center(0, 9).dy));
  });
}
