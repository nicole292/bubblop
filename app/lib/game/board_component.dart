import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:pop_core/pop_core.dart';

import '../render/orb_sprites.dart';
import 'board_layout.dart';
import 'dev_options.dart';
import 'orb_painter.dart';
import 'palette.dart';
import 'pop_game.dart';
import 'timings.dart';
import 'visual_orb.dart';

/// Draws the whole canvas: background, board, orbs, next-row dock and
/// effects. Reads state; never changes it.
class BoardComponent extends Component {
  BoardComponent(this.game);

  final PopGame game;

  // Reused paints (no per-frame allocation for the common cases).
  // _fill/_stroke are used with shaders, so their colour must stay opaque
  // (a paint's alpha also fades its shader). Solid strokes use _solidStroke.
  final _fill = Paint();
  final _stroke = Paint()..style = PaintingStyle.stroke;
  final _solidStroke = Paint()..style = PaintingStyle.stroke;
  final _blurred = Paint();
  final _glint = Paint()
    ..blendMode = BlendMode.plus
    ..filterQuality = FilterQuality.low;

  static const _glintPeriod = 7.0;

  @override
  void render(Canvas canvas) {
    final layout = game.layout;
    final sprites = game.sprites;
    if (!DevOptions.skip('bg')) game.background.render(canvas, sprites, layout?.cell ?? 40);
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
      _paintStageLight(canvas, layout);
      _paintBezel(canvas, layout);
      _paintWell(canvas, layout, board);
    }
    if (!DevOptions.skip('dock')) _paintDock(canvas, layout, sprites);

    // Aim: a beam of the held orb's colour down the column.
    if (aim != null) {
      final lane = Rect.fromLTWH(rect.left + aim * cell, rect.top, cell, rect.height);
      final color = Palette.orbs[rules.currentColor];
      _fill.shader = Gradient.linear(lane.topCenter, lane.bottomCenter, [
        color.withValues(alpha: 0.26),
        color.withValues(alpha: 0.10),
        color.withValues(alpha: 0.02),
      ], const [0.0, 0.6, 1.0]);
      canvas.drawRRect(RRect.fromRectAndRadius(lane.deflate(cell * 0.04), Radius.circular(cell * 0.3)), _fill);
      _fill.shader = null;
    }

    canvas.save();
    // Hide orbs below the floor while a new row slides up.
    canvas.clipRect(Rect.fromLTRB(rect.left - cell, rect.top - cell * 2, rect.right + cell, rect.bottom));

    // Landing guide.
    if (aim != null) {
      final row = rules.landingRow(aim);
      if (row != null) {
        final color = Palette.orbs[rules.currentColor];
        final at = layout.center(aim.toDouble(), row.toDouble());
        final pulse = 0.75 + 0.25 * math.sin(time * 6);
        // A faint ghost of the orb where it will land.
        sprites.draw(canvas, sprites.orb(rules.currentColor), at, alpha: 0.28);
        _solidStroke
          ..strokeWidth = cell * 0.04
          ..color = color.withValues(alpha: 0.8 * pulse);
        canvas.drawCircle(at, sprites.radius * 0.96, _solidStroke);
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
    if (!DevOptions.skip('floor')) {
      for (final e in centers.entries) {
        paintFloorLight(canvas, sprites, e.value, e.key, 0.10);
      }
    }
    if (!DevOptions.skip('orbs')) {
      for (final e in centers.entries) {
        if (e.key.cell.kind != CellKind.stone) paintOrbShadow(canvas, sprites, e.value, e.key);
      }
      for (final e in centers.entries) {
        paintOrb(canvas, sprites, e.value, e.key);
      }
      _paintGlints(canvas, layout, sprites, centers);
    }
    canvas.restore();

    // Held orb, hovering over the aimed column.
    if (aim != null) {
      final held = VisualOrb(Cell.orb(rules.currentColor), aim.toDouble(), layout.rows - 0.15)
        ..glow = 0.25;
      paintOrb(canvas, sprites, layout.center(held.col, held.row), held);
    }

    if (!DevOptions.skip('fx')) game.effects.render(canvas);
    canvas.restore();
  }

  /// A pool of light behind and under the board; flares with pops.
  void _paintStageLight(Canvas canvas, BoardLayout layout) {
    final rect = layout.rect;
    final center = Offset(rect.center.dx, rect.bottom - rect.height * 0.15);
    final radius = rect.height * 0.85;
    final flare = game.boardLight;
    final color = Color.lerp(Palette.backgroundGlow, game.boardLightColor, flare * 0.6)!;
    _fill.shader = Gradient.radial(center, radius, [
      color.withValues(alpha: 0.55 + 0.25 * flare),
      color.withValues(alpha: 0),
    ]);
    canvas.drawCircle(center, radius, _fill);
    _fill.shader = null;
  }

  void _paintBezel(Canvas canvas, BoardLayout layout) {
    final rect = layout.rect;
    final cell = layout.cell;
    final outer = RRect.fromRectAndRadius(rect.inflate(cell * 0.24), Radius.circular(cell * 0.46));
    final o = outer.outerRect;

    final skipBlur = DevOptions.skip('blur');
    // Grounding shadow.
    if (!skipBlur) {
      _blurred
        ..color = const Color(0xB3000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.4);
      canvas.drawRRect(outer.shift(Offset(0, cell * 0.18)), _blurred);
      _blurred.maskFilter = null;
    }

    // Flare: the frame catches the colour of a pop, stronger in chains.
    if (game.boardLight > 0 && !skipBlur) {
      _blurred
        ..color = game.boardLightColor.withValues(alpha: 0.6 * game.boardLight)
        ..blendMode = BlendMode.plus
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.5);
      canvas.drawRRect(outer.inflate(cell * 0.06), _blurred);
      _blurred
        ..maskFilter = null
        ..blendMode = BlendMode.srcOver;
    }

    // Dark metal body.
    _fill.shader = Gradient.linear(o.topCenter, o.bottomCenter,
        const [Palette.bezelTop, Palette.bezelMid, Palette.bezelBottom], const [0.0, 0.35, 1.0]);
    canvas.drawRRect(outer, _fill);
    _fill.shader = null;

    // Lit top edge, fading down the sides.
    _stroke
      ..strokeWidth = math.max(1.2, cell * 0.03)
      ..shader = Gradient.linear(o.topCenter, o.bottomCenter,
          const [Palette.bezelHighlight, Color(0x1AB9C6FF), Color(0x00B9C6FF)], const [0.0, 0.4, 1.0]);
    canvas.drawRRect(outer.deflate(cell * 0.015), _stroke);
    _stroke.shader = null;
  }

