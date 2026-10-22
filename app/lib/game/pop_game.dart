import 'dart:math' as math;
import 'dart:ui' show FragmentProgram;

import 'package:flame/components.dart' show Vector2;
import 'package:flame/game.dart' show FlameGame;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:pop_core/pop_core.dart';

import '../render/background.dart';
import '../render/effects.dart';
import '../render/orb_sprites.dart';
import '../services/haptics.dart';
import '../services/settings.dart';
import '../services/sfx.dart';
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
import 'tutorial.dart';

/// Connects the rules ([Game]) to the screen. Input goes straight to the
/// rules; the resulting events are queued as animation phases, which also
/// trigger effects, sound and vibration.
///
/// The Flame canvas covers the whole screen (background, board, effects);
/// the Flutter HUD sits on top and tells the game where the board goes via
/// [setBoardArea].
class PopGame extends FlameGame {
  PopGame({
    required this.settings,
    required this.sfx,
    required this.haptics,
    this._config = const RulesConfig(),
  }) {
    _startRound(tutorial: false);
  }

  final Settings settings;
  final Sfx sfx;
  final Haptics haptics;

  RulesConfig _config;
  RulesConfig get config => _config;

  late Game rules;
  late BoardScene scene;
  final phases = PhaseQueue();
  final stats = SessionStats();
  final hud = ValueNotifier(const HudState());
  final effects = Effects();
  final background = SkyBackground();

  BoardLayout? layout;
  OrbSprites? sprites;
  FragmentProgram? _orbProgram;
  bool _programLoaded = false;
  Rect? _boardArea;

  /// Column the player is aiming at, or null when not touching.
  int? aimColumn;

  /// Board border pulse on pops, stronger with chain length (0–1).
  double boardLight = 0;
  Color boardLightColor = Palette.balls[3];

  /// Screen shake for big chains: amplitude in pixels, decays quickly.
  double shake = 0;

  /// Seconds since start; drives idle animation.
  double time = 0;

  /// Where the previous chain step burst, for the sparkle trail.
  Offset? _lastStepCenter;

  /// Praise for the move being animated: shown at chain step [_praiseStep].
  int _praiseStep = 0;
  String? _praiseText;

  /// Shell cracks make one sound per chain step, not one per shell:
  /// [_stepToken] counts chain steps; [_crackSoundToken] remembers which
  /// step last played the crack sound.
  int _stepToken = 0;
  int _crackSoundToken = -1;

  TutorialStep _tutorial = TutorialStep.off;
  double _hintTimer = 0;

  // POP_BENCH only: auto-play and frame timing (see dev_options.dart).
  FrameBench? _bench;
  double _benchTime = 0;
  double _benchNextDrop = 0;

