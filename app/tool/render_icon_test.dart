// Renders the app icon images with the game's own ball shader.
//
//   cd app
//   flutter test tool/render_icon_test.dart
//
// Writes to app/assets/icon/:
//   icon.png             1024² full icon (iOS, Windows, store listing)
//   icon_foreground.png  1024² transparent balls only (Android adaptive icon)
//   icon_background.png  1024² sky gradient only (Android adaptive icon)
//
// Then: dart run flutter_launcher_icons

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:project_pop/game/palette.dart';
import 'package:project_pop/render/orb_sprites.dart';

const size = 1024.0;

void main() {
  testWidgets('render app icon', (tester) async {
    await tester.runAsync(() async {
      final program = await OrbSprites.loadProgram();
      // Large sprites so the icon is crisp at 1024 px.
      final sprites = OrbSprites.bake(200, 1, program);
      final dir = Directory('assets/icon')..createSync(recursive: true);

      Future<void> save(String name, void Function(Canvas) paint) async {
        final recorder = PictureRecorder();
        paint(Canvas(recorder));
        final image = await recorder.endRecording().toImage(size.toInt(), size.toInt());
        final bytes = await image.toByteData(format: ImageByteFormat.png);
        File('${dir.path}/$name').writeAsBytesSync(bytes!.buffer.asUint8List());
      }

      await save('icon_background.png', _background);
      await save('icon_foreground.png', (c) => _foreground(c, sprites, scale: 0.86));
      await save('icon.png', (c) {
        _background(c);
        _foreground(c, sprites, scale: 1.0);
      });
      // ignore: avoid_print
      print('Icons written to ${dir.absolute.path} (shader: ${sprites.usesShader})');
    });
  });
}

void _background(Canvas canvas) {
  final rect = const Offset(0, 0) & const Size(size, size);
  canvas.drawRect(
    rect,
    Paint()
      ..shader = Gradient.linear(Offset.zero, const Offset(size * 0.4, size),
          [Palette.skyTop, Palette.skyMid, Palette.skyBottom], const [0, 0.5, 1]),
  );
  // A soft light patch top-left and a warm one bottom-right.
  for (final (c, r, color) in const [
    (Offset(size * 0.15, size * 0.12), size * 0.6, Color(0x55FFFFFF)),
    (Offset(size * 0.95, size * 0.95), size * 0.55, Color(0x40FF8FD1)),
  ]) {
    canvas.drawCircle(c, r, Paint()..shader = Gradient.radial(c, r, [color, color.withValues(alpha: 0)]));
  }
}

/// Three big balls in a tight cluster, with confetti and a sparkle: "pop".
/// [scale] shrinks the art into the Android adaptive-icon safe zone.
void _foreground(Canvas canvas, OrbSprites sprites, {required double scale}) {
  canvas.save();
  canvas.translate(size / 2, size / 2);
  canvas.scale(scale);
  canvas.translate(-size / 2, -size / 2);

  final r = sprites.radius; // 200 px
  // A resting pyramid: two balls side by side, one sitting in the groove.
  final balls = [
    (const Offset(size * 0.315, size * 0.655), 0), // cherry, lower left
    (const Offset(size * 0.685, size * 0.655), 3), // blue, lower right
    (const Offset(size * 0.50, size * 0.335), 1), // sunflower, top
  ];
  // Soft shadow under the cluster.
  canvas.drawOval(
    Rect.fromCenter(center: const Offset(size * 0.5, size * 0.84), width: size * 0.62, height: size * 0.09),
    Paint()
      ..color = const Color(0x403A2D9E)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
  );
  for (final (c, color) in balls) {
    sprites.draw(canvas, sprites.ball(color), c, sx: 0.92, sy: 0.92);
  }

  // Confetti bursting off the top ball.
  final confetti = Paint();
  final rnd = math.Random(11);
  for (var i = 0; i < 9; i++) {
    final a = -math.pi * (0.08 + 0.84 * i / 8) + (rnd.nextDouble() - 0.5) * 0.35;
    final dist = r * (1.25 + rnd.nextDouble() * 0.6);
    final p = const Offset(size * 0.5, size * 0.335) + Offset(math.cos(a), math.sin(a)) * dist;
    confetti.color = [Palette.balls[2], Palette.balls[4], Colors.white, Palette.balls[0]][i % 4];
    canvas.save();
    canvas.translate(p.dx, p.dy);
    canvas.rotate(a + rnd.nextDouble() * 2);
    if (i.isEven) {
      canvas.drawCircle(Offset.zero, 18, confetti);
    } else {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 52, height: 24), const Radius.circular(10)), confetti);
    }
    canvas.restore();
  }

  // A gold sparkle.
  final star = Path();
  for (var i = 0; i < 8; i++) {
    final a = -math.pi / 2 + i * math.pi / 4;
    final rr = i.isEven ? 62.0 : 18.0;
    final p = Offset(size * 0.82 + math.cos(a) * rr, size * 0.20 + math.sin(a) * rr);
    i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
  }
  canvas.drawPath(star..close(), Paint()..color = Palette.gold);
  canvas.restore();
}

class Colors {
  static const white = Color(0xFFFFFFFF);
}