  void _paintWell(Canvas canvas, BoardLayout layout, Board board) {
    final rect = layout.rect;
    final cell = layout.cell;
    final well = RRect.fromRectAndRadius(rect.inflate(cell * 0.09), Radius.circular(cell * 0.34));
    final w = well.outerRect;

    _fill.shader = Gradient.linear(w.topCenter, w.bottomCenter, const [Palette.wellTop, Palette.wellBottom]);
    canvas.drawRRect(well, _fill);

    canvas.save();
    canvas.clipRRect(well);

    // Light pooling on the floor of the well.
    final floor = Offset(w.center.dx, w.bottom);
    final floorColor = Color.lerp(Palette.floorLight, game.boardLightColor, game.boardLight)!;
    _fill.shader = Gradient.radial(floor, w.width * 0.85, [
      floorColor.withValues(alpha: 0.30 + 0.25 * game.boardLight),
      floorColor.withValues(alpha: 0),
    ]);
    canvas.drawRect(w, _fill);

    // Column channels: faintly lit and rounded.
    for (var c = 0; c < layout.columns; c++) {
      final lane = Rect.fromLTWH(rect.left + c * cell, rect.top, cell, rect.height).deflate(cell * 0.05);
      _fill.shader = Gradient.linear(lane.topCenter, lane.bottomCenter,
          const [Color(0x00FFFFFF), Palette.channel, Color(0x14FFFFFF)], const [0.0, 0.5, 1.0]);
      canvas.drawRRect(RRect.fromRectAndRadius(lane, Radius.circular(cell * 0.42)), _fill);
    }
    _fill.shader = null;

    // Inner shadow along the top: the well is recessed into the frame.
    final lip = Rect.fromLTWH(w.left, w.top, w.width, cell * 1.1);
    _fill.shader = Gradient.linear(lip.topCenter, lip.bottomCenter, const [Color(0x99000000), Color(0x00000000)]);
    canvas.drawRect(lip, _fill);
    _fill.shader = null;

    // A faint diagonal reflection: the well sits behind a sheet of glass.
    final sheen = Path()
      ..moveTo(w.left, w.top + w.height * 0.10)
      ..lineTo(w.left + w.width * 0.55, w.top)
      ..lineTo(w.left + w.width * 0.80, w.top)
      ..lineTo(w.left, w.top + w.height * 0.42)
      ..close();
    _fill.shader = Gradient.linear(w.topLeft, Offset(w.left + w.width * 0.5, w.top + w.height * 0.4),
        const [Color(0x09FFFFFF), Color(0x00FFFFFF)]);
    canvas.drawPath(sheen, _fill);
    _fill.shader = null;

    // Danger: red light rising from the top of nearly full columns.
    for (var c = 0; c < layout.columns; c++) {
      if (board.height(c) < layout.rows - 2) continue;
      final pulse = 0.7 + 0.3 * math.sin(game.time * 6);
      final glow = Rect.fromLTWH(rect.left + c * cell, w.top, cell, cell * 2);
      _fill.shader = Gradient.linear(glow.topCenter, glow.bottomCenter, [
        Palette.danger.withValues(alpha: 0.5 * pulse),
        Palette.danger.withValues(alpha: 0),
      ]);
      canvas.drawRect(glow, _fill);
    }
    _fill.shader = null;
    canvas.restore();

    // Inner edge: light catches the lower lip of the well.
    _stroke
      ..strokeWidth = math.max(1.0, cell * 0.02)
      ..shader = Gradient.linear(w.topCenter, w.bottomCenter, const [Color(0x00B9C6FF), Color(0x40B9C6FF)]);
    canvas.drawRRect(well, _stroke);
    _stroke.shader = null;
  }

