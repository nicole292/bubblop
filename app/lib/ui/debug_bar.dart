import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pop_core/pop_core.dart';

import '../game/palette.dart';
import '../game/pop_game.dart';

/// PROTOTYPE ONLY: switches experiment modes and shows session stats.
/// Removed before release.
class DebugBar extends StatelessWidget {
  const DebugBar({super.key, required this.game});

  final PopGame game;

  @override
  Widget build(BuildContext context) {
    final config = game.config;
    return SizedBox(
      height: height,
      child: Opacity(
        opacity: 0.75,
        child: Center(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                const Text('DEV', style: TextStyle(fontSize: 10, color: Palette.textDim, letterSpacing: 1.5)),
                const SizedBox(width: 8),
                for (final kind in RisingRowKind.values)
                  _choice(kind.name, config.risingRowKind == kind,
                      () => game.restart(config: config.copyWith(risingRowKind: kind))),
                const SizedBox(width: 6),
                for (final size in [4, 3])
                  _choice('$size-match', config.matchSize == size,
                      () => game.restart(config: config.copyWith(matchSize: size))),
                TextButton(
                  onPressed: () => _showStats(context),
                  child: const Text('Stats', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const height = 44.0;

  Widget _choice(String label, bool selected, VoidCallback onSelected) => Padding(
        padding: const EdgeInsets.only(right: 4),
        child: ChoiceChip(
          label: Text(label, style: const TextStyle(fontSize: 11)),
          selected: selected,
          showCheckmark: false,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onSelected: selected ? null : (_) => onSelected(),
        ),
      );

  void _showStats(BuildContext context) {
    final report = game.stats.report();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Palette.boardTop,
        title: const Text('Session stats'),
        content: SelectableText(report,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Clipboard.setData(ClipboardData(text: report)),
            child: const Text('Copy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
