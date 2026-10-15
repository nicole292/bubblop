import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game/palette.dart';
import 'ui/game_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const PopApp());
}

class PopApp extends StatelessWidget {
  const PopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Project POP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Palette.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Palette.orbs[3],
          brightness: Brightness.dark,
        ),
      ),
      home: const GameScreen(),
    );
  }
}
