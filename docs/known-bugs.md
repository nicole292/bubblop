# Known bugs and limitations

## Open
- **Rare frame spikes (47–77 ms)**: 1–2 per 60-second benchmark on Windows. Cause not
  identified yet (possibly shader warm-up or garbage collection).
- **Performance not measured on a phone.** The numbers below are from the Windows PC's
  integrated GPU. The emulator only runs debug builds, which don't give meaningful timings.
- **Ghost/landing ring uses the rules board**, which can be one move ahead of the animation
  when the player taps mid-chain. Only visible during fast-forwarded animation.
- On short or wide screens the board is limited by height and gets side margins.
- Score text can be wider than its panel above ~10 million (not reachable yet).

## Fixed (2026-10-15, visual redesign)
- HUD orb icons drawn as vector graphics cost ~8 ms of raster time per frame; they now use
  the baked sprites.
- After aiming once, the board bezel and well faded out: a shared paint's alpha was fading
  later gradient fills. Solid and shader paints are now separate.
- A pre-filled board (chain demo) was invisible until orbs moved: the scene now loads the
  starting board.
- A 3-colour gradient without stops threw during paint and cut every frame short.

## Prototype limitations (by design, for now)
- No sound or haptics yet.
- Session stats and best score are not saved between launches (Stage 4).
- Debug bar (4/3-match switch, stats) is visible to players; remove before release.
- iOS has not been built or run (needs cloud CI or a Mac; Stage 6).

## Performance: measured 2026-10-15
Windows 11, Intel UHD Graphics 770 (integrated; the display is not on the RTX 4060),
profile build, window 430×900 at 150% scaling. 60 s auto-play benchmark
(`--profile --dart-define=POP_BENCH=60`): drops every 0.2 s, ~88 chain steps, up to 196
active effects.

| | avg | p50 | p90 | p99 | frames > 16.7 ms |
|---|---|---|---|---|---|
| Before HUD fix: raster | 13.7 ms | 13.5 | 17.5 | 20.8 | 533 of 3598 |
| After HUD fix: raster (2 runs) | 5.6 ms | 5.6 | 6.9 | 8.6–9.0 | 1–2 of ~3620 |
| UI thread (build) | 0.7 ms | 0.7 | 0.9 | 1.1 | 0 |

## Verified 2026-10-15
- Windows: shader orbs, background, board, dock, HUD, aiming, pops, a 3-step chain with a
  cracked shell (chain demo), the game-over panel, and restart.
- Android emulator (API 37, 1080×2400, debug build): the shader renders, layout, the chain
  demo plays, no Flutter errors in the log.
