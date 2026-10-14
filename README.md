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

# Run the game on Windows
cd C:\dev\project_pop\app
flutter run -d windows
```
