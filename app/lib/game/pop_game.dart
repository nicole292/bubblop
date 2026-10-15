import 'dart:math' as math;
import 'dart:ui' show FragmentProgram;

import 'package:flame/components.dart' show Vector2;
import 'package:flame/game.dart' show FlameGame;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:pop_core/pop_core.dart';

import '../render/background.dart';
import '../render/effects.dart';
import '../render/orb_sprites.dart';
import 'board_component.dart';
import 'board_layout.dart';
import 'board_scene.dart';
import 'dev_options.dart';
import 'frame_bench.dart';
import 'hud_state.dart';
import 'palette.dart';
import 'phase_queue.dart';
import 'session_stats.dart';
import 'timings.dart';

/// Connects the rules ([Game]) to the screen. Input goes straight to the
/// rules; the resulting events are queued as animation phases.
///
/// The Flame canvas covers the whole screen (background, board, effects);
/// the Flutter HUD sits on top and tells the game where the board goes via
/// [setBoardArea].
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
  final effects = Effects();
  final background = NightBackground();

  BoardLayout? layout;
  OrbSprites? sprites;
  FragmentProgram? _orbProgram;
  bool _programLoaded = false;
  Rect? _boardArea;

  /// Column the player is aiming at, or null when not touching.
  int? aimColumn;

  /// Board light that flares on pops and grows with chain length (0–1).
  double boardLight = 0;
  Color boardLightColor = Palette.orbs[3];

  /// Screen shake for big chains: amplitude in pixels, decays quickly.
  double shake = 0;

  /// Seconds since start; drives idle animation (glints, bobbing).
  double time = 0;

  /// Where the previous chain step burst, for the chain beam.
  Offset? _lastStepCenter;

  // POP_BENCH only: auto-play and frame timing (see dev_options.dart).
  FrameBench? _bench;
  double _benchTime = 0;
  double _benchNextDrop = 0;

  @override
  Color backgroundColor() => Palette.backgroundTop;

  @override
  Future<void> onLoad() async {
    _orbProgram = await OrbSprites.loadProgram();
    _programLoaded = true;
    _relayout(force: true);
    add(BoardComponent(this));
    if (DevOptions.isBench) _bench = FrameBench()..start();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    background.resize(Size(size.x, size.y));
    _relayout();
  }

  @override
  void onRemove() {
    sprites?.dispose();
    background.dispose();
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    time += dt;
    background.update(dt);
    phases.update(dt);
    final scaled = dt * phases.speed;
    scene.update(scaled);
    effects.update(scaled);
    boardLight = math.max(0, boardLight - scaled * 1.8);
    shake = math.max(0, shake - scaled * 30);
    if (_bench != null) _benchStep(dt);
  }

  /// Plays fast for the benchmark: stack the current colour on a matching
  /// column top when possible (this produces frequent pops and chains).
  void _benchStep(double dt) {
    final bench = _bench!;
    _benchTime += dt;
    bench.peakEffects = math.max(bench.peakEffects, effects.activeCount);
    if (_benchTime >= DevOptions.benchSeconds) {
      bench.stop();
      debugPrint(bench.report());
      _bench = null;
      return;
    }
    if (_benchTime < _benchNextDrop || layout == null) return;
    _benchNextDrop = _benchTime + 0.2;
    if (rules.isOver) {
      restart();
      return;
    }
    final board = rules.board;
    var choice = -1;
    var lowest = -1;
    for (var c = 0; c < _config.columns; c++) {
      if (!rules.canDrop(c)) continue;
      final h = board.height(c);
      final top = h > 0 ? board.at(c, h - 1) : null;
      if (top != null && top.isOrb && top.color == rules.currentColor) choice = c;
      if (lowest < 0 || h < board.height(lowest)) lowest = c;
    }
    final column = choice >= 0 ? choice : lowest;
    if (column >= 0) dropAt(column);
  }

  /// Called by the screen with the board slot's rectangle in canvas
  /// coordinates.
  void setBoardArea(Rect area) {
    if (area == _boardArea) return;
    _boardArea = area;
    _relayout();
  }

  /// Starts a fresh round; a new [config] switches experiment mode.
  void restart({RulesConfig? config}) {
    if (config != null) {
      _config = config;
      _relayout(force: true);
    }
    phases.clear();
    effects.clear();
    _startRound();
  }

  /// [x] is relative to the board slot.
  void aimAt(double x) {
    final layout = this.layout;
    if (rules.isOver || layout == null) return;
    aimColumn = layout.columnAt(x + (_boardArea?.left ?? 0));
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

  void _relayout({bool force = false}) {
    final area = _boardArea;
    if (area == null || area.isEmpty) return;
    final next = BoardLayout(area.size,
        columns: _config.columns, rows: _config.rows, offset: area.topLeft);
    final radius = next.cell * 0.44;
    if (_programLoaded && (force || sprites == null || (sprites!.radius - radius).abs() > 0.5)) {
      sprites?.dispose();
      final ratio = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
      sprites = OrbSprites.bake(radius, ratio, _orbProgram);
      // New sprites: let the HUD redraw its orb icons with them.
      hud.value = hud.value.copyWith(spritesVersion: hud.value.spritesVersion + 1);
    }
    layout = next;
    effects
      ..cell = next.cell
      ..sprites = sprites;
  }

  void _startRound() {
    rules = DevOptions.demoGame(_config) ?? Game(seed: math.Random().nextInt(1 << 31), config: _config);
    scene = BoardScene(_config.columns, _config.rows)
      ..onPoints = (points) {
        hud.value = hud.value.copyWith(score: hud.value.score + points);
      }
      ..onBanner = (text) {
        hud.value = hud.value.copyWith(banner: text, bannerId: hud.value.bannerId + 1);
      }
      ..onGameOver = () {
        final last = stats.rounds.isEmpty ? null : stats.rounds.last;
        hud.value = hud.value.copyWith(
          isOver: true,
          best: stats.bestScore,
          longestChain: last?.longestChain ?? 0,
          moves: last?.moves ?? rules.moves,
        );
      }
      ..onStepPopped = _stepEffects
      ..onCracked = _crackEffects
      ..onLanded = _landEffects
      ..load(rules.board);
    aimColumn = null;
    boardLight = 0;
    shake = 0;
    _lastStepCenter = null;
    stats.startRound(_config);
    hud.value = HudState(best: stats.bestScore, bannerId: hud.value.bannerId);
    _publishRulesState();
  }

  Offset _at(CellPos p) => layout!.center(p.col.toDouble(), p.row.toDouble());

  /// Effects grow with group size and, more strongly, with chain step, so a
  /// 3-step chain feels clearly bigger than a single 4-match.
  void _stepEffects(ChainStep e) {
    if (layout == null) return;
    if (_bench != null) _bench!.pops++;
    final step = e.step;
    var stepCenter = Offset.zero;
    var total = 0;
    for (final g in e.groups) {
      final n = g.cells.length;
      final intensity = ((1 + 0.22 * (n - 4)) * (1 + 0.45 * (step - 1))).clamp(1.0, 3.4);
      var sum = Offset.zero;
      for (final p in g.cells) {
        final at = _at(p);
        sum += at;
        effects
          ..flash(at, g.color, size: 1.5 + 0.3 * intensity, strength: 0.9)
          ..sparks(at, g.color, count: (3 + 2.5 * intensity).round(), power: intensity)
          ..motes(at, g.color, count: 1);
      }
      final center = sum / n.toDouble();
      stepCenter += sum;
      total += n;
      effects.ring(center, g.color, to: 1.0 + 0.3 * math.sqrt(n) + 0.35 * (step - 1), strength: 0.9);
      if (step > 1) effects.ring(center, -1, from: 0.2, to: 0.8 + 0.25 * step, life: 0.3, strength: 0.6);
      boardLightColor = Palette.orbs[g.color];
    }
    stepCenter = stepCenter / total.toDouble();

    // Chain payoff: light runs from the previous burst to this one, and the
    // step number appears where it happened.
    // Older step labels make way for the new ones.
    effects.fadeLabels();
    if (step > 1 && _lastStepCenter != null) {
      final color = e.groups.first.color;
      effects
        ..beam(_lastStepCenter!, stepCenter, color)
        ..label(stepCenter.translate(0, -layout!.cell * 0.55), '×$step', Palette.orbs[color],
            size: 0.62 + 0.08 * math.min(step, 5), life: 0.9, rise: 0.6);
    }
    effects.label(stepCenter.translate(0, layout!.cell * 0.15), '+${e.points}', Palette.text,
        size: 0.36 + 0.03 * math.min(step, 5), life: 0.8, rise: 1.1);
    _lastStepCenter = stepCenter;

    boardLight = math.min(1.0, 0.35 + 0.22 * (step - 1) + 0.05 * (total - 4));
    if (step >= 3) shake = math.min(7, 2.0 * (step - 2) + 1);
  }

  void _crackEffects(CellPos pos, Cell cell) {
    if (layout == null || cell.kind != CellKind.shell) return;
    final at = _at(pos);
    effects
      ..shards(at)
      ..flash(at, -1, size: 1.4, life: 0.22, strength: 0.8)
      ..flash(at, cell.color, size: 2.0, life: 0.45, strength: 0.7)
      ..ring(at, -1, from: 0.25, to: 0.75, life: 0.28, strength: 0.8)
      ..sparks(at, cell.color, count: 4, power: 0.8);
  }

  void _landEffects(int column, int row) {
    if (layout == null) return;
    // A soft puff of light where the orb settles; a new move starts a new
    // chain, so the beam has nothing to connect back to.
    _lastStepCenter = null;
    final at = layout!.center(column.toDouble(), row - 0.45);
    effects.flash(at, -1, size: 0.9, life: 0.18, strength: 0.25);
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
