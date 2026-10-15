import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:pop_core/pop_core.dart';

import 'orb_painter.dart';
import 'palette.dart';
import 'pop_game.dart';
import 'timings.dart';
import 'visual_orb.dart';

/// Draws the board, aim guide and orbs. Reads state; never changes it.
class BoardComponent extends Component {
  BoardComponent(this.game);

  final PopGame game;

  @override
  void render(Canvas canvas) {
    final layout = game.layout;
    if (layout == null) return;
    final rules = game.rules;
    final board = rules.board;
    final rect = layout.rect;
    final cell = layout.cell;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.inflate(cell * 0.12), Radius.circular(cell * 0.3)),
      Paint()..color = Palette.board,
    );

    final aim = game.aimColumn;
    for (var col = 0; col < layout.columns; col++) {
      final lane = Rect.fromLTWH(rect.left + col * cell, rect.top, cell, rect.height);
      final color = col == aim
          ? Palette.aimLane
          : (col.isEven ? Palette.laneA : Palette.laneB);
      canvas.drawRect(lane.deflate(cell * 0.03), Paint()..color = color);

      // Danger warning: column within two cells of the top.
      if (board.height(col) >= layout.rows - 2) {
        canvas.drawRect(
          Rect.fromLTWH(lane.left, rect.top, cell, cell * 0.12),
          Paint()..color = Palette.danger,
        );
      }
    }

    final radius = cell * 0.42;
    canvas.save();
    // Hide orbs while they are below the floor (rising rows slide in).
    canvas.clipRect(Rect.fromLTRB(
        rect.left - cell, rect.top - cell * 2, rect.right + cell, rect.bottom));

    if (aim != null && !rules.isOver) {
      final row = rules.landingRow(aim);
      final held = VisualOrb(Cell.orb(rules.currentColor), aim.toDouble(), layout.rows + 0.2);
      paintOrb(canvas, layout.center(held.col, held.row), radius, held);
      if (row != null) {
        canvas.drawCircle(
          layout.center(aim.toDouble(), row.toDouble()),
          radius,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = cell * 0.06
            ..color = Palette.orbs[rules.currentColor].withValues(alpha: 0.8),
        );
      }
    }

    final scene = game.scene;
    for (final orb in scene.orbs) {
      var center = layout.center(orb.col, orb.row);
      if (scene.shakeTime > 0 && orb.col.round() == scene.shakeColumn) {
        final t = scene.shakeTime / Timings.shake;
        center = center.translate(math.sin(t * math.pi * 6) * cell * 0.08 * t, 0);
      }
      paintOrb(canvas, center, radius, orb);
    }
    canvas.restore();
  }
}