  @override
  Color backgroundColor() => Palette.skyTop;

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
    _updateTutorial(dt);
    if (_bench != null) _benchStep(dt);
  }

  /// Called by the screen with the board slot's rectangle in canvas
  /// coordinates.
  void setBoardArea(Rect area) {
    if (area == _boardArea) return;
    _boardArea = area;
    _relayout();
  }

  /// X of a column's centre, relative to the board slot (for hint arrows).
  double? columnCenterInSlot(int column) {
    final layout = this.layout;
    final area = _boardArea;
    if (layout == null || area == null) return null;
    return layout.center(column.toDouble(), 0).dx - area.left;
  }

  /// Y of the board's top edge, relative to the board slot.
  double? boardTopInSlot() {
    final layout = this.layout;
    final area = _boardArea;
    if (layout == null || area == null) return null;
    return layout.rect.top - area.top;
  }

  /// Starts a fresh round. The first round on a new install is the tutorial.
  void restart({RulesConfig? config, bool? tutorial}) {
    if (config != null) {
      _config = config;
      _relayout(force: true);
    }
    phases.clear();
    effects.clear();
    _startRound(tutorial: tutorial ?? !settings.tutorialDone);
  }

  /// [x] is relative to the board slot.
  void aimAt(double x) {
    final layout = this.layout;
    if (rules.isOver || layout == null) return;
    aimColumn = layout.columnAt(x + (_boardArea?.left ?? 0));
  }

  void cancelAim() => aimColumn = null;

  /// Drops at the aimed column. A tap passes where it lifted ([x], relative
  /// to the board slot): the gesture arena may have cancelled the aim just
  /// before (a press held over 0.1 s cancels the unused drag on release).
  void releaseAim([double? x]) {
    if (x != null) aimAt(x);
    final column = aimColumn;
    aimColumn = null;
    if (column != null) dropAt(column);
  }

  void dropAt(int column) {
    if (!phases.isIdle) phases.speed = Timings.fastForward;
    final result = rules.drop(column);
    if (!result.accepted) {
      if (!rules.isOver) {
        scene.shake(column);
        sfx.deny();
        haptics.deny();
      }
      return;
    }
    stats.recordMove(result);
    if (rules.isOver) {
      final summary = stats.finishRound(score: rules.score, moves: rules.moves);
      debugPrint('Round over score ${summary.score}, moves ${summary.moves}, '
          'best chain ${summary.longestChain}');
    }

    _choosePraise(result);
    for (final event in result.events) {
      phases.addAll(scene.phasesFor(event));
    }
    final popped = result.events.any((e) => e is ChainStep);
    phases.addAll([Phase(0, onStart: () => _afterMove(popped))]);
    _publishRulesState();
  }

  /// Praise words for big moments, shown as the last chain step bursts.
  void _choosePraise(MoveResult result) {
    final steps = result.events.whereType<ChainStep>().toList();
    _praiseText = null;
    _praiseStep = steps.length;
    if (steps.isEmpty) return;
    final biggest = steps.expand((s) => s.groups).map((g) => g.cells.length).reduce(math.max);
    _praiseText = switch (steps.length) {
      >= 5 => 'Incredible!',
      4 => 'Amazing!',
      3 => 'Great!',
      2 => 'Nice!',
      _ => biggest >= 6 ? 'Big pop!' : null,
    };
  }

  void _relayout({bool force = false}) {
    final area = _boardArea;
    if (area == null || area.isEmpty) return;
    final next = BoardLayout(area.size,
        columns: _config.columns, rows: _config.rows, offset: area.topLeft);
    final radius = next.ballRadius;
    if (_programLoaded && (force || sprites == null || (sprites!.radius - radius).abs() > 0.5)) {
      sprites?.dispose();
      final ratio = DevOptions.pixelRatio;
      sprites = OrbSprites.bake(radius, ratio, _orbProgram);
      // New sprites: let the HUD redraw its ball icons with them.
      hud.value = hud.value.copyWith(spritesVersion: hud.value.spritesVersion + 1);
    }
    layout = next;
    effects.cell = next.cell;
  }

  void _startRound({required bool tutorial}) {
    final seed = DevOptions.seed ?? math.Random().nextInt(1 << 31);
    rules = DevOptions.demoGame(_config) ??
        (tutorial ? Tutorial.game(_config, seed) : Game(seed: seed, config: _config));
    scene = BoardScene(_config.columns, _config.rows)
      ..onPoints = (points) {
        if (points <= 0) return;
        final h = hud.value;
        hud.value = h.copyWith(score: h.score + points, gain: points, gainId: h.gainId + 1);
      }
      ..onBanner = _banner
      ..onGameOver = _gameOver
      ..onStepPopped = _stepEffects
      ..onCracked = _crackEffects
      ..onLanded = _landEffects
      ..onRose = _roseEffects
      ..onLevelUp = (_) {
        sfx.levelUp();
        haptics.big();
      }
      ..load(rules.board);
    aimColumn = null;
    boardLight = 0;
    shake = 0;
    _lastStepCenter = null;
    _praiseText = null;
    stats.startRound(_config);
    _tutorial = tutorial && DevOptions.demo.isEmpty ? TutorialStep.drop : TutorialStep.off;
    hud.value = HudState(
      best: settings.best,
      bannerId: hud.value.bannerId,
      gainId: hud.value.gainId,
      spritesVersion: hud.value.spritesVersion,
      hint: _tutorial == TutorialStep.drop ? Tutorial.dropHint : null,
      hintColumn: _tutorial == TutorialStep.drop ? Tutorial.dropColumn : null,
    );
    _publishRulesState();
  }

  void _banner(String text) {
    hud.value = hud.value.copyWith(banner: text, bannerId: hud.value.bannerId + 1);
  }

  void _gameOver() {
    // Show what happened: the board jolts as the round ends.
    shake = math.max(shake, (layout?.cell ?? 50) * 0.12);
    final last = stats.rounds.isEmpty ? null : stats.rounds.last;
    final isBest = settings.recordRound(rules.score);
    if (isBest) {
      sfx.newBest();
      haptics.big();
      final area = _boardArea;
      if (area != null) {
        // A celebration burst behind the results card.
        for (var i = 0; i < Palette.balls.length; i++) {
          effects.confetti(area.center.translate((i - 2) * 40.0, -40), Palette.balls[i], count: 14, power: 2.5);
        }
      }
    } else {
      sfx.gameOver();
    }
    hud.value = hud.value.copyWith(
      isOver: true,
      best: settings.best,
      newBest: isBest,
      longestChain: last?.longestChain ?? 0,
      moves: last?.moves ?? rules.moves,
      clearHint: true,
    );
    _tutorial = TutorialStep.off;
  }

  // --- Tutorial -----------------------------------------------------------

  void _afterMove(bool popped) {
    if (_tutorial == TutorialStep.drop) {
      if (popped) {
        // The key lesson is learned; don't force the tutorial again.
        settings.tutorialDone = true;
        _tutorial = TutorialStep.chain;
        _hintTimer = 4.5;
        hud.value = hud.value.copyWith(hint: Tutorial.chainHint, clearHint: false, hintColumn: -1);
      } else {
        hud.value = hud.value.copyWith(hint: Tutorial.retryHint);
      }
    }
  }

  void _updateTutorial(double dt) {
    switch (_tutorial) {
      case TutorialStep.chain:
        _hintTimer -= dt;
        if (_hintTimer <= 0) {
          _tutorial = TutorialStep.waitForRise;
          hud.value = hud.value.copyWith(clearHint: true);
        }
      case TutorialStep.waitForRise:
        if (!rules.isOver && rules.pressure <= 2 && phases.isIdle) {
          _tutorial = TutorialStep.rise;
          hud.value = hud.value.copyWith(hint: Tutorial.riseHint, hintColumn: -1);
        }
      default:
        break;
    }
  }

  void _finishTutorial() {
    _tutorial = TutorialStep.off;
    hud.value = hud.value.copyWith(clearHint: true);
  }

  // --- Effects, sound and vibration --------------------------------------

  Offset _at(CellPos p) => layout!.center(p.col.toDouble(), p.row.toDouble());

  /// Effects grow with group size and, more strongly, with chain step, so a
  /// 3-step chain feels clearly bigger than a single 4-match.
  void _stepEffects(ChainStep e) {
    final step = e.step;
    _stepToken++;
    sfx.pop(step, groups: e.groups.length);
    haptics.pop(step);
    if (layout == null) return;
    if (_bench != null) _bench!.pops++;
    var stepCenter = Offset.zero;
    var total = 0;
    for (final g in e.groups) {
      final n = g.cells.length;
      final color = Palette.balls[g.color];
      final intensity = ((1 + 0.22 * (n - 4)) * (1 + 0.45 * (step - 1))).clamp(1.0, 3.4);
      var sum = Offset.zero;
      for (final p in g.cells) {
        final at = _at(p);
        sum += at;
        // Restrained: a burst of light and a couple of confetti bits per
        // ball, growing with group size and chain step.
        effects
          ..flash(at, color, to: 0.55 + 0.05 * step)
          ..confetti(at, color, count: (0.5 + 1.2 * intensity).round(), power: intensity);
      }
      final center = sum / n.toDouble();
      stepCenter += sum;
      total += n;
      effects
        ..ring(center, color, to: 0.8 + 0.2 * math.sqrt(n) + 0.25 * (step - 1), width: 0.12 + 0.03 * step)
        ..sparkles(center, count: step, spread: 0.5 + 0.1 * math.sqrt(n), color: Palette.gold);
      boardLightColor = color;
    }
    stepCenter = stepCenter / total.toDouble();

    // Older step labels make way for the new ones.
    effects.fadeLabels();
    // Chain payoff: a sparkle trail from the previous burst to this one, and
    // a bouncy step badge where it happened.
    if (step > 1 && _lastStepCenter != null) {
      final color = Palette.balls[e.groups.first.color];
      effects
        ..trail(_lastStepCenter!, stepCenter, Palette.gold)
        ..label(stepCenter.translate(0, -layout!.cell * 0.45), '×$step', color,
            size: 0.5 + 0.07 * math.min(step, 5), life: 0.7, rise: 0.5);
    }
    // The total also lands in the score panel; this small tag says where.
    effects.label(stepCenter.translate(0, layout!.cell * 0.25), '+${e.points}', Palette.ink,
        size: 0.32 + 0.02 * math.min(step, 5), life: 0.6, rise: 0.8);
    _lastStepCenter = stepCenter;

    boardLight = math.min(1.0, 0.35 + 0.2 * (step - 1) + 0.05 * (total - 4));
    if (step >= 3) shake = math.min(5, 1.2 * (step - 2) + 1);

    if (step == _praiseStep && _praiseText != null) {
      _banner(_praiseText!);
      sfx.praise();
      _praiseText = null;
    }
  }

  /// A shell's bubble pops: droplets, a ring in the freed ball's colour.
  void _crackEffects(CellPos pos, Cell cell) {
    if (cell.kind != CellKind.shell) return;
    if (_crackSoundToken != _stepToken) {
      _crackSoundToken = _stepToken;
      sfx.crack();
    }
    if (layout == null) return;
    final at = _at(pos);
    effects
      ..puff(at, count: 8, spread: 0.55, size: 0.11, color: const Color(0xFFC7D0FF))
      ..ring(at, Palette.balls[cell.color], from: 0.3, to: 0.85, life: 0.32, width: 0.12)
      ..sparkles(at, count: 2, spread: 0.4, color: Palette.gold);
  }

  void _landEffects(int column, int row) {
    sfx.land();
    haptics.land();
    // A new move starts a new chain, so the trail has nothing to link back to.
    _lastStepCenter = null;
    if (layout == null) return;
    final at = layout!.center(column.toDouble(), row - 0.42);
    effects.puff(at, count: 4, spread: 0.25, size: 0.06, color: const Color(0xFFCBD3FF));
  }

  void _roseEffects() {
    sfx.rise();
    if (_tutorial == TutorialStep.rise) _finishTutorial();
  }

  /// Values the HUD can show immediately (they are not animated).
  void _publishRulesState() {
    hud.value = hud.value.copyWith(
      level: rules.level,
      queue: rules.queue,
      pressure: rules.pressure,
      pressureMax: _config.pressureInterval(rules.level),
      best: settings.best,
    );
  }

  // --- Benchmark (developer only) ----------------------------------------

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
      restart(tutorial: false);
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
}
