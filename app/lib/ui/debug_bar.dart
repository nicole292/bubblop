import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/palette.dart';
import '../game/pop_game.dart';
import 'type.dart';

/// PROTOTYPE ONLY: switches the 4/3-match experiment and shows session
/// stats. Removed before release. (Stones are no longer offered in the game;
/// RisingRowKind.stones remains in pop_core for simulations only.)
class DebugBar extends StatelessWidget {
  const DebugBar({super.key, required this.game});

  final PopGame game;

  @override
  Widget build(BuildContext context) {
    final config = game.config;
    return SizedBox(
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('DEV', style: PopType.of(9.5, 700, color: Palette.textDim.withValues(alpha: 0.6), spacing: 1.6)),
          const SizedBox(width: 10),
          for (final size in [4, 3])
            _choice('$size-match', config.matchSize == size,
                () => game.restart(config: config.copyWith(matchSize: size))),
          _choice('Stats', false, () => _showStats(context)),
        ],
      ),
    );
  }

  static const height = 36.0;

  Widget _choice(String label, bool selected, VoidCallback onTap) => TextButton(
        onPressed: selected ? null : onTap,
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 28),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          label,
          style: PopType.of(11, selected ? 700 : 500,
              color: selected ? Palette.text.withValues(alpha: 0.75) : Palette.textDim.withValues(alpha: 0.6)),
        ),
      );

  void _showStats(BuildContext context) {
    final report = game.stats.report();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Palette.bezelMid,
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
