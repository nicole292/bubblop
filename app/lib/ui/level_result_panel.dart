import 'package:flutter/material.dart';
import 'package:pop_core/pop_core.dart';

import '../game/hud_state.dart';
import '../game/palette.dart';
import '../progress/achievements.dart';
import '../progress/progress.dart';
import '../progress/rewards.dart';
import 'buttons.dart';
import 'gift_box.dart';
import 'glass.dart';
import 'goal_icon.dart';
import 'type.dart';
import 'undo_button.dart';

/// The end of a level round. A win shows the goals ticked, the coins earned,
/// the gift to open (if any) and Next level; a loss shows how close each
/// goal got, with Try again.
class LevelResultPanel extends StatelessWidget {
  const LevelResultPanel({
    super.key,
    required this.hud,
    required this.onNext,
    required this.onReplay,
    required this.onLevels,
    required this.onGiftOpen,
    this.undoCost,
    this.onUndo,
  });

  /// What taking back the losing move costs (0 = free), or null when it
  /// can't be undone.
  final int? undoCost;
  final VoidCallback? onUndo;

  final HudState hud;
  final VoidCallback onNext;
  final VoidCallback onReplay;
  final VoidCallback onLevels;
  final VoidCallback onGiftOpen;

  @override
  Widget build(BuildContext context) {
    final clear = hud.levelClear;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      builder: (context, t, child) => ColoredBox(
        color: Palette.scrim.withValues(alpha: 0.35 * t.clamp(0.0, 1.0)),
        child: Center(
          child: Transform.scale(
            scale: Curves.easeOutBack.transform(t),
            child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
          ),
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 330),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          decoration: BoxDecoration(
            color: Palette.card,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Palette.edge, width: 1.2),
            boxShadow: const [BoxShadow(color: Color(0x663A2D9E), blurRadius: 30, offset: Offset(0, 12))],
          ),
          child: SingleChildScrollView(
            child: clear != null ? _won(clear) : _lost(),
          ),
        ),
      ),
    );
  }

  Widget _won(LevelClear clear) {
    final last = clear.level >= Campaign.count;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Money at the top, points in the middle: they never sit together.
        if (clear.firstTime) ...[
          _CoinBadge(coins: clear.coins),
          const SizedBox(height: 12),
        ],
        Text('LEVEL ${clear.level}', style: PopType.panelTitle),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('Complete!', style: PopType.of(34, 1000, color: Palette.success)),
        ),
        const SizedBox(height: 12),
        for (final g in hud.goals) ...[
          _GoalResult(view: g),
          const SizedBox(height: 6),
        ],
        const SizedBox(height: 8),
        _Points(score: clear.score, note: clear.newBest
            ? 'New best!'
            : clear.firstTime
                ? null
                : 'Best ${clear.bestScore}'),
        const SizedBox(height: 10),
        if (clear.firstTime) ...[
          if (clear.gift != GiftKind.none && clear.giftContents != null) ...[
            const SizedBox(height: 8),
            GiftBox(
              kind: clear.gift,
              contents: clear.giftContents!,
              duplicateCosmetic: clear.duplicateCosmetic,
              onOpen: onGiftOpen,
            ),
          ],
        ] else
          Text('Rewards already collected', style: PopType.of(13, 800, color: Palette.inkSoft)),
        if (hud.achievements.isNotEmpty) ...[
          const SizedBox(height: 12),
          AchievementChips(achievements: hud.achievements),
        ],
        const SizedBox(height: 18),
        if (!last) ...[
          BigButton(label: 'Next level', icon: Icons.arrow_forward_rounded, onPressed: onNext),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Expanded(child: SoftButton(label: 'Replay', icon: Icons.replay_rounded, onPressed: onReplay)),
            const SizedBox(width: 10),
            Expanded(child: SoftButton(label: 'Levels', icon: Icons.grid_view_rounded, onPressed: onLevels)),
          ],
        ),
      ],
    );
  }

  Widget _lost() {
    final close = hud.goals.every((g) => g.progress >= g.goal.target * 0.75);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('LEVEL ${hud.levelNumber}', style: PopType.panelTitle),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            close
                ? 'So close!'
                : hud.dropsLeft == 0
                    ? 'Out of drops!'
                    : 'Out of room!',
            style: PopType.of(32, 1000, color: Palette.ink),
          ),
        ),
        const SizedBox(height: 14),
        for (final g in hud.goals) ...[
          _GoalResult(view: g, showBar: true),
          const SizedBox(height: 8),
        ],
        if (hud.achievements.isNotEmpty) ...[
          const SizedBox(height: 6),
          AchievementChips(achievements: hud.achievements),
        ],
        const SizedBox(height: 16),
        if (undoCost case final cost? when onUndo != null) ...[
          UndoPill(cost: cost, onPressed: onUndo!),
          const SizedBox(height: 10),
        ],
        BigButton(label: 'Try again', icon: Icons.replay_rounded, onPressed: onReplay),
        const SizedBox(height: 10),
        SoftButton(label: 'Levels', icon: Icons.grid_view_rounded, onPressed: onLevels),
      ],
    );
  }
}

