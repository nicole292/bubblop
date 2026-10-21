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

/// Draws the whole canvas: background, board card (board, rise meter and
/// next-row tray), balls and effects. Reads state; never changes it.
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

    if (!DevOptions.skip('dock')) {
      _paintMeter(canvas, layout);
      _paintDockBalls(canvas, layout, sprites);
    }

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
      var c = layout.center(orb.col + orb.dx, orb.row + orb.dy);
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
      ..strokeWidth = layout.cell * (0.04 + 0.06 * game.boardLight)
      ..color = game.boardLightColor.withValues(alpha: 0.6 * game.boardLight);
    canvas.drawRRect(card.deflate(layout.cell * 0.03), _stroke);
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

  /// The rise meter: one segment per drop until the next row rises. Lit
  /// segments are drops left; they turn red for the last two.
  void _paintMeter(Canvas canvas, BoardLayout layout) {
    final rules = game.rules;
    final rect = layout.rect;
    final cell = layout.cell;
    final total = math.max(1, game.config.pressureInterval(rules.level));
    final left = rules.pressure.clamp(0, total);
    final urgent = left <= 2;
    final pulse = left <= 1 ? 0.5 + 0.5 * math.sin(game.time * 8) : 1.0;
    final lit = urgent ? Palette.danger.withValues(alpha: 0.6 + 0.4 * pulse) : Palette.accent;

    final gap = cell * 0.08;
    final x0 = rect.left + cell * 0.12;
    final width = rect.width - cell * 0.24;
    final w = (width - gap * (total - 1)) / total;
    final h = cell * 0.1;
    for (var i = 0; i < total; i++) {
      final seg = Rect.fromLTWH(x0 + i * (w + gap), layout.meterY - h / 2, w, h);
      _fill.color = i < left ? lit : Palette.pipEmpty;
      canvas.drawRRect(RRect.fromRectAndRadius(seg, Radius.circular(h / 2)), _fill);
    }
  }

  /// The next row, already in its shells, bobbing gently in the tray.
  void _paintDockBalls(Canvas canvas, BoardLayout layout, OrbSprites sprites) {
    final rules = game.rules;
    final rect = layout.rect;
    final cell = layout.cell;
    final y = layout.trayCenterY;
    final row = rules.nextRow;
    final lift = rules.pressure <= 1 ? (0.5 + 0.5 * math.sin(game.time * 8)) * cell * 0.03 : 0.0;
    for (var c = 0; c < row.length; c++) {
      final at = Offset(rect.left + (c + 0.5) * cell, y);
      final bob = math.sin(game.time * 1.8 + c * 0.9) * cell * 0.02 - lift;
      final orb = VisualOrb(row[c], c.toDouble(), 0)..scale = 0.62;
      paintOrb(canvas, sprites, at.translate(0, bob), orb);
    }
  }

  /// The board card: the board, then the rise meter and the next-row tray.
  RRect _cardRRect(BoardLayout layout) {
    final rect = layout.rect;
    final cell = layout.cell;
    return RRect.fromLTRBR(rect.left - cell * 0.2, rect.top - cell * 0.2, rect.right + cell * 0.2,
        layout.cardBottom, Radius.circular(cell * 0.5));
  }

  void _ensureStatic(BoardLayout layout) {
    if (_static != null && _staticFor == layout.rect) return;
    final card = _cardRRect(layout);
    // Room for the shadow around the card.
    final bounds = card.outerRect.inflate(layout.cell * 0.6);
    final ratio = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;

    final recorder = PictureRecorder();
    final canvas = Canvas(recorder)
      ..scale(ratio)
      ..translate(-bounds.left, -bounds.top);
    _paintStatic(canvas, layout, card);
    final picture = recorder.endRecording();
    _static?.dispose();
    _static = picture.toImageSync((bounds.width * ratio).ceil(), (bounds.height * ratio).ceil());
    picture.dispose();
    _staticFor = layout.rect;
    _staticBounds = bounds;
  }

  void _paintStatic(Canvas canvas, BoardLayout layout, RRect card) {
    final rect = layout.rect;
    final cell = layout.cell;
    final paint = Paint();

    // A soft, close shadow: lifted off the sky, not floating.
    paint
      ..color = Palette.panelShadow
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.18);
    canvas.drawRRect(card.shift(Offset(0, cell * 0.08)), paint);
    paint
      ..maskFilter = null
      ..color = Palette.card;
    canvas.drawRRect(card, paint);

    // The well the balls sit in.
    final well = RRect.fromRectAndRadius(rect.inflate(cell * 0.07), Radius.circular(cell * 0.42));
    paint.color = Palette.well;
    canvas.drawRRect(well, paint);
    canvas.save();
    canvas.clipRRect(well);
    // Alternate lanes, so columns are easy to tell apart.
    paint.color = Palette.laneAlt;
    for (var c = 1; c < layout.columns; c += 2) {
      final lane = Rect.fromLTWH(rect.left + c * cell, rect.top, cell, rect.height).deflate(cell * 0.06);
      canvas.drawRRect(RRect.fromRectAndRadius(lane, Radius.circular(cell * 0.42)), paint);
    }
    canvas.restore();
  }
}