  /// The next row waits in recessed sockets under the board, brightening as
  /// the countdown runs out.
  void _paintDock(Canvas canvas, BoardLayout layout, OrbSprites sprites) {
    final rules = game.rules;
    final rect = layout.rect;
    final cell = layout.cell;
    final y = layout.trayCenterY + cell * 0.04;
    final dock = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(rect.center.dx, y), width: rect.width + cell * 0.3, height: cell * 0.82),
      Radius.circular(cell * 0.41),
    );
    final d = dock.outerRect;
    _fill.shader = Gradient.linear(d.topCenter, d.bottomCenter, const [Palette.bezelBottom, Palette.bezelMid]);
    canvas.drawRRect(dock, _fill);
    _fill.shader = null;
    _stroke
      ..strokeWidth = 1
      ..shader = Gradient.linear(d.topCenter, d.bottomCenter, const [Color(0x10B9C6FF), Color(0x4DB9C6FF)]);
    canvas.drawRRect(dock, _stroke);
    _stroke.shader = null;

    final urgent = rules.pressure <= 2;
    final pulse = rules.pressure <= 1 ? 0.5 + 0.5 * math.sin(game.time * 8) : 0.0;
    final row = rules.nextRow;
    for (var c = 0; c < row.length; c++) {
      final at = Offset(rect.left + (c + 0.5) * cell, y);
      final socketR = cell * 0.33;
      _fill.shader = Gradient.radial(at.translate(0, -socketR * 0.3), socketR * 1.3,
          const [Palette.socketInner, Color(0xFF10163A)]);
      canvas.drawCircle(at, socketR, _fill);
      _fill.shader = null;
      _solidStroke
        ..strokeWidth = 1
        ..color = urgent ? Color.lerp(Palette.socketRim, Palette.danger, 0.5 + 0.5 * pulse)! : Palette.socketRim;
      canvas.drawCircle(at, socketR, _solidStroke);

      final bob = math.sin(game.time * 1.6 + c * 0.9) * cell * 0.02;
      final orb = VisualOrb(row[c], c.toDouble(), 0)
        ..scale = 0.66
        ..alpha = urgent ? 1.0 : 0.82;
      paintOrb(canvas, sprites, at.translate(0, bob), orb);
    }
  }

  /// Every few seconds a band of light sweeps diagonally across the board
  /// and glints off each orb it passes: life without constant motion.
  void _paintGlints(Canvas canvas, BoardLayout layout, OrbSprites sprites, Map<VisualOrb, Offset> centers) {
    final rect = layout.rect;
    final phase = (game.time % _glintPeriod) / _glintPeriod;
    if (phase > 0.4) return;
    final span = rect.width + rect.height;
    final band = rect.left + rect.top + (phase / 0.4) * span * 1.2 - span * 0.1;
    final unit = layout.cell / (sprites.radius * OrbSprites.pad * 2);
    for (final e in centers.entries) {
      final orb = e.key;
      if (orb.alpha < 1 || orb.cell.kind == CellKind.stone) continue;
      final c = e.value;
      final dist = ((c.dx + c.dy) - band).abs() / layout.cell;
      if (dist > 1.2) continue;
      final a = (1 - dist / 1.2) * 0.75;
      final at = c + Offset(-sprites.radius * 0.36, -sprites.radius * 0.48);
      sprites.draw(canvas, sprites.bloom, at, sx: 0.55 * unit, sy: 0.55 * unit, alpha: a, paint: _glint);
    }
  }
}
