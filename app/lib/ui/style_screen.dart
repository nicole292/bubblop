import 'package:flutter/material.dart';

import '../game/palette.dart';
import '../progress/cosmetics.dart';
import '../progress/progress.dart';
import 'glass.dart';
import 'swatches.dart';
import 'type.dart';

/// The collection: ball sets and skies. Owned items can be used with a tap;
/// coin items unlock with coins; gift items come from the level gifts.
/// Everything here is decorative.
class StyleScreen extends StatelessWidget {
  const StyleScreen({
    super.key,
    required this.progress,
    required this.onBack,
    required this.onTap,
    required this.onBought,
    required this.onDeny,
  });

  final Progress progress;
  final VoidCallback onBack;
  final VoidCallback onTap;
  final VoidCallback onBought;
  final VoidCallback onDeny;

  @override
  Widget build(BuildContext context) {
    return SkyGradient(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  GlassBackButton(onPressed: onBack),
                  Expanded(
                    child: Text('Style', textAlign: TextAlign.center, style: PopType.of(26, 1000, color: Colors.white)),
                  ),
                  CoinChip(coins: progress.coins),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      _section('BALLS'),
                      for (final c in Cosmetics.ofKind(CosmeticKind.balls)) _item(c),
                      const SizedBox(height: 10),
                      _section('SKY'),
                      for (final c in Cosmetics.ofKind(CosmeticKind.sky)) _item(c),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 10),
        child: Text(title, style: PopType.of(14, 900, color: Colors.white, spacing: 2)),
      );

  Widget _item(Cosmetic c) {
    final owned = progress.owns(c);
    final inUse = progress.selected(c.kind) == c;
    final unlock = c.unlock;
    Widget action;
    if (inUse) {
      action = _pill('In use', Palette.success, Colors.white, icon: Icons.check_rounded);
    } else if (owned) {
      action = _pill('Use', Palette.accent, Colors.white);
    } else if (unlock is CoinUnlock) {
      final afford = progress.coins >= unlock.price;
      action = Container(
        height: 38,
        padding: const EdgeInsets.fromLTRB(8, 0, 14, 0),
        decoration: BoxDecoration(
          color: afford ? const Color(0xFFFFF4D6) : Palette.well,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: afford ? Palette.gold : Palette.pipEmpty, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CoinIcon(size: 22),
            const SizedBox(width: 5),
            Text('${unlock.price}',
                style: PopType.of(15, 1000, color: afford ? Palette.ink : Palette.inkSoft, numbers: true)),
          ],
        ),
      );
    } else if (unlock is GiftUnlock) {
      action = _pill('Level ${unlock.level} gift', Palette.well, Palette.inkSoft, icon: Icons.auto_awesome_rounded);
    } else {
      action = const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          if (inUse) return;
          if (owned) {
            progress.select(c);
            onTap();
          } else if (unlock is CoinUnlock && progress.buy(c)) {
            progress.select(c);
            onBought();
          } else {
            onDeny();
          }
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            color: Palette.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: inUse ? Palette.success : Colors.transparent, width: 2.5),
            boxShadow: const [BoxShadow(color: Palette.panelShadow, blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: Row(
            children: [
              Opacity(opacity: owned ? 1 : 0.55, child: CosmeticSwatch(cosmetic: c, height: 38)),
              const SizedBox(width: 12),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(c.name, maxLines: 1, style: PopType.of(17, 1000)),
                ),
              ),
              const SizedBox(width: 8),
              action,
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(String text, Color background, Color foreground, {IconData? icon}) => Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(19)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 16, color: foreground), const SizedBox(width: 4)],
            Text(text, style: PopType.of(14, 900, color: foreground)),
          ],
        ),
      );
}
