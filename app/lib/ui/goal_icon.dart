import 'package:flutter/material.dart';
import 'package:pop_core/pop_core.dart';

import '../game/palette.dart';

/// One icon per goal type, used on the level card, the header and results:
/// a star for points, a ball for popping, linked rings for a chain, bubbles
/// for cracking shells.
class GoalIcon extends StatelessWidget {
  const GoalIcon({super.key, required this.kind, this.size = 20});
  final GoalKind kind;
  final double size;

  @override
  Widget build(BuildContext context) => switch (kind) {
        GoalKind.score => Icon(Icons.star_rounded, size: size, color: Palette.gold),
        GoalKind.pop => Icon(Icons.circle, size: size * 0.82, color: Palette.balls[3]),
        GoalKind.chain => Icon(Icons.link_rounded, size: size, color: Palette.accent),
        GoalKind.crack => Icon(Icons.bubble_chart_rounded, size: size, color: Palette.balls[2]),
      };
}

/// Progress as a short count: "23/40", or "×2/×3" for a chain.
String goalCount(LevelGoal goal, int progress) => switch (goal.kind) {
      GoalKind.chain => '${progress <= 1 ? '–' : '×$progress'}/×${goal.target}',
      _ => '$progress/${goal.target}',
    };
