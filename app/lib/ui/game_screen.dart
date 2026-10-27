import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pop_core/pop_core.dart';

import '../game/board_layout.dart';
import '../game/dev_options.dart';
import '../game/hud_state.dart';
import '../game/pop_game.dart';
import '../progress/progress.dart';
import '../services/haptics.dart';
import '../services/settings.dart';
import '../services/sfx.dart';
import 'achievements_screen.dart';
import 'banner_text.dart';
import 'debug_bar.dart';
import 'game_over_panel.dart';
import 'hint_bubble.dart';
import 'home_screen.dart';
import 'hud_bar.dart';
import 'level_result_panel.dart';
import 'level_select_screen.dart';
import 'pause_menu.dart';
import 'style_screen.dart';

enum _Mode { home, levels, achievements, style, playing, paused }

/// The app's single screen. The game canvas fills it (background, board,
/// effects); the HUD, menus and hints are laid out on top. An invisible
/// board slot tells the game where to draw the board.
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.settings,
    required this.progress,
    required this.sfx,
    required this.haptics,
  });

  final Settings settings;
  final Progress progress;
  final Sfx sfx;
  final Haptics haptics;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final game = PopGame(
    settings: widget.settings,
    progress: widget.progress,
    sfx: widget.sfx,
    haptics: widget.haptics,
  );
  final _stackKey = GlobalKey();
  _Mode _mode = DevOptions.demo.isNotEmpty || DevOptions.isBench || DevOptions.startPlaying
      ? _Mode.playing
      : _Mode.home;

  /// A level whose goal card should open when the level map appears.
  int? _openLevel;

  /// The level map, so back can close its goal card first.
  final _levelsKey = GlobalKey<LevelSelectScreenState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    game.hud.dispose();
    super.dispose();
  }

  /// Leaving the app mid-round pauses it, so nothing happens unseen.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _mode == _Mode.playing && !game.hud.value.isOver) {
      _pause();
    }
  }

  void _tap() {
    widget.sfx.tap();
    widget.haptics.tap();
  }

  /// Starts a round: Endless, or the campaign [level].
  void _play({bool? tutorial, LevelDef? level}) {
    _tap();
    game.restart(tutorial: tutorial, level: level);
    game.resumeEngine();
    setState(() => _mode = _Mode.playing);
  }

  void _deny() {
    widget.sfx.deny();
    widget.haptics.deny();
  }

  /// Shows a menu screen over the (still running) game canvas.
  void _show(_Mode mode, {int? openLevel}) {
    _tap();
    game.resumeEngine();
    setState(() {
      _mode = mode;
      _openLevel = openLevel;
    });
  }

  void _pause() {
    game.pauseEngine();
    setState(() => _mode = _Mode.paused);
  }

  void _resume() {
    _tap();
    game.resumeEngine();
    setState(() => _mode = _Mode.playing);
  }

  void _home() {
    _tap();
    game.resumeEngine();
    setState(() => _mode = _Mode.home);
  }

  /// Android back and Escape: pause a round, resume from pause, leave a
  /// finished round for home. On the home screen back leaves the app.
  void _back() {
    switch (_mode) {
      case _Mode.playing:
        if (game.hud.value.isOver) {
          _home();
        } else {
          _tap();
          _pause();
        }
      case _Mode.paused:
        _resume();
      case _Mode.levels:
        if (!(_levelsKey.currentState?.closeIntro() ?? false)) _show(_Mode.home);
      case _Mode.achievements || _Mode.style:
        _show(_Mode.home);
      case _Mode.home:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _mode == _Mode.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): _back},
        child: Focus(autofocus: true, child: _screen()),
      ),
    );
  }

  Widget _screen() {
    return Scaffold(
      body: Stack(
        key: _stackKey,
        children: [
          Positioned.fill(child: GameWidget(game: game)),
          SafeArea(
            child: ValueListenableBuilder<HudState>(
              valueListenable: game.hud,
              builder: (context, hud, _) => Column(
                children: [
                  Expanded(
                    child: _BoardSlot(
                      game: game,
                      stackKey: _stackKey,
                      hud: hud,
                      onPause: () {
                        _tap();
                        _pause();
                      },
                    ),
                  ),
                  if (DevOptions.showDevBar) RepaintBoundary(child: DebugBar(game: game)),
                ],
              ),
            ),
          ),
          ValueListenableBuilder<HudState>(
            valueListenable: game.hud,
            builder: (context, hud, _) {
              if (!hud.isOver || _mode != _Mode.playing) return const SizedBox.shrink();
              if (hud.isLevel) {
                final level = hud.levelNumber!;
                return LevelResultPanel(
                  hud: hud,
                  onNext: () => _show(_Mode.levels, openLevel: level + 1),
                  onReplay: () => _play(tutorial: false, level: Campaign.level(level)),
                  // "LEVEL n" opens that level's goal card, with the map behind it.
                  onLevels: () => _show(
                    _Mode.levels,
                    openLevel: widget.progress.allCompleted ? null : widget.progress.currentLevel,
                  ),
                  onGiftOpen: () {
                    widget.sfx.newBest();
                    widget.haptics.big();
                  },
                );
              }
              return GameOverPanel(hud: hud, onPlayAgain: () => _play(tutorial: false), onHome: _home);
            },
          ),
          if (_mode == _Mode.paused)
            PauseMenu(
              settings: widget.settings,
              onResume: _resume,
              onRestart: () => _play(tutorial: false, level: game.level),
              onHowToPlay: () => _play(tutorial: true),
              onHome: _home,
            ),
          if (_mode == _Mode.home)
            Positioned.fill(
              child: ValueListenableBuilder<HudState>(
                valueListenable: game.hud,
                // Rebuilds when sprites are baked so the logo balls appear.
                builder: (context, _, _) => HomeScreen(
                  settings: widget.settings,
                  progress: widget.progress,
                  sprites: game.sprites,
                  // "LEVEL n" opens that level's goal card, with the map behind it.
                  onLevels: () => _show(
                    _Mode.levels,
                    openLevel: widget.progress.allCompleted ? null : widget.progress.currentLevel,
                  ),
                  onEndless: () => _play(),
                  onAchievements: () => _show(_Mode.achievements),
                  onStyle: () => _show(_Mode.style),
                  onHowToPlay: () => _play(tutorial: true),
                  onTap: _tap,
                ),
              ),
            ),
          if (_mode == _Mode.levels || _mode == _Mode.achievements || _mode == _Mode.style)
            Positioned.fill(
              child: ListenableBuilder(
                listenable: widget.progress,
                builder: (context, _) => switch (_mode) {
                  _Mode.levels => LevelSelectScreen(
                      key: _levelsKey,
                      progress: widget.progress,
                      openLevel: _openLevel,
                      onBack: () => _show(_Mode.home),
                      onPlay: (level) => _play(level: level),
                      onTap: _tap,
                      onDeny: _deny,
                    ),
                  _Mode.achievements => AchievementsScreen(
                      progress: widget.progress,
                      onBack: () => _show(_Mode.home),
                    ),
                  _ => StyleScreen(
                      progress: widget.progress,
                      onBack: () => _show(_Mode.home),
                      onTap: _tap,
                      onBought: () {
                        widget.sfx.praise();
                        widget.haptics.big();
                      },
                      onDeny: _deny,
                    ),
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Fills the space the board may use, reports it to the game after each
/// layout, turns touches into aiming and dropping, and hosts the card's
/// header, banners and tutorial hints.
class _BoardSlot extends StatelessWidget {
  const _BoardSlot({required this.game, required this.stackKey, required this.hud, required this.onPause});

  final PopGame game;
  final GlobalKey stackKey;
  final HudState hud;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = context.findRenderObject() as RenderBox?;
      final stack = stackKey.currentContext?.findRenderObject();
      if (box == null || !box.hasSize || stack == null) return;
      game.setBoardArea(box.localToGlobal(Offset.zero, ancestor: stack) & box.size);
    });
    final hint = hud.hint;
    final column = hud.hintColumn;
    return SizedBox.expand(
      child: GestureDetector(
        // Tap a column, or drag to aim and release to drop.
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => game.aimAt(d.localPosition.dx),
        onTapUp: (d) => game.releaseAim(d.localPosition.dx),
        onTapCancel: game.cancelAim,
        onPanStart: (d) => game.aimAt(d.localPosition.dx),
        onPanUpdate: (d) => game.aimAt(d.localPosition.dx),
        onPanEnd: (_) => game.releaseAim(),
        onPanCancel: game.cancelAim,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // The same layout the game draws the card with.
            final layout = BoardLayout(constraints.biggest, columns: game.config.columns, rows: game.config.rows);
            final next = _nextSpot(layout);
            return Stack(
              children: [
                Positioned.fromRect(
                  rect: layout.headerRect,
                  child: Visibility(
                    visible: !DevOptions.skip('hud'),
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: RepaintBoundary(
                      child: HudBar(hud: hud, sprites: game.sprites, onPause: onPause, showNext: next == null),
                    ),
                  ),
                ),
                // The next balls float just above the stack, where you are
                // already looking, and rise with it.
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  left: 0,
                  right: 0,
                  top: next ?? layout.rect.top,
                  height: layout.cell * _nextHeightCells,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: next == null || DevOptions.skip('hud') ? 0 : 1,
                      duration: const Duration(milliseconds: 250),
                      child: FittedBox(
                        child: NextBalls(sprites: game.sprites, queue: hud.queue, floating: true),
                      ),
                    ),
                  ),
                ),
                Align(
                  // High on the board, where it is usually empty.
                  alignment: const Alignment(0, -0.55),
                  child: BannerText(text: hud.banner, id: hud.bannerId),
                ),
                if (hint != null)
                  IgnorePointer(
                    child: HintBubble(
                      text: hint,
                      top: (game.boardTopInSlot() ?? 40) + 12,
                      arrowX: column != null && column >= 0 ? game.columnCenterInSlot(column) : null,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Height of the floating next-balls pill, in rows.
  static const _nextHeightCells = 0.85;

  /// Top of the floating next-balls pill: a little above the tallest
  /// column. Null when the stack is too tall to leave it room below the
  /// held ball (it moves up into the header then).
  double? _nextSpot(BoardLayout layout) {
    final board = game.rules.board;
    var tallest = 0;
    for (var c = 0; c < layout.columns; c++) {
      tallest = math.max(tallest, board.height(c));
    }
    final stackTop = layout.rect.top + (layout.rows - tallest) * layout.cell;
    final top = stackTop - layout.cell * (0.3 + _nextHeightCells);
    return top >= layout.rect.top + layout.cell * 0.2 ? top : null;
  }
}
