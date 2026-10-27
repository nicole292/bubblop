import 'package:flutter/material.dart';

import '../game/palette.dart';
import '../progress/cosmetics.dart';
import '../progress/progress.dart';
import 'buttons.dart';
import 'glass.dart';
import 'swatches.dart';
import 'type.dart';

/// The collection: ball sets, shapes and skies. Owned items can be used with a tap;
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
                      for (final c in Cosmetics.ofKind(CosmeticKind.balls)) _item(context, c),
                      const SizedBox(height: 10),
                      _section('SHAPES'),
                      for (final c in Cosmetics.ofKind(CosmeticKind.shape)) _item(context, c),
                      const SizedBox(height: 10),
                      _section('SKY'),
                      for (final c in Cosmetics.ofKind(CosmeticKind.sky)) _item(context, c),
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

  Widget _item(BuildContext context, Cosmetic c) {
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
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _tapItem(context, c),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
          decoration: BoxDecoration(
            color: Palette.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: inUse ? Palette.success : Colors.transparent, width: 2.5),
            boxShadow: const [BoxShadow(color: Palette.panelShadow, blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (!owned) ...[
                    const Icon(Icons.lock_rounded, size: 18, color: Palette.inkSoft),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(c.name, maxLines: 1, style: PopType.of(18, 1000)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  action,
                ],
              ),
              const SizedBox(height: 10),
              // A big preview, so the sets are easy to compare.
              Opacity(
                opacity: owned ? 1 : 0.8,
                child: c.kind != CosmeticKind.sky
                    ? Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: CosmeticSwatch(cosmetic: c, height: 56, wide: true),
                      )
                    : CosmeticSwatch(cosmetic: c, height: 44, wide: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Owned: use it. Coin item: ask before spending. Otherwise say how to get it.
  Future<void> _tapItem(BuildContext context, Cosmetic c) async {
    if (progress.selected(c.kind) == c) return;
    if (progress.owns(c)) {
      progress.select(c);
      onTap();
      return;
    }
    final unlock = c.unlock;
    if (unlock is CoinUnlock && progress.coins >= unlock.price) {
      onTap();
      final yes = await showDialog<bool>(
        context: context,
        barrierColor: Palette.ink.withValues(alpha: 0.4),
        builder: (context) => _ConfirmUnlock(cosmetic: c, price: unlock.price),
      );
      if (yes == true && progress.buy(c)) {
        progress.select(c);
        onBought();
      }
      return;
    }
    onDeny();
    final message = switch (unlock) {
      CoinUnlock(:final price) => 'You need ${price - progress.coins} more coins. Complete levels to earn them!',
      GiftUnlock(:final level) => 'Complete level $level to win ${c.name}!',
      _ => '',
    };
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message, style: PopType.of(15, 800, color: Colors.white)),
        backgroundColor: Palette.ink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
      ));
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

/// "Unlock Jewel for 250 coins?", so coins are never spent by accident.
class _ConfirmUnlock extends StatelessWidget {
  const _ConfirmUnlock({required this.cosmetic, required this.price});
  final Cosmetic cosmetic;
  final int price;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 320,
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        decoration: BoxDecoration(
          color: Palette.card,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [BoxShadow(color: Color(0x663A2D9E), blurRadius: 30, offset: Offset(0, 12))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('UNLOCK', style: PopType.panelTitle),
            const SizedBox(height: 6),
            Text(cosmetic.name, style: PopType.of(30, 1000, color: Palette.accent)),
            const SizedBox(height: 14),
            cosmetic.kind != CosmeticKind.sky
                ? CosmeticSwatch(cosmetic: cosmetic, height: 52)
                : CosmeticSwatch(cosmetic: cosmetic, height: 48, wide: true),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CoinIcon(size: 26),
                const SizedBox(width: 6),
                Text('$price coins', style: PopType.of(20, 1000, numbers: true)),
              ],
            ),
            const SizedBox(height: 18),
            BigButton(label: 'Unlock', icon: Icons.lock_open_rounded, onPressed: () => Navigator.pop(context, true)),
            const SizedBox(height: 10),
            SoftButton(label: 'Not now', onPressed: () => Navigator.pop(context, false)),
          ],
        ),
      ),
    );
  }
}