class _GoalResult extends StatelessWidget {
  const _GoalResult({required this.view, this.showBar = false});
  final GoalView view;
  final bool showBar;

  @override
  Widget build(BuildContext context) {
    final goal = view.goal;
    final fraction = (view.progress / goal.target).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
      decoration: BoxDecoration(color: Palette.well, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Row(
            children: [
              view.met
                  ? Icon(Icons.check_circle_rounded, size: 24, color: Palette.success)
                  : GoalIcon(kind: goal.kind, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(goal.text, style: PopType.of(15, 900)),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                goalCount(goal, view.progress),
                style: PopType.of(15, 900, color: view.met ? Palette.success : Palette.inkSoft, numbers: true),
              ),
            ],
          ),
          if (showBar) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 8,
                backgroundColor: Palette.pipEmpty,
                color: view.met ? Palette.success : Palette.accent,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Small gold chips for achievements unlocked this round.
class AchievementChips extends StatelessWidget {
  const AchievementChips({super.key, required this.achievements});
  final List<Achievement> achievements;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final a in achievements)
          Container(
            padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
            decoration: BoxDecoration(
              color: Palette.cream,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Palette.gold, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events_rounded, size: 18, color: Palette.gold),
                const SizedBox(width: 5),
                Text(a.title, style: PopType.of(13, 900)),
                const SizedBox(width: 6),
                const CoinIcon(size: 16),
                const SizedBox(width: 3),
                Text('+${a.coins}', style: PopType.of(13, 900, numbers: true)),
              ],
            ),
          ),
      ],
    );
  }
}

/// The coins a level paid, as a gold badge at the top of the card.
class _CoinBadge extends StatelessWidget {
  const _CoinBadge({required this.coins});
  final int coins;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, s, child) => Transform.scale(scale: s, child: child),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 5, 16, 5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFFF3C4), Color(0xFFFFE08A)]),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFF0A000), width: 2),
          boxShadow: const [BoxShadow(color: Color(0x40F0A000), blurRadius: 10, offset: Offset(0, 3))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CoinIcon(size: 28),
            const SizedBox(width: 6),
            Text('+$coins coins', style: PopType.of(19, 1000, color: const Color(0xFF7A4A00), numbers: true)),
          ],
        ),
      ),
    );
  }
}

/// The level's points, big in the middle of the card, with a star (stars
/// always mean points).
class _Points extends StatelessWidget {
  const _Points({required this.score, this.note});
  final int score;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, size: 34, color: Palette.gold),
            const SizedBox(width: 4),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: score.toDouble()),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => Text('${v.round()}', style: PopType.of(40, 1000, numbers: true)),
            ),
          ],
        ),
        Text(note == null ? 'POINTS' : 'POINTS  ·  ${note!.toUpperCase()}',
            style: PopType.of(12, 900, color: Palette.inkSoft, spacing: 1.5)),
      ],
    );
  }
}
