import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:pop_core/pop_core.dart';

import '../render/orb_sprites.dart';
import 'board_layout.dart';
import 'dev_options.dart';
import 'orb_painter.dart';
import 'palette.dart';
import 'pop_game.dart';
import 'timings.dart';
import 'visual_orb.dart';

/// Draws the whole canvas: background, board card, balls, next-row dock and
/// effects. Reads state; never changes it.
class BoardComponent extends Component {
  BoardComponent(this.game);

  final PopGame game;

  // The parts of the board that never move are baked into one image per
  // layout, so a frame draws them with a single image copy.
  Image? _static;
  Rect? _staticFor;
  Rect _staticBounds = Rect.zero;

  final _fill = Paint();
  final _stroke = Paint()..style = PaintingStyle.stroke;
  final _imagePaint = Paint()..filterQuality = FilterQuality.medium;

  @override
  void onRemove() {
    _static?.dispose();
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    final layout = game.layout;
    final sprites = game.sprites;
    if (!DevOptions.skip('bg')) game.background.render(canvas);
    if (layout == null || sprites == null) return;

    final rules = game.rules;
    final board = rules.board;
    final rect = layout.rect;
    final cell = layout.cell;
    final aim = rules.isOver ? null : game.aimColumn;
    final time = game.time;

    canvas.save();
    if (game.shake > 0) {
      canvas.translate(math.sin(time * 90) * game.shake, math.cos(time * 77) * game.shake * 0.6);
    }

    if (!DevOptions.skip('board')) {
      _ensureStatic(layout);
      final image = _static!;
      canvas.drawImageRect(image, Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          _staticBounds, _imagePaint);
      _paintPulse(canvas, layout);
      _paintDanger(canvas, layout, board);
    }

    // Aim: a soft lane of the held ball's colour.
    if (aim != null) {
      final lane = Rect.fromLTWH(rect.left + aim * cell, rect.top, cell, rect.height).deflate(cell * 0.06);
      final color = Palette.balls[rules.currentColor];
      _fill.shader = Gradient.linear(lane.topCenter, lane.bottomCenter, [
        color.withValues(alpha: 0.22),
        color.withValues(alpha: 0.08),
      ]);
      canvas.drawRRect(RRect.fromRectAndRadius(lane, Radius.circular(cell * 0.45)), _fill);
      _fill.shader = null;
    }

    if (!DevOptions.skip('dock')) _paintDockBalls(canvas, layout, sprites);

    canvas.save();
    // Hide balls below the floor while a new row slides up.
    canvas.clipRect(Rect.fromLTRB(rect.left - cell, rect.top - cell * 2, rect.right + cell, rect.bottom));

    // Landing guide: a faint ghost ball inside a dashed-feeling ring.
    if (aim != null) {
      final row = rules.landingRow(aim);
      if (row != null) {
        final color = Palette.balls[rules.currentColor];
        final at = layout.center(aim.toDouble(), row.toDouble());
        final pulse = 0.7 + 0.3 * math.sin(time * 6);
        sprites.draw(canvas, sprites.ball(rules.currentColor), at, alpha: 0.32);
        _stroke
          ..strokeWidth = cell * 0.05
          ..color = color.withValues(alpha: 0.85 * pulse);
        canvas.drawCircle(at, sprites.radius * 1.02, _stroke);
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
    if (!DevOptions.skip('orbs')) {
      for (final e in centers.entries) {
        paintOrbShadow(canvas, sprites, e.value, e.key);
      }
      for (final e in centers.entries) {
        paintOrb(canvas, sprites, e.value, e.key);
      }
    }
    canvas.restore();

    // Held ball, hovering over the aimed column with a gentle bob.
    if (aim != null) {
      final held = VisualOrb(Cell.orb(rules.currentColor), aim.toDouble(), layout.rows - 0.1);
      final bob = math.sin(time * 5) * cell * 0.04;
      paintOrb(canvas, sprites, layout.center(held.col, held.row).translate(0, bob), held);
    }

    if (!DevOptions.skip('fx')) game.effects.render(canvas);
    canvas.restore();
  }

  /// The board's border lights up in the colour of a pop, stronger in chains.
  void _paintPulse(Canvas canvas, BoardLayout layout) {
    if (game.boardLight <= 0) return;
    final card = _cardRRect(layout);
    _stroke
      ..strokeWidth = layout.cell * (0.08 + 0.10 * game.boardLight)
      ..color = game.boardLightColor.withValues(alpha: 0.85 * game.boardLight);
    canvas.drawRRect(card.deflate(layout.cell * 0.04), _stroke);
  }

  /// Red tint sliding down from the top of nearly full columns.
  void _paintDanger(Canvas canvas, BoardLayout layout, Board board) {
    final rect = layout.rect;
    final cell = layout.cell;
    for (var c = 0; c < layout.columns; c++) {
      if (board.height(c) < layout.rows - 2) continue;
      final pulse = 0.7 + 0.3 * math.sin(game.time * 6);
      final lane = Rect.fromLTWH(rect.left + c * cell, rect.top, cell, cell * 2.2).deflate(cell * 0.06);
      _fill.shader = Gradient.linear(lane.topCenter, lane.bottomCenter, [
        Palette.danger.withValues(alpha: 0.45 * pulse),
        Palette.danger.withValues(alpha: 0),
      ]);
      canvas.drawRRect(RRect.fromRectAndRadius(lane, Radius.circular(cell * 0.45)), _fill);
    }
    _fill.shader = null;
  }

  /// The next row bobbing gently in its sockets; brighter when it is close.
  void _paintDockBalls(Canvas canvas, BoardLayout layout, OrbSprites sprites) {
    final rules = game.rules;
    final rect = layout.rect;
    final cell = layout.cell;
    final y = layout.trayCenterY;
    final urgent = rules.pressure <= 2;
    final pulse = rules.pressure <= 1 ? 0.5 + 0.5 * math.sin(game.time * 8) : 0.0;
    final row = rules.nextRow;
    for (var c = 0; c < row.length; c++) {
      final at = Offset(rect.left + (c + 0.5) * cell, y);
      if (urgent) {
        _stroke
          ..strokeWidth = cell * 0.05
          ..color = Palette.danger.withValues(alpha: 0.55 + 0.45 * pulse);
        canvas.drawCircle(at, cell * 0.34, _stroke);
      }
      final bob = math.sin(game.time * 1.8 + c * 0.9) * cell * 0.025;
      final orb = VisualOrb(row[c], c.toDouble(), 0)
        ..scale = 0.64
        ..alpha = urgent ? 1.0 : 0.9;
      paintOrb(canvas, sprites, at.translate(0, bob), orb);
    }
  }

  RRect _cardRRect(BoardLayout layout) =>
      RRect.fromRectAndRadius(layout.rect.inflate(layout.cell * 0.2), Radius.circular(layout.cell * 0.55));

  void _ensureStatic(BoardLayout layout) {
    if (_static != null && _staticFor == layout.rect) return;
    final cell = layout.cell;
    final card = _cardRRect(layout);
    final dockRect = Rect.fromCenter(
      center: Offset(layout.rect.center.dx, layout.trayCenterY),
      width: layout.rect.width + cell * 0.2,
      height: cell * 0.86,
    );
    // Room for the shadows around the card and dock.
    final bounds = Rect.fromLTRB(card.left, card.top, card.right, dockRect.bottom).inflate(cell * 0.8);
    final ratio = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder)
      ..scale(ratio)
      ..translate(-bounds.left, -bounds.top);
    _paintStatic(canvas, layout, card, dockRect);
    final picture = recorder.endRecording();
    _static?.dispose();
    _static = picture.toImageSync((bounds.width * ratio).ceil(), (bounds.height * ratio).ceil());
    picture.dispose();
    _staticFor = layout.rect;
    _staticBounds = bounds;
  }

  void _paintStatic(Canvas canvas, BoardLayout layout, RRect card, Rect dockRect) {
    final rect = layout.rect;
    final cell = layout.cell;
    final paint = Paint();

    // Soft coloured shadow lifts the card off the sky.
    paint
      ..color = Palette.cardShadow
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.35);
    canvas.drawRRect(card.shift(Offset(0, cell * 0.22)), paint);
    paint.maskFilter = null;

    // The card: white, with a gentle cool tint at the bottom edge. (Reset the
    // colour first: a paint's alpha also fades its shader.)
    paint
      ..color = const Color(0xFFFFFFFF)
      ..shader = Gradient.linear(card.outerRect.topCenter, card.outerRect.bottomCenter,
        const [Palette.card, Color(0xFFF4F1FF)]);
    canvas.drawRRect(card, paint);
    paint.shader = null;

    // The well the balls sit in.
    final well = RRect.fromRectAndRadius(rect.inflate(cell * 0.07), Radius.circular(cell * 0.45));
    paint.color = Palette.well;
    canvas.drawRRect(well, paint);
    canvas.save();
    canvas.clipRRect(well);
    // Alternate lane stripes, rounded at both ends.
    paint.color = Palette.laneAlt;
    for (var c = 1; c < layout.columns; c += 2) {
      final lane = Rect.fromLTWH(rect.left + c * cell, rect.top, cell, rect.height).deflate(cell * 0.06);
      canvas.drawRRect(RRect.fromRectAndRadius(lane, Radius.circular(cell * 0.45)), paint);
    }
    // A soft inner shadow at the top gives the well a little depth.
    final lip = Rect.fromLTWH(well.left, well.top, well.width, cell * 0.6);
    paint
      ..color = const Color(0xFFFFFFFF)
      ..shader = Gradient.linear(lip.topCenter, lip.bottomCenter, const [Color(0x223A2D9E), Color(0x003A2D9E)]);
    canvas.drawRect(lip, paint);
    paint.shader = null;
    canvas.restore();

    // The dock for the next row.
    final dock = RRect.fromRectAndRadius(dockRect, Radius.circular(dockRect.height / 2));
    paint
      ..color = Palette.cardShadow
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.2);
    canvas.drawRRect(dock.shift(Offset(0, cell * 0.12)), paint);
    paint
      ..maskFilter = null
      ..color = Palette.card;
    canvas.drawRRect(dock, paint);
    paint.color = Palette.socket;
    for (var c = 0; c < layout.columns; c++) {
      canvas.drawCircle(Offset(rect.left + (c + 0.5) * cell, layout.trayCenterY), cell * 0.34, paint);
    }
  }
}
