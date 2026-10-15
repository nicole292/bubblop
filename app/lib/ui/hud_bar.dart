import 'package:flutter/material.dart';

import '../game/hud_state.dart';
import '../game/palette.dart';

const _numbers = TextStyle(fontFeatures: [FontFeature.tabularFigures()]);

/// Score, upcoming orbs and the rising-row countdown.
class HudBar extends StatelessWidget {
  const HudBar({super.key, required this.hud, required this.onRestart});

  final HudState hud;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Label('SCORE'),
                    Text('${hud.score}',
                        style: _numbers.copyWith(
                            fontSize: 30, fontWeight: FontWeight.w700, color: Palette.text)),
                    Text('Best ${hud.best} · Level ${hud.level}',
                        style: _numbers.copyWith(fontSize: 12, color: Palette.textDim)),
                  ],
                ),
              ),
              _Queue(queue: hud.queue),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Restart',
                onPressed: onRestart,
                icon: const Icon(Icons.refresh, color: Palette.textDim),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _Pressure(left: hud.pressure, max: hud.pressureMax),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 11, letterSpacing: 1.5, color: Palette.textDim, fontWeight: FontWeight.w600));
}

class _Queue extends StatelessWidget {
  const _Queue({required this.queue});
  final List<int> queue;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _Label('NEXT'),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < queue.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _Dot(color: Palette.orbs[queue[i]], size: i == 0 ? 30 : 20),
              ),
          ],
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

/// One pip per drop until the next row rises; filled pips are drops left.
class _Pressure extends StatelessWidget {
  const _Pressure({required this.left, required this.max});
  final int left;
  final int max;

  @override
  Widget build(BuildContext context) {
    final urgent = left <= 2;
    return Row(
      children: [
        const _Label('RISE IN'),
        const SizedBox(width: 10),
        for (var i = 0; i < max; i++)
          Container(
            width: 14,
            height: 6,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: i < left
                  ? (urgent ? Palette.danger : Palette.text)
                  : Palette.laneB,
            ),
          ),
      ],
    );
  }
}
