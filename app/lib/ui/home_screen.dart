import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/palette.dart';
import '../progress/progress.dart';
import '../render/orb_sprites.dart';
import '../services/settings.dart';
import 'buttons.dart';
import 'glass.dart';
import 'orb_icon.dart';
import 'type.dart';

/// The first thing players see: a light, glowing sky with glossy balls
/// drifting up, the bouncing logo, coins and best score, one big shining
/// Levels button, Classic (no goals, just play) below it, and three quiet
/// round buttons (achievements, style, how to play). Nothing to read,
/// nothing to sign up for.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.settings,
    required this.progress,
    required this.sprites,
    required this.onLevels,
    required this.onClassic,
    required this.onAchievements,
    required this.onStyle,
    required this.onHowToPlay,
    required this.onTap,
  });

  final Settings settings;
  final Progress progress;
  final OrbSprites? sprites;
  final VoidCallback onLevels;
  final VoidCallback onClassic;
  final VoidCallback onAchievements;
  final VoidCallback onStyle;
  final VoidCallback onHowToPlay;
  final VoidCallback onTap;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final _clock = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();

  /// A slow minute-long loop for the drifting balls.
  late final _drift = AnimationController(vsync: this, duration: const Duration(minutes: 1))..repeat();

  @override
  void dispose() {
    _clock.dispose();
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.skyTop, Palette.skyMid, Palette.skyBottom],
        ),
      ),
      child: Stack(
        children: [
          // A soft light behind the logo.
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.3),
                  radius: 0.75,
                  colors: [Color(0x66FFFFFF), Color(0x00FFFFFF)],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: _FloatingBalls(clock: _drift, sprites: widget.sprites),
          ),
          SafeArea(
            child: ListenableBuilder(
              listenable: Listenable.merge([settings, widget.progress]),
              builder: (context, _) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Row(
                      children: [
                        CoinChip(coins: widget.progress.coins),
                        if (settings.best > 0) ...[const SizedBox(width: 8), _BestChip(best: settings.best)],
                        const Spacer(),
                        GlassIconButton(
                          icon: settings.sound ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                          tooltip: 'Sound',
                          off: !settings.sound,
                          onPressed: () {
                            settings.sound = !settings.sound;
                            widget.onTap();
                          },
                        ),
                        const SizedBox(width: 8),
                        GlassIconButton(
                          icon: settings.music ? Icons.music_note_rounded : Icons.music_off_rounded,
                          tooltip: 'Music',
                          off: !settings.music,
                          onPressed: () {
                            settings.music = !settings.music;
                            widget.onTap();
                          },
                        ),
                        const SizedBox(width: 8),
                        GlassIconButton(
                          icon: settings.haptics ? Icons.vibration_rounded : Icons.mobile_off_rounded,
                          tooltip: 'Vibration',
                          off: !settings.haptics,
                          onPressed: () {
                            settings.haptics = !settings.haptics;
                            widget.onTap();
                          },
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 3),
                  _Logo(clock: _clock, sprites: widget.sprites),
                  const SizedBox(height: 14),
                  Text('DROP  •  MATCH  •  CHAIN', style: PopType.of(14, 900, color: Colors.white, spacing: 2.5)),
                  const Spacer(flex: 3),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 44),
                    child: AnimatedBuilder(
                      animation: _clock,
                      // A gentle "breathing" invites the first tap.
                      builder: (context, child) =>
                          Transform.scale(scale: 1 + 0.025 * math.sin(_clock.value * math.pi * 2 * 3), child: child),
                      child: _ShinyButton(
                        clock: _clock,
                        child: BigButton(
                          label: widget.progress.allCompleted ? 'LEVELS' : 'LEVEL ${widget.progress.currentLevel}',
                          icon: Icons.play_arrow_rounded,
                          height: 76,
                          onPressed: widget.onLevels,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Classic: the glass pill of the round buttons, as wide as Levels.
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 44),
                    child: GlassPill(
                      label: 'Classic',
                      icon: Icons.all_inclusive_rounded,
                      wide: true,
                      onPressed: widget.onClassic,
                    ),
                  ),
                  const Spacer(flex: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 100,
                        child: GlassIconButton(
                          icon: Icons.emoji_events_rounded,
                          tooltip: 'Achievements',
                          label: 'Awards',
                          size: 52,
                          onPressed: widget.onAchievements,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 100,
                        child: GlassIconButton(
                          icon: Icons.palette_rounded,
                          tooltip: 'Style',
                          label: 'Style',
                          size: 52,
                          onPressed: widget.onStyle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 100,
                        child: GlassIconButton(
                          icon: Icons.lightbulb_rounded,
                          tooltip: 'How to play',
                          label: 'How to play',
                          size: 52,
                          onPressed: () {
                            widget.onTap();
                            widget.onHowToPlay();
                          },
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Padding(padding: EdgeInsets.only(bottom: 14), child: _Signature()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The best Classic score, next to the coins.
class _BestChip extends StatelessWidget {
  const _BestChip({required this.best});
  final int best;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.fromLTRB(7, 0, 16, 0),
      decoration: glass(22),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFD45C), Palette.gold],
              ),
            ),
            child: const Icon(Icons.emoji_events_rounded, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Text('$best', style: PopType.of(20, 900, color: Colors.white, numbers: true)),
        ],
      ),
    );
  }
}

/// A streak of light sweeps across the button every few seconds.
class _ShinyButton extends StatelessWidget {
  const _ShinyButton({required this.clock, required this.child});
  final Animation<double> clock;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(38),
              child: AnimatedBuilder(
                animation: clock,
                builder: (context, _) {
                  // Sweeps during the first 30% of each half-cycle.
                  final t = (clock.value * 2) % 1 / 0.3;
                  if (t > 1) return const SizedBox.shrink();
                  final x = -1.6 + 3.2 * Curves.easeInOut.transform(t);
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(x - 0.5, -1),
                        end: Alignment(x + 0.5, 1),
                        colors: const [Color(0x00FFFFFF), Color(0x66FFFFFF), Color(0x00FFFFFF)],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Glossy balls drifting slowly upward behind everything; bigger ones are
/// nearer (brighter and faster), and each sways a little.
class _FloatingBalls extends StatelessWidget {
  const _FloatingBalls({required this.clock, required this.sprites});
  final Animation<double> clock;
  final OrbSprites? sprites;

  // (x 0..1, start 0..1, size, colour, screens travelled per minute; whole
  // numbers so the loop is seamless)
  static const _balls = [
    (0.08, 0.10, 46.0, 0, 3),
    (0.88, 0.25, 38.0, 1, 3),
    (0.22, 0.55, 22.0, 2, 2),
    (0.70, 0.70, 28.0, 3, 2),
    (0.50, 0.92, 18.0, 4, 1),
    (0.95, 0.60, 16.0, 0, 1),
    (0.04, 0.80, 20.0, 3, 1),
    (0.36, 0.30, 14.0, 1, 1),
    (0.62, 0.05, 34.0, 2, 2),
    (0.80, 0.95, 50.0, 4, 3),
  ];

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) => AnimatedBuilder(
          animation: clock,
          builder: (context, _) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            return Stack(
              children: [
                for (final (x, start, size, color, speed) in _balls)
                  _ball(w, h, x, (start + clock.value * speed) % 1, size, color),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _ball(double w, double h, double x, double p, double size, int color) {
    final y = h + size - p * (h + size * 2);
    final sway = math.sin((p * 4 + x * 7) * math.pi) * 10;
    return Positioned(
      left: x * w - size / 2 + sway,
      top: y,
      child: Opacity(
        opacity: (0.25 + size / 80).clamp(0.0, 0.85),
        child: OrbIcon(sprites: sprites, color: color, size: size),
      ),
    );
  }
}

/// The maker's name, barely there: thin white letters that surface one by
/// one, linger faintly, then dissolve. Easy to miss; there if you look.
/// It plays as soon as the app opens, and again on each return home.
class _Signature extends StatefulWidget {
  const _Signature();

  @override
  State<_Signature> createState() => _SignatureState();
}

class _SignatureState extends State<_Signature> with SingleTickerProviderStateMixin {
  static const _word = 'elishakov';
  static const _total = 4400.0;

  late final _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _total.round()),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final ms = _controller.value * _total;
          // Everything fades out together at the end.
          final out = 1 - Curves.easeInOut.transform(((ms - 3000) / 1200).clamp(0.0, 1.0));
          if (out <= 0) return const SizedBox(height: 16);
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < _word.length; i++)
                Opacity(
                  // From the first frame, letter by letter, 90 ms apart, each easing in
                  // over 600 ms.
                  opacity: 0.28 * out * Curves.easeOut.transform(((ms - 100 - i * 90) / 600).clamp(0.0, 1.0)),
                  child: Text(_word[i], style: PopType.of(12, 600, color: Colors.white, spacing: 3)),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// "Bubblop" in chunky letters, one ball colour each, bouncing in turn, with
/// balls bobbing around it.
class _Logo extends StatelessWidget {
  const _Logo({required this.clock, required this.sprites});

  final Animation<double> clock;
  final OrbSprites? sprites;

  static const _letters = ['B', 'u', 'b', 'b', 'l', 'o', 'p'];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: clock,
      builder: (context, _) {
        final t = clock.value * math.pi * 2;
        return SizedBox(
          height: 190,
          width: 340,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (final (x, y, size, color, phase) in const [
                (-140.0, -60.0, 34.0, 1, 0.0),
                (135.0, -70.0, 26.0, 3, 1.3),
                (-125.0, 60.0, 24.0, 2, 2.1),
                (140.0, 55.0, 36.0, 0, 3.4),
                (0.0, -88.0, 20.0, 4, 4.4),
              ])
                Transform.translate(
                  offset: Offset(x, y + math.sin(t * 2 + phase) * 6),
                  child: OrbIcon(sprites: sprites, color: color, size: size),
                ),
              // Scales the word down to fit narrow screens instead of overflowing.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < _letters.length; i++)
                        Transform.translate(
                          offset: Offset(0, -math.max(0, math.sin(t * 2 - i * 0.55)) * 10),
                          child: Transform.rotate(
                            angle: (i.isEven ? -1 : 1) * 0.05,
                            child: _Letter(_letters[i], Palette.balls[i % Palette.balls.length]),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Letter extends StatelessWidget {
  const _Letter(this.letter, this.color);
  final String letter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const size = 68.0;
    return Stack(
      children: [
        // Soft drop shadow, chunky white outline, then the coloured face.
        Transform.translate(
          offset: const Offset(0, 5),
          child: Text(letter, style: PopType.of(size, 1000, color: const Color(0x403A2D9E))),
        ),
        Text(
          letter,
          style: PopType.of(
            size,
            1000,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 11
              ..strokeJoin = StrokeJoin.round
              ..color = Colors.white,
          ),
        ),
        Text(letter, style: PopType.of(size, 1000, color: color)),
      ],
    );
  }
}
