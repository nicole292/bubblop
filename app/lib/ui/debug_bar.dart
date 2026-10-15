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
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 4,
        children: [
          for (final kind in RisingRowKind.values)
            _choice(kind.name, config.risingRowKind == kind,
                () => game.restart(config: config.copyWith(risingRowKind: kind))),
          const SizedBox(width: 8),
          for (final size in [4, 3])
            _choice('$size-match', config.matchSize == size,
                () => game.restart(config: config.copyWith(matchSize: size))),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => _showStats(context),
            child: const Text('Stats'),
          ),
        ],
      ),
    );
  }

  Widget _choice(String label, bool selected, VoidCallback onSelected) => ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        visualDensity: VisualDensity.compact,
        onSelected: selected ? null : (_) => onSelected(),
      );

  void _showStats(BuildContext context) {
    final report = game.stats.report();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Palette.board,
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
