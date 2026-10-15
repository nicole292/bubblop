# Known bugs and limitations

## Open
- **Shell colours are hard to tell apart** (blue/green shells look nearly identical in the
  greybox). Readable shell colours are essential to the shells mechanic. Fix in Stage 3.
- **Ghost/landing ring uses the rules board**, which can be one move ahead of the animation
  when the player taps mid-chain. Only visible during fast-forwarded animation.
- Large empty gap between HUD and board on tall phones (layout not yet tuned).

## Prototype limitations (by design, for now)
- Greybox art and no sound or haptics (Stage 3).
- Session stats and best score are not saved between launches (Stage 4).
- Debug bar (mode switches, stats) is visible to players; remove before release.
- iOS has not been built or run (needs cloud CI or a Mac; Stage 6).

## Verified 2026-10-15
- Windows desktop: drop, pop, crack, rising rows, restart (mouse input).
- Android emulator (API 37, 1080×2400): tap and drag input, rising rows, safe area.
