import 'dart:math' as math;

import 'package:flame/components.dart' show Vector2;
import 'package:flame/game.dart' show FlameGame;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:pop_core/pop_core.dart';

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

  BoardLayout? layout;

  /// Column the player is aiming at, or null when not touching.
  int? aimColumn;

  @override
  Color backgroundColor() => Palette.background;

  @override
  Future<void> onLoad() async {
    add(BoardComponent(this));
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    layout = BoardLayout(Size(size.x, size.y),
        columns: _config.columns, rows: _config.rows);
  }

  @override
  void update(double dt) {
    super.update(dt);
    phases.update(dt);
    scene.update(dt * phases.speed);
  }

  /// Starts a fresh round; a new [config] switches experiment mode.
  void restart({RulesConfig? config}) {
    if (config != null) {
      _config = config;
      final size = this.size;
      layout = BoardLayout(Size(size.x, size.y),
          columns: _config.columns, rows: _config.rows);
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
      };
    aimColumn = null;
    stats.startRound(_config);
    hud.value = HudState(best: stats.bestScore, bannerId: hud.value.bannerId);
    _publishRulesState();
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
