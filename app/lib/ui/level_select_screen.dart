import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pop_core/pop_core.dart';

import '../game/palette.dart';
import '../progress/progress.dart';
import '../progress/rewards.dart';
import 'buttons.dart';
import 'glass.dart';
import 'goal_icon.dart';
import 'type.dart';

/// The level map: 30 numbered bubbles in three groups of ten. Completed
/// levels are filled with a ball colour and ticked, the next one glows,
/// locked ones are frosted glass. Gift badges mark every third level and
/// the special gifts at 10, 20 and 30. Tapping a level opens its goal card.
class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({
    super.key,
    required this.progress,
    required this.onBack,
    required this.onPlay,
    required this.onTap,
    required this.onDeny,
    this.openLevel,
  });

  final Progress progress;
  final VoidCallback onBack;
  final ValueChanged<LevelDef> onPlay;
  final VoidCallback onTap;
  final VoidCallback onDeny;

  /// A level whose goal card opens straight away (after "Next level").
  final int? openLevel;

  @override
  State<LevelSelectScreen> createState() => LevelSelectScreenState();
}

class LevelSelectScreenState extends State<LevelSelectScreen> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  final _currentKey = GlobalKey();
  late int? _open = widget.openLevel;

  @override
  void initState() {
    super.initState();
    // Start with the next level to play in view.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _currentKey.currentContext;
      if (context != null) Scrollable.ensureVisible(context, alignment: 0.4);
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  /// Back while a goal card is open closes the card. Returns false when
  /// there was none (then back leaves the map).
  bool closeIntro() {
    if (_open == null) return false;
    widget.onTap();
    setState(() => _open = null);
    return true;
  }

  void _tapLevel(int level) {
    if (!widget.progress.isUnlocked(level)) {
      widget.onDeny();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('Complete level ${widget.progress.unlockedLevel} to unlock the next one!',
              style: PopType.of(15, 800, color: Colors.white)),
          backgroundColor: Palette.ink,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          duration: const Duration(seconds: 2),
        ));
      return;
    }
    widget.onTap();
    setState(() => _open = level);
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.progress;
    return SkyGradient(
      child: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(
                    children: [
                      GlassBackButton(onPressed: widget.onBack),
                      Expanded(
                        child: Column(
                          children: [
                            Text('Levels', style: PopType.of(26, 1000, color: Colors.white)),
                            Text(
                              '${progress.completedCount} of ${Campaign.count} complete',
                              style: PopType.of(13, 800, color: const Color(0xD9FFFFFF)),
                            ),
                          ],
                        ),
                      ),
                      CoinChip(coins: progress.coins),
                    ],
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final width = math.min(constraints.maxWidth, 460.0);
                      // Five per row inside a group card: page padding 2×16,
                      // card padding 2×14 and its border, four gaps, and slack.
                      final node = ((width - 32 - 28 - 4 * _gap - 8) / 5).clamp(44.0, 72.0);
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                        child: Center(
                          child: SizedBox(
                            width: width - 32,
                            child: Column(
                              children: [
                                for (var chapter = 0; chapter < Campaign.count ~/ 10; chapter++)
                                  _chapter(chapter, node),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_open != null)
            LevelIntro(
              level: Campaign.level(_open!),
              progress: progress,
              onPlay: () => widget.onPlay(Campaign.level(_open!)),
              onClose: () {
                widget.onTap();
                setState(() => _open = null);
              },
            ),
        ],
      ),
    );
  }

  static const _gap = 12.0;

  Widget _chapter(int chapter, double node) {
    final first = chapter * 10 + 1;
    final last = first + 9;
    final done = [for (var l = first; l <= last; l++) widget.progress.isCompleted(l)].where((c) => c).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
        decoration: glass(28),
        child: Column(
          children: [
            Row(
              children: [
                Text('Levels $first–$last', style: PopType.of(15, 900, color: Colors.white)),
                const Spacer(),
                Text('$done/10', style: PopType.of(14, 900, color: const Color(0xD9FFFFFF), numbers: true)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: _gap,
              runSpacing: _gap,
              alignment: WrapAlignment.center,
              children: [
                for (var level = first; level <= last; level++)
                  _LevelNode(
                    key: level == widget.progress.currentLevel ? _currentKey : null,
                    level: level,
                    size: node,
                    progress: widget.progress,
                    pulse: _pulse,
                    onTap: () => _tapLevel(level),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({
    super.key,
    required this.level,
    required this.size,
    required this.progress,
    required this.pulse,
    required this.onTap,
  });

  final int level;
  final double size;
  final Progress progress;
  final Animation<double> pulse;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final completed = progress.isCompleted(level);
    final unlocked = progress.isUnlocked(level);
    final current = unlocked && !completed;
    final color = Palette.balls[(level - 1) % Palette.balls.length];
    final gift = LevelRewards.forLevel(level).gift;

    Widget face;
    if (completed) {
      face = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.35, -0.45),
            radius: 0.95,
            colors: [Color.lerp(color, Colors.white, 0.35)!, color],
          ),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        alignment: Alignment.center,
        child: Text('$level', style: PopType.of(size * 0.38, 1000, color: Colors.white, numbers: true)),
      );
    } else if (current) {
      face = AnimatedBuilder(
        animation: pulse,
        builder: (context, child) {
          final t = pulse.value;
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.7 * (1 - t)),
                  blurRadius: 4,
                  spreadRadius: size * 0.22 * t,
                ),
                const BoxShadow(color: Palette.panelShadow, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            alignment: Alignment.center,
            child: child,
          );
        },
        child: Text('$level', style: PopType.of(size * 0.4, 1000, color: Palette.accent, numbers: true)),
      );
    } else {
      face = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0x26FFFFFF),
          border: Border.all(color: const Color(0x66FFFFFF), width: 1.5),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_rounded, size: size * 0.26, color: const Color(0xB3FFFFFF)),
            Text('$level', style: PopType.of(size * 0.22, 900, color: const Color(0xB3FFFFFF), numbers: true)),
          ],
        ),
      );
    }

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: 'Level $level${completed ? ', completed' : unlocked ? '' : ', locked'}',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: face),
              if (completed)
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: _Badge(size: size * 0.36, color: Palette.success, icon: Icons.check_rounded),
                ),
              if (gift != GiftKind.none)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Opacity(
                    opacity: completed ? 0.55 : 1,
                    child: _Badge(
                      size: gift == GiftKind.special ? size * 0.46 : size * 0.36,
                      color: gift == GiftKind.special ? Palette.accent : Palette.gold,
                      icon: gift == GiftKind.special ? Icons.auto_awesome_rounded : Icons.card_giftcard_rounded,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.size, required this.color, required this.icon});
  final double size;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [BoxShadow(color: Palette.panelShadow, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Icon(icon, size: size * 0.62, color: Colors.white),
      );
}

