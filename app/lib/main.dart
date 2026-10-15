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
        brightness: Brightness.light,
        fontFamily: 'Nunito',
        scaffoldBackgroundColor: Palette.skyTop,
        colorScheme: ColorScheme.fromSeed(seedColor: Palette.accent),
      ),
      home: const GameScreen(),
    );
  }
}
