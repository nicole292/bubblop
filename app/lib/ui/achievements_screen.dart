import 'package:flutter/material.dart';

import '../game/palette.dart';
import '../progress/achievements.dart';
import '../progress/progress.dart';
import 'glass.dart';
import 'type.dart';

/// A short list of milestones with their progress and coin rewards. Coins
/// are paid automatically the moment an achievement unlocks.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key, required this.progress, required this.onBack});

  final Progress progress;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final earned = Achievements.all.where((a) => progress.hasAchievement(a.id)).length;
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
                    child: Column(
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Achievements', style: PopType.of(24, 1000, color: Colors.white)),
                        ),
                        Text('$earned of ${Achievements.all.length} earned',
                            style: PopType.of(13, 800, color: const Color(0xD9FFFFFF))),
                      ],
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
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                    children: [
                      for (final a in Achievements.all) ...[
                        _AchievementCard(achievement: a, progress: progress),
                        const SizedBox(height: 12),
                      ],
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
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement, required this.progress});
  final Achievement achievement;
  final Progress progress;

  @override
  Widget build(BuildContext context) {
    final done = progress.hasAchievement(achievement.id);
    final (have, need) = progress.achievementProgress(achievement);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Palette.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: Palette.panelShadow, blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: done
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFFFD45C), Palette.gold],
                    )
                  : null,
              color: done ? null : Palette.well,
            ),
            child: Icon(
              done ? Icons.emoji_events_rounded : Icons.lock_outline_rounded,
              size: 28,
              color: done ? Colors.white : Palette.inkSoft,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(achievement.title, style: PopType.of(17, 1000)),
                const SizedBox(height: 2),
                Text(achievement.description, style: PopType.of(13, 700, color: Palette.inkSoft)),
                if (need > 1 && !done) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: have / need,
                            minHeight: 7,
                            backgroundColor: Palette.pipEmpty,
                            color: Palette.accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('$have/$need', style: PopType.of(12, 900, color: Palette.inkSoft, numbers: true)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          done
              ? const Icon(Icons.check_circle_rounded, size: 28, color: Palette.success)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CoinIcon(size: 20),
                    const SizedBox(width: 4),
                    Text('${achievement.coins}', style: PopType.of(15, 900, numbers: true)),
                  ],
                ),
        ],
      ),
    );
  }
}
