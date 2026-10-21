# Bubblop

A one-thumb chain-reaction puzzle game for iOS and Android (codename during development: Project POP).
App ID: `com.bubblop.game`.

## Layout
```
app/                 Flutter app (UI, rendering, audio). Platforms: android, ios, windows
packages/pop_core/   Pure-Dart gameplay rules + unit tests (no Flutter imports)
docs/                rules.md, art-direction.md, decisions/, known-bugs.md
```

## Setup (Windows)
- **Windows Developer Mode ON** (Settings → System → For developers). Needed to build
  plugins (audio, storage) for Windows. Android builds work without it.
- Flutter SDK at `C:\dev\flutter` (on the user PATH)
- Visual Studio 2022 with "Desktop development with C++" (for Windows builds)
- Android Studio (Android SDK, emulator, command-line tools)
- VS Code with the Flutter extension

Check with `flutter doctor`.

## Run (in the VS Code terminal)
```powershell
# Gameplay rule tests
cd C:\dev\project_pop\packages\pop_core
dart test

# Balance simulator (compares rule settings over many seeded games)
dart run tool/simulate.dart

# App tests (layout, animation playback matches rules, stats)
cd C:\dev\project_pop\app
flutter test

# Run the game on Windows
flutter run -d windows

# Run on the Android emulator
flutter emulators --launch Medium_Phone_API_37.0
flutter run -d emulator-5554
```
While `flutter run` is active: `r` hot-reloads code changes, `R` restarts, `q` quits.
(Changes to `shaders/ball.frag` need a full restart: press `q` and run again.)

### Developer launch options
```powershell
# Show the developer bar (4/3-match switch, session stats)
flutter run -d windows --dart-define=POP_DEV=true

# Start on a board where the first drop into column 5 sets off a 3-step chain
flutter run -d windows --dart-define=POP_DEMO=chain

# 60-second auto-play benchmark; prints frame-time statistics to the terminal
flutter run -d windows --profile --dart-define=POP_BENCH=60

# Same, with layers turned off to find raster costs (bg, board, fx, orbs, dock, hud)
flutter run -d windows --profile --dart-define=POP_BENCH=30 --dart-define=POP_SKIP=fx,bg
```

### Phone-size screenshots (developer only)
```powershell
# Show the game as a 390x844 phone (47 px top / 34 px bottom safe area) in the window.
# Uses a throwaway save, so your real best score is never touched.
flutter run -d windows --dart-define=POP_PHONE=390x844+47+34

# Play a script and save PNGs to build/shots/ (next to the .exe when run from a build), then quit.
# POP_PLAY=true skips the home screen; POP_SEED=7 deals the same round every time.
flutter run -d windows --dart-define=POP_PHONE=390x844+47+34 --dart-define=POP_PLAY=true `
  --dart-define=POP_SEED=7 "--dart-define=POP_SHOT=wait 2; tap 221 450; wait 1; shot board"
```
Script commands: `wait S`, `tap X Y`, `down X Y`, `up`, `shot NAME`, `burst NAME COUNT SECONDS`
(coordinates in logical pixels inside the phone).

## App structure (`app/lib`)
```
main.dart              app entry, portrait lock, theme
game/pop_game.dart     connects rules to screen: input → rules → event phases; effect triggers
game/board_scene.dart  on-screen board, changed only by playing rule events
game/phase_queue.dart  timed animation steps (fast-forwards on early input)
game/board_component.dart  draws background, board card (baked), balls, dock, effects
game/orb_painter.dart  one ball's animation state (squash, halo, cracks, reveal, boing)
game/board_layout.dart cell ↔ pixel conversion
game/dev_options.dart  POP_DEMO / POP_BENCH / POP_SKIP / POP_SEED / POP_PLAY (developer only)
dev/shot_driver.dart   POP_PHONE / POP_SHOT: phone-size frame and scripted screenshots
game/frame_bench.dart  frame-time measurement for POP_BENCH
render/orb_sprites.dart  bakes shader balls, shells, halos and shadow once per size
render/effects.dart    pooled playful effects (confetti, sparkles, rings, puffs, trails, labels)
render/background.dart bright sky, colour blobs, floating bubbles
shaders/ball.frag      glossy ball and shell bubble material
game/tutorial.dart     the guided first round
services/              settings (saved), sound effects (SoLoud), haptics
ui/                    home screen, HUD, pause menu, hints, banners, game-over panel, debug bar
tools/make_sfx.py      generates every sound effect from scratch (python tools/make_sfx.py)
```
