import 'dart:math' as math;

import 'package:flutter/animation.dart' show Curves;
import 'package:pop_core/pop_core.dart';

import 'phase_queue.dart';
import 'timings.dart';
import 'visual_orb.dart';

/// The on-screen copy of the board. It changes only by playing the events
/// that the rules produce, so once every phase has finished it matches the
/// rules board exactly (checked in test/board_scene_test.dart).
class BoardScene {
  BoardScene(this.columns, this.rows)
      : _grid = List<VisualOrb?>.filled(columns * rows, null);

  final int columns;
  final int rows;
  final List<VisualOrb?> _grid;

  /// Called when points should be added to the displayed score.
  void Function(int points)? onPoints;

  /// Called for short announcements such as "Chain ×3".
  void Function(String text)? onBanner;

  /// Called when the game-over moment has been shown.
  void Function()? onGameOver;

  /// Visual-effect hooks (particles, light). They never change the scene.
  /// [onStepPopped] fires as a chain step's groups burst.
  void Function(ChainStep step)? onStepPopped;
  void Function(CellPos pos, Cell cell)? onCracked;
  void Function(int column, int row)? onLanded;
  void Function()? onRose;
  void Function(int level)? onLevelUp;

  int? shakeColumn;
  double shakeTime = 0;

  Iterable<VisualOrb> get orbs => _grid.whereType<VisualOrb>();

  VisualOrb? _at(int col, int row) => _grid[row * columns + col];
  void _put(int col, int row, VisualOrb? orb) => _grid[row * columns + col] = orb;

  /// Cosmetic timers that do not block the event queue.
  void update(double dt) {
    for (final orb in orbs) {
      if (orb.squash > 0) orb.squash = (orb.squash - dt).clamp(0, Timings.squash);
      if (orb.flash > 0) orb.flash = (orb.flash - dt).clamp(0, Timings.revealFlash);
    }
    if (shakeTime > 0) shakeTime = (shakeTime - dt).clamp(0, Timings.shake);
  }

  /// Feedback for an illegal drop (full column).
  void shake(int column) {
    shakeColumn = column;
    shakeTime = Timings.shake;
  }

