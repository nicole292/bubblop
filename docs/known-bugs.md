# Known bugs and limitations

## Open
- **Ghost/landing ring uses the rules board**, which can be one move ahead of the animation
  when the player taps mid-chain. Only visible during fast-forwarded animation.
- On short or wide screens the board is limited by height and gets side margins
  (by design, but worth reviewing on real phones).
- Score text can be wider than its space if a score passes ~10 million (not reachable yet).

## Fixed (2026-10-15)
- Shell colours hard to tell apart: shells now have a saturated core and a bold symbol.
- Large gap between the HUD and the board on tall phones: the HUD now sits on the board.
- HUD text overflow with Sora: the HUD now sizes itself to its content.

## Prototype limitations (by design, for now)
- No sound or haptics yet.
- Session stats and best score are not saved between launches (Stage 4).
- Debug bar (mode switches, stats) is visible to players; remove before release.
- iOS has not been built or run (needs cloud CI or a Mac; Stage 6).

## Verified 2026-10-15
- Windows desktop (430×900 window, 150% scaling): drop, pop effects, shell crack, rising
  rows, rejected drops into full columns, game-over panel, restart.
- Android emulator (API 37, 1080×2400): layout, tap and drag-to-aim, next-row tray.
