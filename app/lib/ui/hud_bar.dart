import 'package:flutter/material.dart';

import '../game/hud_state.dart';
import '../game/palette.dart';
import 'orb_icon.dart';
import 'type.dart';

/// Score, upcoming orbs and the rising-row countdown. Sizes itself to its
/// content; the board sits directly beneath it.
class HudBar extends StatelessWidget {
  const HudBar({super.key, required this.hud, required this.onRestart});

  final HudState hud;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('SCORE', style: PopType.label),
                    const SizedBox(height: 2),
                    Text('${hud.score}', style: PopType.score),
                  ],
                ),
              ),
              _Queue(queue: hud.queue),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Restart',
                visualDensity: VisualDensity.compact,
                onPressed: onRestart,
                icon: const Icon(Icons.refresh_rounded, color: Palette.textDim),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Best ${hud.best}  ·  Level ${hud.level}',
                style: PopType.small,
              ),
              const Spacer(),
              _Pressure(left: hud.pressure, max: hud.pressureMax),
            ],
          ),
        ],
      ),
    );
  }
}

class _Queue extends StatelessWidget {
  const _Queue({required this.queue});
  final List<int> queue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('NEXT', style: PopType.label),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < queue.length; i++)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Opacity(
                  opacity: i == 0 ? 1 : 0.8,
                  child: OrbIcon(color: queue[i], size: i == 0 ? 34 : 22),
                ),
              ),
          ],
        ),
      ],
    );
  }
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('RISE', style: PopType.label),
        const SizedBox(width: 8),
        for (var i = 0; i < max; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 12,
            height: 5,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: i < left
                  ? (urgent ? Palette.danger : Palette.text)
                  : Palette.pipEmpty,
            ),
          ),
      ],
    );
  }
}
