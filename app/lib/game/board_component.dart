import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:pop_core/pop_core.dart';

import 'board_layout.dart';
import 'orb_painter.dart';
import 'palette.dart';
import 'pop_game.dart';
import 'timings.dart';
import 'visual_orb.dart';

/// Draws the board, aim guide, orbs, effects and next-row tray.
/// Reads state; never changes it.
class BoardComponent extends Component {
  BoardComponent(this.game);

  final PopGame game;
  double _time = 0;

  @override
  void update(double dt) => _time += dt;

  @override
  void render(Canvas canvas) {
    final layout = game.layout;
    final sprites = game.sprites;
    if (layout == null || sprites == null) return;
    final rules = game.rules;
    final board = rules.board;
    final rect = layout.rect;
    final cell = layout.cell;
    final aim = rules.isOver ? null : game.aimColumn;

    _paintTray(canvas, layout);
    _paintBoard(canvas, layout);

    // Aim: a soft beam of the current orb's colour down the column.
    if (aim != null) {
      final lane = Rect.fromLTWH(rect.left + aim * cell, rect.top, cell, rect.height);
      final color = Palette.orbs[rules.currentColor];
      canvas.drawRect(
        lane,
        Paint()
          ..shader = Gradient.linear(lane.topCenter, lane.bottomCenter, [
            color.withValues(alpha: 0.20),
            color.withValues(alpha: 0.05),
          ]),
      );
    }

    // Danger: a red glow from the top of columns close to full.
    for (var col = 0; col < layout.columns; col++) {
      if (board.height(col) < layout.rows - 2) continue;
      final pulse = 0.75 + 0.25 * math.sin(_time * 6);
      final glow = Rect.fromLTWH(rect.left + col * cell, rect.top, cell, cell * 1.6);
      canvas.drawRect(
        glow,
        Paint()
          ..shader = Gradient.linear(glow.topCenter, glow.bottomCenter, [
            Palette.danger.withValues(alpha: 0.45 * pulse),
            Palette.danger.withValues(alpha: 0),
          ]),
      );
    }

    canvas.save();
    // Hide orbs below the floor while a new row slides up.
    canvas.clipRect(Rect.fromLTRB(
        rect.left - cell, rect.top - cell * 2, rect.right + cell, rect.bottom));

    // Landing guide: a ring where the orb will settle.
    if (aim != null) {
      final row = rules.landingRow(aim);
      if (row != null) {
        final color = Palette.orbs[rules.currentColor];
        final at = layout.center(aim.toDouble(), row.toDouble());
        canvas.drawCircle(at, sprites.radius, Paint()..color = color.withValues(alpha: 0.12));
        canvas.drawCircle(
          at,
          sprites.radius * 0.96,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = cell * 0.045
            ..color = color.withValues(alpha: 0.75),
        );
      }
    }

    final scene = game.scene;
    final centers = <VisualOrb, Offset>{};
    for (final orb in scene.orbs) {
      var c = layout.center(orb.col, orb.row);
      if (scene.shakeTime > 0 && orb.col.round() == scene.shakeColumn) {
        final t = scene.shakeTime / Timings.shake;
        c = c.translate(math.sin(t * math.pi * 6) * cell * 0.08 * t, 0);
      }
      centers[orb] = c;
    }
    for (final e in centers.entries) {
      if (e.key.cell.kind != CellKind.stone) paintOrbShadow(canvas, sprites, e.value, e.key);
    }
    for (final e in centers.entries) {
      paintOrb(canvas, sprites, e.value, e.key);
    }
    canvas.restore();

    // Held orb, hovering over the aimed column.
    if (aim != null) {
      final held = VisualOrb(Cell.orb(rules.currentColor), aim.toDouble(), layout.rows - 0.15);
      paintOrb(canvas, sprites, layout.center(held.col, held.row), held);
    }

    game.particles.render(canvas);
  }

  void _paintBoard(Canvas canvas, BoardLayout layout) {
    final rect = layout.rect;
    final cell = layout.cell;
    final frame = RRect.fromRectAndRadius(rect.inflate(cell * 0.14), Radius.circular(cell * 0.34));

    // Drop shadow and the board light (flares on pops, stronger in chains).
    canvas.drawRRect(
      frame.shift(Offset(0, cell * 0.12)),
      Paint()
        ..color = const Color(0x99000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.35),
    );
    if (game.boardLight > 0) {
      canvas.drawRRect(
        frame.inflate(cell * 0.05),
        Paint()
          ..color = game.boardLightColor.withValues(alpha: 0.55 * game.boardLight)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.45),
      );
    }

    // Recessed tray.
    canvas.drawRRect(
      frame,
      Paint()
        ..shader = Gradient.linear(frame.outerRect.topCenter, frame.outerRect.bottomCenter,
            const [Palette.boardTop, Palette.boardBottom]),
    );
    // Inner shadow along the top edge sells the depth.
    final lip = Rect.fromLTWH(frame.left, frame.top, frame.width, cell * 0.8);
    canvas.save();
    canvas.clipRRect(frame);
    canvas.drawRect(
      lip,
      Paint()
        ..shader = Gradient.linear(lip.topCenter, lip.bottomCenter,
            const [Color(0x66000000), Color(0x00000000)]),
    );
    canvas.restore();

    // Column grooves.
    final groove = Paint()
      ..color = Palette.groove
      ..strokeWidth = math.max(1, cell * 0.025);
    for (var c = 1; c < layout.columns; c++) {
      final x = rect.left + c * cell;
      canvas.drawLine(Offset(x, rect.top + cell * 0.2), Offset(x, rect.bottom - cell * 0.2), groove);
    }

    // Rim: catches the light at the top, fades toward the bottom.
    canvas.drawRRect(
      frame,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, cell * 0.035)
        ..shader = Gradient.linear(frame.outerRect.topCenter, frame.outerRect.bottomCenter,
            const [Palette.rimLight, Palette.rimDark]),
    );
  }

  /// The next row waits in a slim tray under the board, brightening as the
  /// countdown runs out.
  void _paintTray(Canvas canvas, BoardLayout layout) {
    final sprites = game.sprites!;
    final rules = game.rules;
    final rect = layout.rect;
    final cell = layout.cell;
    final y = layout.trayCenterY;
    final tray = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(rect.center.dx, y), width: rect.width, height: cell * 0.74),
      Radius.circular(cell * 0.37),
    );
    canvas.drawRRect(tray, Paint()..color = Palette.trayFill);

    final urgency = rules.pressure <= 1
        ? 1.0
        : rules.pressure == 2
            ? 0.9
            : 0.75;
    final pulse = rules.pressure <= 1 ? 0.85 + 0.15 * math.sin(_time * 8) : 1.0;
    final row = rules.nextRow;
    const scale = 0.7;
    for (var c = 0; c < row.length; c++) {
      final orb = VisualOrb(row[c], c.toDouble(), 0)
        ..scale = scale
        ..alpha = urgency * pulse;
      paintOrb(canvas, sprites, Offset(rect.left + (c + 0.5) * cell, y), orb);
    }
  }
}
