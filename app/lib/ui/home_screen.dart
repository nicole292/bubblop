import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/palette.dart';
import '../render/orb_sprites.dart';
import '../services/settings.dart';
import 'buttons.dart';
import 'orb_icon.dart';
import 'type.dart';

/// The first thing players see: a bouncing logo, their best score and one
/// big Play button. Nothing to read, nothing to sign up for.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.settings,
    required this.sprites,
    required this.onPlay,
    required this.onTap,
  });

  final Settings settings;
  final OrbSprites? sprites;
  final VoidCallback onPlay;
  final VoidCallback onTap;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final _clock = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Palette.skyTop, Palette.skyMid, Palette.skyBottom],
        ),
      ),
      child: SafeArea(
        child: ListenableBuilder(
          listenable: settings,
          builder: (context, _) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    const Spacer(),
                    RoundIconButton(
                      icon: settings.sound ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                      tooltip: 'Sound',
                      onPressed: () {
                        settings.sound = !settings.sound;
                        widget.onTap();
                      },
                    ),
                    const SizedBox(width: 10),
                    RoundIconButton(
                      icon: settings.music ? Icons.music_note_rounded : Icons.music_off_rounded,
                      tooltip: 'Music',
                      onPressed: () {
                        settings.music = !settings.music;
                        widget.onTap();
                      },
                    ),
                    const SizedBox(width: 10),
                    RoundIconButton(
                      icon: settings.haptics ? Icons.vibration_rounded : Icons.mobile_off_rounded,
                      tooltip: 'Vibration',
                      onPressed: () {
                        settings.haptics = !settings.haptics;
                        widget.onTap();
                      },
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),
              _Logo(clock: _clock, sprites: widget.sprites),
              const SizedBox(height: 10),
              Text('Drop  •  Match  •  Chain', style: PopType.of(17, 800, color: Colors.white, spacing: 1)),
              const Spacer(flex: 2),
              if (settings.best > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events_rounded, color: Palette.gold),
                      const SizedBox(width: 8),
                      Text('Best ${settings.best}', style: PopType.of(18, 900, numbers: true)),
                    ],
                  ),
                ),
              const SizedBox(height: 22),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: AnimatedBuilder(
                  animation: _clock,
                  // A gentle "breathing" invites the first tap.
                  builder: (context, child) => Transform.scale(
                    scale: 1 + 0.03 * math.sin(_clock.value * math.pi * 2 * 3),
                    child: child,
                  ),
                  child: BigButton(label: 'PLAY', icon: Icons.play_arrow_rounded, height: 72, onPressed: widget.onPlay),
                ),
              ),
              const Spacer(),
              const Padding(
                padding: EdgeInsets.only(bottom: 14),
                child: _Signature(),
              ),
            ],
          ),
        ),
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

  late final _controller = AnimationController(vsync: this, duration: Duration(milliseconds: _total.round()))
    ..forward();

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
        Text(letter,
            style: PopType.of(size, 1000,
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 11
                  ..strokeJoin = StrokeJoin.round
                  ..color = Colors.white)),
        Text(letter, style: PopType.of(size, 1000, color: color)),
      ],
    );
  }
}
