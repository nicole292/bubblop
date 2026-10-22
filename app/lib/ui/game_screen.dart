import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/board_layout.dart';
import '../game/dev_options.dart';
import '../game/hud_state.dart';
import '../game/pop_game.dart';
import '../services/haptics.dart';
import '../services/settings.dart';
import '../services/sfx.dart';
import 'banner_text.dart';
import 'debug_bar.dart';
import 'game_over_panel.dart';
import 'hint_bubble.dart';
import 'home_screen.dart';
import 'hud_bar.dart';
import 'pause_menu.dart';

enum _Mode { home, playing, paused }

/// The app's single screen. The game canvas fills it (background, board,
/// effects); the HUD, menus and hints are laid out on top. An invisible
/// board slot tells the game where to draw the board.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.settings, required this.sfx, required this.haptics});

  final Settings settings;
  final Sfx sfx;
  final Haptics haptics;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final game = PopGame(settings: widget.settings, sfx: widget.sfx, haptics: widget.haptics);
  final _stackKey = GlobalKey();
  _Mode _mode =
      DevOptions.demo.isNotEmpty || DevOptions.isBench || DevOptions.startPlaying ? _Mode.playing : _Mode.home;

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

  void _play({bool? tutorial}) {
    _tap();
    game.restart(tutorial: tutorial);
    game.resumeEngine();
    setState(() => _mode = _Mode.playing);
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
            child: LayoutBuilder(builder: (context, constraints) {
              final boardMax = BoardLayout.preferredHeight(constraints.maxWidth,
                  columns: game.config.columns, rows: game.config.rows);
              return ValueListenableBuilder<HudState>(
                valueListenable: game.hud,
                builder: (context, hud, _) => Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Visibility(
                      visible: !DevOptions.skip('hud'),
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: RepaintBoundary(
                        child: HudBar(hud: hud, sprites: game.sprites, onPause: () {
                          _tap();
                          _pause();
                        }),
                      ),
                    ),
                    Flexible(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: boardMax),
                        child: _BoardSlot(game: game, stackKey: _stackKey, hud: hud),
                      ),
                    ),
                    if (DevOptions.showDevBar)
                      RepaintBoundary(child: DebugBar(game: game))
                    else
                      const SizedBox(height: 12),
                  ],
                ),
              );
            }),
          ),
          ValueListenableBuilder<HudState>(
            valueListenable: game.hud,
            builder: (context, hud, _) => hud.isOver && _mode == _Mode.playing
                ? GameOverPanel(hud: hud, onPlayAgain: () => _play(tutorial: false), onHome: _home)
                : const SizedBox.shrink(),
          ),
          if (_mode == _Mode.paused)
            PauseMenu(
              settings: widget.settings,
              onResume: _resume,
              onRestart: () => _play(tutorial: false),
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
                  sprites: game.sprites,
                  onPlay: () => _play(),
                  onTap: _tap,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Fills the space the board may use, reports it to the game after each
/// layout, turns touches into aiming and dropping, and hosts banners and
/// tutorial hints.
class _BoardSlot extends StatelessWidget {
  const _BoardSlot({required this.game, required this.stackKey, required this.hud});

  final PopGame game;
  final GlobalKey stackKey;
  final HudState hud;

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
        child: Stack(
          children: [
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
        ),
      ),
    );
  }
}
