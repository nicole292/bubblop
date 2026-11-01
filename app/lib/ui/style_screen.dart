import 'package:flutter/material.dart';

import '../game/palette.dart';
import '../progress/cosmetics.dart';
import '../progress/progress.dart';
import '../services/settings.dart';
import 'buttons.dart';
import 'glass.dart';
import 'swatches.dart';
import 'type.dart';

/// The collection: light or dark theme, ball sets, shapes and skies. Owned items can be used with a tap;
/// coin items unlock with coins; gift items come from the level gifts.
/// Everything here is decorative.
class StyleScreen extends StatelessWidget {
  const StyleScreen({
    super.key,
    required this.progress,
    required this.settings,
    required this.onBack,
    required this.onTap,
    required this.onBought,
    required this.onDeny,
  });

  final Progress progress;
  final Settings settings;
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
                    child: Text(
                      'Shapes',
                      textAlign: TextAlign.center,
                      style: PopType.of(26, 1000, color: Colors.white),
                    ),
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
                      _section('THEME'),
                      _themeCard(),
                      const SizedBox(height: 10),
                      const SizedBox(height: 10),
                      _section('SHAPES'),
                      _shapeCard(context),
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

  /// Every shape in one card: a small tile per shape showing a single piece.
  Widget _shapeCard(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        decoration: BoxDecoration(
          color: Palette.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Palette.edge, width: 1.2),
          boxShadow: [BoxShadow(color: Palette.panelShadow, blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: LayoutBuilder(
          builder: (context, box) {
            // Four tiles a row on most phones, three on narrow ones.
            final perRow = box.maxWidth >= 340 ? 4 : 3;
            final tile = (box.maxWidth - 8 * (perRow - 1)) / perRow;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in Cosmetics.ofKind(CosmeticKind.shape)) _shapeTile(context, c, tile),
                ],
              ),
            );
          },
        ),
      );

  /// One shape: a single piece in its own colour, its name, and what it
  /// takes to get it. No tile background; the shape in use gets a ring.
  Widget _shapeTile(BuildContext context, Cosmetic c, double width) {
    final owned = progress.owns(c);
    final inUse = progress.selected(c.kind) == c;
    final unlock = c.unlock;
    final status = inUse
        ? Icon(Icons.check_circle_rounded, size: 18, color: Palette.success)
        : owned
            ? Text('Use', style: PopType.of(12, 900, color: Palette.accent))
            : switch (unlock) {
                CoinUnlock(:final price) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CoinIcon(size: 14),
                      const SizedBox(width: 3),
                      Text('$price',
                          style: PopType.of(12, 900,
                              color: progress.coins >= price ? Palette.ink : Palette.inkSoft, numbers: true)),
                    ],
                  ),
                GiftUnlock(:final level) => Text('Lv $level gift', style: PopType.of(11, 900, color: Palette.inkSoft)),
                _ => const SizedBox.shrink(),
              };
    return GestureDetector(
      onTap: () => _tapItem(context, c),
      child: Container(
        width: width,
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: inUse ? Palette.success : Colors.transparent, width: 2.5),
        ),
        child: Column(
          children: [
            Opacity(
              opacity: owned ? 1 : 0.75,
              child: GlossyBall(color: c.shape.signature, size: width * 0.5, shape: c.shape),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(c.name, maxLines: 1, style: PopType.of(13, 900)),
            ),
            const SizedBox(height: 3),
            SizedBox(height: 18, child: Center(child: status)),
          ],
        ),
      ),
    );
  }

  /// Light, dark or follow the phone; the same setting as in the pause menu.
  Widget _themeCard() => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
    decoration: BoxDecoration(
      color: Palette.card,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Palette.edge, width: 1.2),
      boxShadow: [BoxShadow(color: Palette.panelShadow, blurRadius: 12, offset: const Offset(0, 4))],
    ),
    child: ListenableBuilder(
      listenable: settings,
      builder: (context, _) => ThemeRow(
        value: settings.theme,
        onChanged: (v) {
          settings.theme = v;
          onTap();
        },
      ),
    ),
  );

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(6, 6, 6, 10),
    child: Text(title, style: PopType.of(14, 900, color: Colors.white, spacing: 2)),
  );

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
        barrierColor: Palette.scrim.withValues(alpha: 0.4),
        builder: (context) => _Confirm(
          title: c.name,
          preview: c.kind != CosmeticKind.sky
              ? CosmeticSwatch(cosmetic: c, height: 52)
              : CosmeticSwatch(cosmetic: c, height: 48, wide: true),
          price: unlock.price,
          action: 'Unlock',
        ),
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
    _say(context, message);
  }

  void _say(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, style: PopType.of(15, 800, color: Colors.white)),
          backgroundColor: Palette.ink,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          duration: const Duration(seconds: 2),
        ),
      );
  }
}

/// "Unlock Ocean for 300 coins?" or "Buy 5 bombs for 160 coins?", so coins
/// are never spent by accident.
class _Confirm extends StatelessWidget {
  const _Confirm({required this.title, required this.preview, required this.price, required this.action});
  final String title;
  final Widget preview;
  final int price;

  /// The verb on the button: "Unlock" or "Buy".
  final String action;

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
          border: Border.all(color: Palette.edge, width: 1.2),
          boxShadow: const [BoxShadow(color: Color(0x663A2D9E), blurRadius: 30, offset: Offset(0, 12))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(action.toUpperCase(), style: PopType.panelTitle),
            const SizedBox(height: 6),
            Text(title, style: PopType.of(30, 1000, color: Palette.accent)),
            const SizedBox(height: 14),
            preview,
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
            BigButton(
              label: action,
              icon: action == 'Buy' ? Icons.shopping_bag_rounded : Icons.lock_open_rounded,
              onPressed: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: 10),
            SoftButton(label: 'Not now', onPressed: () => Navigator.pop(context, false)),
          ],
        ),
      ),
    );
  }
}
