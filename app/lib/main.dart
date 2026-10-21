import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dev/shot_driver.dart';
import 'game/palette.dart';
import 'services/haptics.dart';
import 'services/settings.dart';
import 'services/sfx.dart';
import 'ui/game_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Phone-frame test runs never touch the player's saved progress.
  final settings = DevPhone.enabled ? (Settings.memory()..tutorialDone = true) : await Settings.load();
  final sfx = Sfx(settings);
  await sfx.init();
  final app = PopApp(settings: settings, sfx: sfx, haptics: Haptics(settings));
  runApp(DevPhone.enabled ? DevPhone(child: app) : app);
}

class PopApp extends StatelessWidget {
  const PopApp({super.key, required this.settings, required this.sfx, required this.haptics});

  final Settings settings;
  final Sfx sfx;
  final Haptics haptics;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bubblop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: 'Nunito',
        scaffoldBackgroundColor: Palette.skyTop,
        colorScheme: ColorScheme.fromSeed(seedColor: Palette.accent),
      ),
      home: GameScreen(settings: settings, sfx: sfx, haptics: haptics),
    );
  }
}