/// The goal card shown before a level starts: what to do, what you'll get,
/// and one big Play button.
class LevelIntro extends StatelessWidget {
  const LevelIntro({
    super.key,
    required this.level,
    required this.progress,
    required this.onPlay,
    required this.onClose,
  });

  final LevelDef level;
  final Progress progress;
  final VoidCallback onPlay;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final rewards = LevelRewards.forLevel(level.number);
    final completed = progress.isCompleted(level.number);
    return GestureDetector(
      onTap: onClose,
      child: ColoredBox(
        color: Palette.ink.withValues(alpha: 0.4),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.85, end: 1),
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              builder: (context, s, child) => Transform.scale(scale: s, child: child),
              child: Container(
                width: 320,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
                decoration: BoxDecoration(
                  color: Palette.card,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [BoxShadow(color: Color(0x663A2D9E), blurRadius: 30, offset: Offset(0, 12))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        tooltip: 'Close',
                        onPressed: onClose,
                        icon: const Icon(Icons.close_rounded, color: Palette.inkSoft),
                      ),
                    ),
                    Text('LEVEL', style: PopType.panelTitle),
                    Text('${level.number}', style: PopType.of(52, 1000, color: Palette.accent, numbers: true)),
                    const SizedBox(height: 12),
                    for (final goal in level.goals) ...[
                      _GoalRow(goal: goal),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 8),
                    _RewardRow(rewards: rewards, completed: completed, best: progress.bestScore(level.number)),
                    const SizedBox(height: 18),
                    BigButton(
                      label: completed ? 'Play again' : 'Play',
                      icon: Icons.play_arrow_rounded,
                      onPressed: onPlay,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.goal});
  final LevelGoal goal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: Palette.well, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          GoalIcon(kind: goal.kind, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(goal.text, style: PopType.of(18, 900)),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({required this.rewards, required this.completed, required this.best});
  final LevelRewards rewards;
  final bool completed;
  final int? best;

  @override
  // Shrinks to fit rather than overflow with long numbers or large text.
  Widget build(BuildContext context) => FittedBox(fit: BoxFit.scaleDown, child: _row());

  Widget _row() {
    if (completed) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded, size: 18, color: Palette.success),
          const SizedBox(width: 6),
          Text('Completed', style: PopType.of(15, 900, color: Palette.success)),
          if (best != null) ...[
            const SizedBox(width: 10),
            Text('Best $best', style: PopType.of(15, 800, color: Palette.inkSoft, numbers: true)),
          ],
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('REWARD', style: PopType.label),
        const SizedBox(width: 10),
        const CoinIcon(size: 22),
        const SizedBox(width: 4),
        Text('${rewards.coins}', style: PopType.of(17, 900, numbers: true)),
        if (rewards.gift != GiftKind.none) ...[
          const SizedBox(width: 12),
          Icon(
            rewards.gift == GiftKind.special ? Icons.auto_awesome_rounded : Icons.card_giftcard_rounded,
            size: 20,
            color: rewards.gift == GiftKind.special ? Palette.accent : Palette.gold,
          ),
          const SizedBox(width: 4),
          Text(
            rewards.gift == GiftKind.special ? 'Special gift' : 'Gift box',
            style: PopType.of(15, 900, color: rewards.gift == GiftKind.special ? Palette.accent : Palette.ink),
          ),
        ],
      ],
    );
  }
}
