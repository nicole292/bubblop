# 0001 — Flutter + Flame, with gameplay rules in a pure-Dart package

Date: 2026-10-15 · Status: accepted

## Context
Project POP is a 2D grid puzzle for iOS and Android, built in VS Code with Claude
by a developer who is learning. The work is mostly deterministic rules, polished UI,
and timed animation. Development happens on Windows; there is no Mac yet.

## Decision
- **Flutter (Dart) + Flame** for the app. Flutter for menus/UI, Flame for the board.
- **`packages/pop_core`** holds every gameplay rule as pure Dart with no Flutter import.
  `applyDrop(state, column)` returns the new state plus a list of events; the app only
  animates those events.
- Iterate as a Windows desktop app; verify Android on an emulator or phone; verify iOS
  through cloud CI (Codemagic) until a Mac is justified.

## Consequences
- Rules are fast to unit-test and can never be changed by animation code.
- Everything is text, so it is easy to review in VS Code.
- Particles and orb materials are written in code and shaders rather than in a visual editor.
- iOS-specific issues surface later unless the cloud iOS build runs regularly.
