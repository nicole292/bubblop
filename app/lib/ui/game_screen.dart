import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/board_layout.dart';
import '../game/hud_state.dart';
import '../game/palette.dart';
import '../game/pop_game.dart';
import 'banner_text.dart';
import 'debug_bar.dart';
import 'game_over_panel.dart';
import 'hud_bar.dart';

/// The play screen: HUD directly above the board, any spare height mostly
/// above the HUD so play stays within thumb reach on tall phones.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final game = PopGame();

  @override
  void dispose() {
    game.hud.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final board = GestureDetector(
      // Tap a column, or drag to aim and release to drop.
      behavior: HitTestBehavior.opaque,
      onTapDown: (d) => game.aimAt(d.localPosition.dx),
      onTapUp: (_) => game.releaseAim(),
      onTapCancel: game.cancelAim,
      onPanStart: (d) => game.aimAt(d.localPosition.dx),
      onPanUpdate: (d) => game.aimAt(d.localPosition.dx),
      onPanEnd: (_) => game.releaseAim(),
      onPanCancel: game.cancelAim,
      child: GameWidget(game: game),
    );

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Palette.backgroundTop, Palette.backgroundBottom],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, 0.3),
              radius: 0.9,
              colors: [Palette.backgroundGlow.withValues(alpha: 0.55), Palette.backgroundGlow.withValues(alpha: 0)],
            ),
          ),
          child: Stack(
            children: [
              SafeArea(
                child: LayoutBuilder(builder: (context, constraints) {
                  // The board takes the remaining height, but never more
                  // than it needs; spare height ends up above the HUD.
                  final boardMax = BoardLayout.preferredHeight(constraints.maxWidth,
                      columns: game.config.columns, rows: game.config.rows);
                  return ValueListenableBuilder<HudState>(
                    valueListenable: game.hud,
                    builder: (context, hud, child) => Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        HudBar(hud: hud, onRestart: () => game.restart()),
                        Flexible(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: boardMax),
                            child: SizedBox.expand(
                              child: Stack(
                                children: [
                                  child!,
                                  Align(
                                    alignment: const Alignment(0, -0.3),
                                    child: BannerText(text: hud.banner, id: hud.bannerId),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        DebugBar(game: game),
                      ],
                    ),
                    child: board,
                  );
                }),
              ),
              ValueListenableBuilder<HudState>(
                valueListenable: game.hud,
                builder: (context, hud, _) => hud.isOver
                    ? GameOverPanel(
                        score: hud.score,
                        best: hud.best,
                        onPlayAgain: () => game.restart(),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
