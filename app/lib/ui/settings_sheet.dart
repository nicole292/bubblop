import 'package:flutter/material.dart';

import '../game/palette.dart';
import '../services/settings.dart';
import 'buttons.dart';
import 'type.dart';

/// All the switches in one small card, opened from the gear on the home
/// screen: sound, music, vibration, faces and light or dark.
Future<void> showSettingsSheet(BuildContext context, Settings settings) => showDialog<void>(
      context: context,
      barrierColor: Palette.scrim.withValues(alpha: 0.4),
      builder: (context) => _SettingsSheet(settings: settings),
    );

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet({required this.settings});
  final Settings settings;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 310,
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
        decoration: BoxDecoration(
          color: Palette.card,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Palette.edge, width: 1.2),
          boxShadow: const [BoxShadow(color: Color(0x663A2D9E), blurRadius: 30, offset: Offset(0, 12))],
        ),
        child: ListenableBuilder(
          listenable: settings,
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('SETTINGS', style: PopType.panelTitle),
              const SizedBox(height: 12),
              ToggleRow(
                icon: Icons.volume_up_rounded,
                label: 'Sound',
                value: settings.sound,
                onChanged: (v) => settings.sound = v,
              ),
              ToggleRow(
                icon: Icons.music_note_rounded,
                label: 'Music',
                value: settings.music,
                onChanged: (v) => settings.music = v,
              ),
              ToggleRow(
                icon: Icons.vibration_rounded,
                label: 'Vibration',
                value: settings.haptics,
                onChanged: (v) => settings.haptics = v,
              ),
              ToggleRow(
                icon: Icons.emoji_emotions_rounded,
                label: 'Faces',
                value: settings.faces,
                onChanged: (v) => settings.faces = v,
              ),
              ThemeRow(value: settings.theme, onChanged: (v) => settings.theme = v),
              const SizedBox(height: 14),
              BigButton(label: 'Done', icon: Icons.check_rounded, onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    );
  }
}
