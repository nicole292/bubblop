import 'package:flutter/material.dart';

import '../game/palette.dart';
import '../services/settings.dart';
import 'buttons.dart';
import 'type.dart';

/// Pause card: resume, restart, settings, how to play, home.
class PauseMenu extends StatelessWidget {
  const PauseMenu({
    super.key,
    required this.settings,
    required this.onResume,
    required this.onRestart,
    required this.onHowToPlay,
    required this.onHome,
  });

  final Settings settings;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onHowToPlay;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Palette.ink.withValues(alpha: 0.4),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.85, end: 1),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutBack,
          builder: (context, s, child) => Transform.scale(scale: s, child: child),
          child: Container(
            width: 310,
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            decoration: BoxDecoration(
              color: Palette.card,
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [BoxShadow(color: Color(0x663A2D9E), blurRadius: 30, offset: Offset(0, 12))],
            ),
            child: ListenableBuilder(
              listenable: settings,
              builder: (context, _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('PAUSED', style: PopType.panelTitle),
                  const SizedBox(height: 16),
                  BigButton(label: 'Resume', icon: Icons.play_arrow_rounded, onPressed: onResume),
                  const SizedBox(height: 12),
                  ToggleRow(
                    icon: Icons.volume_up_rounded,
                    label: 'Sound',
                    value: settings.sound,
                    onChanged: (v) => settings.sound = v,
                  ),
                  ToggleRow(
                    icon: Icons.vibration_rounded,
                    label: 'Vibration',
                    value: settings.haptics,
                    onChanged: (v) => settings.haptics = v,
                  ),
                  ToggleRow(
                    icon: Icons.category_rounded,
                    label: 'Ball shapes',
                    value: settings.shapes,
                    onChanged: (v) => settings.shapes = v,
                  ),
                  const SizedBox(height: 10),
                  SoftButton(label: 'Restart', icon: Icons.refresh_rounded, onPressed: onRestart),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: SoftButton(label: 'How to play', onPressed: onHowToPlay)),
                      const SizedBox(width: 10),
                      Expanded(child: SoftButton(label: 'Home', icon: Icons.home_rounded, onPressed: onHome)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
