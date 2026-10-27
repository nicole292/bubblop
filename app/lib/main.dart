import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dev/shot_driver.dart';
import 'game/dev_options.dart';
import 'game/palette.dart';
import 'progress/cosmetics.dart';
import 'progress/progress.dart';
import 'services/haptics.dart';
import 'services/settings.dart';
import 'services/sfx.dart';
import 'ui/game_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Phone-frame test runs never touch the player's saved progress.
  final settings = DevPhone.enabled ? (Settings.memory()..tutorialDone = true) : await Settings.load();
  final progress = DevPhone.enabled ? Progress.memory() : await Progress.load();
  if (DevPhone.enabled) {
    for (var level = 1; level <= DevOptions.progressLevels; level++) {
      progress.completeLevel(level, score: 1000);
    }
    for (final id in DevOptions.style.split(',')) {
      final cosmetic = Cosmetics.byId(id);
      if (cosmetic == null) continue;
      progress.buy(cosmetic);
      progress.select(cosmetic);
    }
  }
  // The chosen ball set, shape and sky style everything from the first frame.
  Palette.apply(balls: progress.balls, shape: progress.shape, sky: progress.sky);
  final sfx = Sfx(settings);
  await sfx.init();
  final app = PopApp(settings: settings, progress: progress, sfx: sfx, haptics: Haptics(settings));
  runApp(DevPhone.enabled ? DevPhone(child: app) : app);
}

class PopApp extends StatelessWidget {
  const PopApp({super.key, required this.settings, required this.progress, required this.sfx, required this.haptics});

  final Settings settings;
  final Progress progress;
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
      home: GameScreen(settings: settings, progress: progress, sfx: sfx, haptics: haptics),
    );
  }
}
