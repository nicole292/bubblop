import 'dart:math' as math;

import 'package:flame/components.dart' show Vector2;
import 'package:flame/game.dart' show FlameGame;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:pop_core/pop_core.dart';

import '../render/orb_sprites.dart';
import '../render/particles.dart';
import 'board_component.dart';
import 'board_layout.dart';
import 'board_scene.dart';
import 'hud_state.dart';
import 'palette.dart';
import 'phase_queue.dart';
import 'session_stats.dart';
import 'timings.dart';

/// Connects the rules ([Game]) to the screen. Input goes straight to the
/// rules; the resulting events are queued as animation phases.
class PopGame extends FlameGame {
  PopGame({this._config = const RulesConfig()}) {
    _startRound();
  }

  RulesConfig _config;
  RulesConfig get config => _config;

  late Game rules;
  late BoardScene scene;
  final phases = PhaseQueue();
  final stats = SessionStats();
  final hud = ValueNotifier(const HudState());
  final particles = ParticleSystem();

  BoardLayout? layout;
  OrbSprites? sprites;

  /// Column the player is aiming at, or null when not touching.
  int? aimColumn;

  /// Board light that flares on pops and grows with chain length (0–1).
  double boardLight = 0;
  Color boardLightColor = Palette.orbs[3];

  /// Transparent: the screen's background gradient shows through.
  @override
  Color backgroundColor() => const Color(0x00000000);

  @override
  Future<void> onLoad() async {
    add(BoardComponent(this));
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _relayout();
  }

  @override
  void onRemove() {
    sprites?.dispose();
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    phases.update(dt);
    final scaled = dt * phases.speed;
    scene.update(scaled);
    particles.update(scaled);
    boardLight = math.max(0, boardLight - scaled * 2.2);
  }

  /// Starts a fresh round; a new [config] switches experiment mode.
  void restart({RulesConfig? config}) {
    if (config != null) {
      _config = config;
      _relayout();
    }
    phases.clear();
    _startRound();
  }

  void aimAt(double x) {
    if (rules.isOver || layout == null) return;
    aimColumn = layout!.columnAt(x);
  }

  void cancelAim() => aimColumn = null;

  void releaseAim() {
    final column = aimColumn;
    aimColumn = null;
    if (column != null) dropAt(column);
  }

  void dropAt(int column) {
    if (!phases.isIdle) phases.speed = Timings.fastForward;
    final result = rules.drop(column);
    if (!result.accepted) {
      if (!rules.isOver) scene.shake(column);
      return;
    }
    stats.recordMove(result);
    if (rules.isOver) {
      final summary = stats.finishRound(score: rules.score, moves: rules.moves);
      debugPrint('Round over [${summary.mode}] score ${summary.score}, '
          'moves ${summary.moves}, best chain ${summary.longestChain}');
    }
    for (final event in result.events) {
      phases.addAll(scene.phasesFor(event));
    }
    _publishRulesState();
  }

  void _relayout() {
    if (!hasLayout) return;
    final next = BoardLayout(Size(size.x, size.y),
        columns: _config.columns, rows: _config.rows);
    final radius = next.cell * 0.44;
    if (sprites == null || (sprites!.radius - radius).abs() > 0.5) {
      sprites?.dispose();
      final ratio = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
      sprites = OrbSprites.bake(radius, ratio);
    }
    layout = next;
    particles.cell = next.cell;
  }

  void _startRound() {
    rules = Game(seed: math.Random().nextInt(1 << 31), config: _config);
    scene = BoardScene(_config.columns, _config.rows)
      ..onPoints = (points) {
        hud.value = hud.value.copyWith(score: hud.value.score + points);
      }
      ..onBanner = (text) {
        hud.value = hud.value.copyWith(banner: text, bannerId: hud.value.bannerId + 1);
      }
      ..onGameOver = () {
        hud.value = hud.value.copyWith(isOver: true, best: stats.bestScore);
      }
      ..onGroupPopped = _popEffects
      ..onCracked = _crackEffects;
    aimColumn = null;
    boardLight = 0;
    stats.startRound(_config);
    hud.value = HudState(best: stats.bestScore, bannerId: hud.value.bannerId);
    _publishRulesState();
  }

  /// Sparks per orb, one ring per group; the board light grows with the
  /// chain so long chains feel bigger without extra clutter.
  void _popEffects(PoppedGroup group, int step) {
    final layout = this.layout;
    if (layout == null) return;
    final color = Palette.orbs[group.color];
    var sum = Offset.zero;
    for (final p in group.cells) {
      final at = layout.center(p.col.toDouble(), p.row.toDouble());
      sum += at;
      particles.burst(at, color, count: step > 1 ? 7 : 5);
    }
    final centroid = sum / group.cells.length.toDouble();
    particles.ring(centroid, color, to: 1.1 + 0.25 * math.min(step, 4));
    boardLight = math.min(1.0, math.max(boardLight, 0.25 + 0.25 * (step - 1)));
    boardLightColor = color;
  }

  void _crackEffects(CellPos pos, Cell cell) {
    final layout = this.layout;
    if (layout == null || cell.kind != CellKind.shell) return;
    particles.shards(layout.center(pos.col.toDouble(), pos.row.toDouble()));
  }

  /// Values the HUD can show immediately (they are not animated).
  void _publishRulesState() {
    hud.value = hud.value.copyWith(
      level: rules.level,
      queue: rules.queue,
      pressure: rules.pressure,
      pressureMax: _config.pressureInterval(rules.level),
      best: stats.bestScore,
    );
  }
}
