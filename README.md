# Project POP

A one-thumb chain-reaction puzzle game for iOS and Android (codename).

## Layout
```
app/                 Flutter app (UI, rendering, audio). Platforms: android, ios, windows
packages/pop_core/   Pure-Dart gameplay rules + unit tests (no Flutter imports)
docs/                rules.md, decisions/, known-bugs.md
```

## Setup (Windows)
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

## App structure (`app/lib`)
```
main.dart              app entry, portrait lock, theme
game/pop_game.dart     connects rules to screen: input → rules → event phases
game/board_scene.dart  on-screen board, changed only by playing rule events
game/phase_queue.dart  timed animation steps (fast-forwards on early input)
game/board_component.dart, orb_painter.dart   drawing (greybox for now)
game/board_layout.dart cell ↔ pixel conversion
game/session_stats.dart shells-vs-stones experiment numbers
ui/                    Flutter HUD, banners, game-over panel, debug bar
```
