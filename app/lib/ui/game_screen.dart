import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/hud_state.dart';
import '../game/pop_game.dart';
import 'banner_text.dart';
import 'debug_bar.dart';
import 'game_over_panel.dart';
import 'hud_bar.dart';

/// The play screen: HUD on top, board in the middle, debug controls below.
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
    return Scaffold(
      body: SafeArea(
        child: ValueListenableBuilder<HudState>(
          valueListenable: game.hud,
          builder: (context, hud, _) => Column(
            children: [
              HudBar(hud: hud, onRestart: () => game.restart()),
              Expanded(
                child: Stack(
                  children: [
                    // Tap a column, or drag to aim and release to drop.
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (d) => game.aimAt(d.localPosition.dx),
                      onTapUp: (_) => game.releaseAim(),
                      onTapCancel: game.cancelAim,
                      onPanStart: (d) => game.aimAt(d.localPosition.dx),
                      onPanUpdate: (d) => game.aimAt(d.localPosition.dx),
                      onPanEnd: (_) => game.releaseAim(),
                      onPanCancel: game.cancelAim,
                      child: GameWidget(game: game),
                    ),
                    Align(
                      alignment: const Alignment(0, -0.35),
                      child: BannerText(text: hud.banner, id: hud.bannerId),
                    ),
                    if (hud.isOver)
                      GameOverPanel(
                        score: hud.score,
                        best: hud.best,
                        onPlayAgain: () => game.restart(),
                      ),
                  ],
                ),
              ),
              DebugBar(game: game),
            ],
          ),
        ),
      ),
    );
  }
}
