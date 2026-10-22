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
      // Room for the held orb above the board and the tray below it.
      expect(layout.cardTop, greaterThanOrEqualTo(0));
      expect(layout.headerRect.bottom, lessThanOrEqualTo(layout.rect.top - layout.cell * BoardLayout.headroomCells + 1e-6));
      // Tray balls are drawn at 62% of a ball (radius 0.44 cell).
      expect(layout.trayCenterY + layout.cell * 0.44 * 0.62, lessThanOrEqualTo(layout.cardBottom));
      expect(layout.cardBottom, lessThanOrEqualTo(size.height));
    });
  }

  test('on a phone the card covers most of the screen', () {
    const size = Size(390, 763);
    final layout = BoardLayout(size, columns: 6, rows: 10);
    final card = layout.cardRect;
    expect(card.width * card.height, greaterThan(size.width * size.height * 0.75));
    expect(card.top, greaterThanOrEqualTo(0));
    expect(card.bottom, lessThanOrEqualTo(size.height));
    // The header sits above the room for the held orb.
    expect(layout.headerRect.bottom, lessThanOrEqualTo(layout.rect.top - layout.cell * BoardLayout.headroomCells + 1e-6));
  });

  for (final size in const [Size(390, 600), Size(390, 763), Size(430, 860)]) {
    test('on a phone ($size) the card fills the width', () {
      final layout = BoardLayout(size, columns: 6, rows: 10);
      expect(layout.cardRect.width, closeTo(size.width - BoardLayout.padding * 2, 0.5));
      expect(layout.columnWidth, greaterThanOrEqualTo(layout.cell));
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
