import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/board_layout.dart';
import '../game/dev_options.dart';
import '../game/hud_state.dart';
import '../game/pop_game.dart';
import 'banner_text.dart';
import 'debug_bar.dart';
import 'game_over_panel.dart';
import 'hud_bar.dart';

/// The play screen. The game canvas fills the screen (background, board,
/// effects); the HUD is laid out on top, and an invisible board slot tells
/// the game where to draw the board. Spare height goes above the HUD so play
/// stays within thumb reach on tall phones.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final game = PopGame();
  final _stackKey = GlobalKey();

  @override
  void dispose() {
    game.hud.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                        child: HudBar(hud: hud, sprites: game.sprites, onRestart: () => game.restart()),
                      ),
                    ),
                    Flexible(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: boardMax),
                        child: _BoardSlot(game: game, stackKey: _stackKey, hud: hud),
                      ),
                    ),
                    RepaintBoundary(child: DebugBar(game: game)),
                  ],
                ),
              );
            }),
          ),
          ValueListenableBuilder<HudState>(
            valueListenable: game.hud,
            builder: (context, hud, _) => hud.isOver
                ? GameOverPanel(hud: hud, onPlayAgain: () => game.restart())
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// Fills the space the board may use, reports it to the game after each
/// layout, and turns touches into aiming and dropping.
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
    return SizedBox.expand(
      child: GestureDetector(
        // Tap a column, or drag to aim and release to drop.
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => game.aimAt(d.localPosition.dx),
        onTapUp: (_) => game.releaseAim(),
        onTapCancel: game.cancelAim,
        onPanStart: (d) => game.aimAt(d.localPosition.dx),
        onPanUpdate: (d) => game.aimAt(d.localPosition.dx),
        onPanEnd: (_) => game.releaseAim(),
        onPanCancel: game.cancelAim,
        child: Align(
          alignment: const Alignment(0, -0.25),
          child: BannerText(text: hud.banner, id: hud.bannerId),
        ),
      ),
    );
  }
}