  /// Shows [board] immediately, without animation (round start, or a board
  /// that does not start empty).
  void load(Board board) {
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < columns; col++) {
        final cell = board.at(col, row);
        _put(col, row, cell == null ? null : VisualOrb(cell, col.toDouble(), row.toDouble()));
      }
    }
  }

  /// The scene as a rules [Board], for checking that the two agree.
  Board toBoard() {
    final board = Board(columns, rows);
    for (var i = 0; i < _grid.length; i++) {
      board.set(i % columns, i ~/ columns, _grid[i]?.cell);
    }
    return board;
  }

  List<Phase> phasesFor(GameEvent event) => switch (event) {
        OrbDropped() => [_drop(event)],
        ChainStep() => _chain(event),
        RowRose() => [_rise(event)],
        BoardCleared(:final bonus) => [
            Phase(0, onStart: () {
              onBanner?.call('Board clear! +$bonus');
              onPoints?.call(bonus);
            }),
          ],
        LevelUp(:final level) => [
            Phase(0, onStart: () {
              onBanner?.call('Level $level!');
              onLevelUp?.call(level);
            }),
          ],
        GameOver() => [
            Phase(Timings.gameOverDelay, onEnd: () => onGameOver?.call()),
          ],
      };

  Phase _drop(OrbDropped e) {
    final startRow = rows + 0.2;
    late VisualOrb orb;
    return Phase(
      Timings.drop(startRow - e.row),
      onStart: () {
        orb = VisualOrb(Cell.orb(e.color), e.column.toDouble(), startRow);
        _put(e.column, e.row, orb);
      },
      onUpdate: (t) => orb.row = _lerp(startRow, e.row.toDouble(), Curves.easeIn.transform(t)),
      onEnd: () {
        orb.squash = Timings.squash;
        onLanded?.call(e.column, e.row);
      },
    );
  }

  List<Phase> _chain(ChainStep e) {
    final f = Timings.chainFactor(e.step);
    final popped = [for (final g in e.groups) ...g.cells];
    var popOrbs = <VisualOrb>[];
    var crackOrbs = <VisualOrb>[];
    // How far each popping orb leans toward its group's centre (cells).
    final pull = <VisualOrb, (double, double)>{};

    return [
      Phase(
        Timings.highlight * f,
        onStart: () {
          popOrbs = [for (final p in popped) ?_at(p.col, p.row)];
          pull.clear();
          for (final g in e.groups) {
            final cx = g.cells.map((p) => p.col).reduce((a, b) => a + b) / g.cells.length;
            final cy = g.cells.map((p) => p.row).reduce((a, b) => a + b) / g.cells.length;
            for (final p in g.cells) {
              final orb = _at(p.col, p.row);
              if (orb != null) pull[orb] = ((cx - p.col) * 0.12, (cy - p.row) * 0.12);
            }
          }
          crackOrbs = [];
          final poppedSet = popped.toSet();
          for (final p in e.cracked.keys) {
            final orb = _at(p.col, p.row);
            if (orb == null) continue;
            crackOrbs.add(orb);
            // Cracks start on the side facing the orb that broke it.
            for (final (dc, dr, angle) in const [
              (-1, 0, math.pi),
              (1, 0, 0.0),
              (0, -1, math.pi / 2),
              (0, 1, -math.pi / 2),
            ]) {
              if (poppedSet.contains((col: p.col + dc, row: p.row + dr))) {
                orb.crackAngle = angle;
                break;
              }
            }
          }
        },
        onUpdate: (t) {
          // The group squeezes together, glowing, just before it bursts.
          final k = Curves.easeOut.transform(t);
          for (final o in popOrbs) {
            o.scale = 1 + 0.12 * k;
            o.glow = t;
            final (px, py) = pull[o] ?? (0.0, 0.0);
            o
              ..dx = px * k
              ..dy = py * k;
          }
          for (final o in crackOrbs) {
            if (o.cell.kind == CellKind.shell) o.crack = t;
          }
        },
      ),
      Phase(
        Timings.pop * f,
        onStart: () {
          onStepPopped?.call(e);
          e.cracked.forEach((p, cell) => onCracked?.call(p, cell));
        },
        onUpdate: (t) {
          // Balloon pop: puff up a little and vanish quickly.
          for (final o in popOrbs) {
            o.scale = 1.12 + 0.3 * Curves.easeOut.transform(t);
            o.alpha = (1 - t * 2.2).clamp(0.0, 1.0);
            o.glow = (1 - t * 2.2).clamp(0.0, 1.0);
          }
          for (final o in crackOrbs) {
            if (o.cell.kind == CellKind.shell) {
              o.reveal = t;
            } else {
              o.alpha = 1 - t;
              o.scale = 1 - 0.4 * t;
            }
          }
        },
        onEnd: () {
          for (final p in popped) {
            _put(p.col, p.row, null);
          }
          e.cracked.forEach((p, cell) {
            final orb = _at(p.col, p.row);
            if (cell.kind == CellKind.shell && orb != null) {
              orb
                ..cell = Cell.orb(cell.color)
                ..reveal = 0
                ..crack = 0
                ..flash = Timings.revealFlash;
            } else {
              _put(p.col, p.row, null);
            }
          });
          onPoints?.call(e.points);
        },
      ),
      if (e.falls.isNotEmpty) _fall(e.falls, Timings.gravity * f),
    ];
  }

  Phase _fall(List<Fall> falls, double duration) {
    final moving = <(VisualOrb, Fall)>[];
    return Phase(
      duration,
      onStart: () {
        // Falls are listed bottom-up per column, so each target is free.
        for (final f in falls) {
          final orb = _at(f.column, f.fromRow);
          if (orb == null) continue;
          _put(f.column, f.fromRow, null);
          _put(f.column, f.toRow, orb);
          moving.add((orb, f));
        }
      },
      onUpdate: (t) {
        final k = Curves.easeIn.transform(t);
        for (final (orb, f) in moving) {
          orb.row = _lerp(f.fromRow.toDouble(), f.toRow.toDouble(), k);
        }
      },
      onEnd: () {
        for (final (orb, _) in moving) {
          orb.squash = Timings.squash;
        }
      },
    );
  }

  Phase _rise(RowRose e) {
    final moving = <(VisualOrb, int)>[];
    return Phase(
      Timings.rowRise,
      onStart: () {
        onRose?.call();
        for (var col = 0; col < columns; col++) {
          for (var row = rows - 1; row > 0; row--) {
            _put(col, row, _at(col, row - 1));
          }
          _put(col, 0, VisualOrb(e.row[col], col.toDouble(), -1));
        }
        for (var i = 0; i < _grid.length; i++) {
          final orb = _grid[i];
          if (orb != null) moving.add((orb, i ~/ columns));
        }
      },
      onUpdate: (t) {
        final k = Curves.easeOut.transform(t);
        for (final (orb, row) in moving) {
          orb.row = row - 1 + k;
        }
      },
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}
