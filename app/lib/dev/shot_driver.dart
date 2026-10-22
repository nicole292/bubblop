import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../game/dev_options.dart';

/// Developer-only: shows the app at a phone's size and safe areas inside the
/// desktop window, and can play a script of taps and screenshots.
///
///   flutter run -d windows --dart-define=POP_PHONE=390x844+47+34
///     A 390×844 phone with a 47 px top and 34 px bottom safe area.
///
///   --dart-define=POP_SHOT="wait 2; shot home; tap 195 700; wait 1; shot board"
///     Plays the script, saves PNGs to build/shots/ and quits.
///     Commands: `wait S` · `tap X Y` · `down X Y` · `up` · `shot NAME` ·
///     `burst NAME COUNT SECONDS_APART`
///     Coordinates are logical pixels inside the phone.
///
///   --dart-define=POP_SHOT_SCALE=3  saves at 3× (default 2), e.g. 440x956 → 1320×2868.
class DevPhone extends StatefulWidget {
  const DevPhone({super.key, required this.child});

  static const _phone = String.fromEnvironment('POP_PHONE');
  static const _script = String.fromEnvironment('POP_SHOT');

  static bool get enabled => _phone.isNotEmpty;

  final Widget child;

  @override
  State<DevPhone> createState() => _DevPhoneState();
}

class _DevPhoneState extends State<DevPhone> {
  final _key = GlobalKey();
  late final Size _size;
  late final EdgeInsets _safe;
  int _pointer = 9000;
  Offset? _held;

  @override
  void initState() {
    super.initState();
    // "390x844+47+34": width x height + top inset + bottom inset.
    final m = RegExp(r'(\d+)x(\d+)(?:\+(\d+)\+(\d+))?').firstMatch(DevPhone._phone)!;
    _size = Size(double.parse(m[1]!), double.parse(m[2]!));
    _safe = EdgeInsets.only(top: double.parse(m[3] ?? '0'), bottom: double.parse(m[4] ?? '0'));
    if (DevPhone._script.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _run(DevPhone._script));
    }
  }

  Future<void> _run(String script) async {
    final dir = Directory('build/shots')..createSync(recursive: true);
    for (final line in script.split(';')) {
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.first.isEmpty) continue;
      switch (parts.first) {
        case 'wait':
          await _wait(double.parse(parts[1]));
        case 'tap':
          await _tap(Offset(double.parse(parts[1]), double.parse(parts[2])));
        case 'down':
          _held = _global(Offset(double.parse(parts[1]), double.parse(parts[2])));
          GestureBinding.instance.handlePointerEvent(PointerDownEvent(pointer: ++_pointer, position: _held!));
        case 'up':
          GestureBinding.instance.handlePointerEvent(PointerUpEvent(pointer: _pointer, position: _held!));
        case 'shot':
          await _shot(dir, parts[1]);
        case 'burst':
          final count = int.parse(parts[2]);
          final gap = double.parse(parts[3]);
          for (var i = 0; i < count; i++) {
            await _shot(dir, '${parts[1]}_${i.toString().padLeft(2, '0')}');
            await _wait(gap);
          }
      }
    }
    debugPrint('Shots saved to ${dir.absolute.path}');
    // Stop the audio engine first: exiting with it running hangs on Windows.
    if (SoLoud.instance.isInitialized) SoLoud.instance.deinit();
    exit(0);
  }

  Future<void> _wait(double seconds) => Future.delayed(Duration(milliseconds: (seconds * 1000).round()));

  Offset _global(Offset local) => (_key.currentContext!.findRenderObject() as RenderBox).localToGlobal(local);

  Future<void> _tap(Offset local) async {
    final at = _global(local);
    final id = _pointer++;
    final binding = GestureBinding.instance;
    binding.handlePointerEvent(PointerDownEvent(pointer: id, position: at));
    await _wait(0.05);
    binding.handlePointerEvent(PointerUpEvent(pointer: id, position: at));
  }

  Future<void> _shot(Directory dir, String name) async {
    final boundary = _key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: DevOptions.shotScale.toDouble());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    File('${dir.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return ColoredBox(
      color: const Color(0xFF202020),
      child: Center(
        child: FittedBox(
          child: SizedBox.fromSize(
            size: _size,
            child: MediaQuery(
              data: media.copyWith(size: _size, padding: _safe, viewPadding: _safe),
              child: RepaintBoundary(key: _key, child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}
