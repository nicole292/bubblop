# Art direction: "Bright & Bouncy"

(Replaces "Lit Glass at Night" on 2026-10-15: user feedback was that the dark glass look felt
too premium and overdesigned. The goal is colourful, fun, clean and modern, but still
polished.)

Tokens: `app/lib/game/palette.dart`. Ball material: `app/shaders/ball.frag` (Canvas
fallback in `app/lib/render/orb_material.dart`). Effects: `app/lib/render/effects.dart`.

## Principles
- **The balls are the stars.** Simple, glossy, solid-colour spheres with no symbols or
  markings. Everything else is calmer and lighter than they are.
- **Bright and friendly.** Sky-blue to lavender background, white cards, a rounded font.
- **Quality comes from colour, shape, light and motion**, not from ornament: one light
  source (top-left), soft shadows, bouncy timing.
- **Playful, readable feedback.** Effects are coloured confetti and sparkles, not glowing
  light. They scale up with matches and chains, then clear quickly.

## Colours
| Use | Colour |
|---|---|
| Balls | Cherry `#FF4757`, Sunflower `#FFC312`, Fresh green `#2ED573`, Sky blue `#1E90FF`, Grape `#9B59F6` (the 5th, from level 5) |
| Sky | `#5CC8FF` → `#7FA8FF` → `#A98BFF` |
| Cards | White, soft shadow `#3A2D9E` at 33% |
| Text | Ink `#26285A`, soft ink `#7B80B0`; white on the sky |
| Accent | Purple `#7B5CFF` (level pill, banner outline) |
| Button | Orange `#FFA62B` → pink `#FF5C8A` |

The ball colours differ in brightness as well as hue. Colour is the only cue on a ball,
so a colour-blind option should be considered later (Stage 4 settings).

## Pieces
| Piece | Look |
|---|---|
| Ball | Shader: soft shading from the light, slightly deeper colour on the shaded rim, light bounced from the white board on the lower rim, a soft oval highlight and a small hot spot, and a faint contour |
| Shell | A white bubble (clear centre, solid rim, highlight) around a smaller ball |
| Board | A white rounded card with a soft coloured shadow; a pale well with alternating rounded lane stripes and a faint inner top shadow. Static parts are baked into one image per layout |
| Next row | Balls in shells, sitting in sockets on a white dock pill; they bob gently, and the sockets get red rings with 2 drops left |
| Background | Sky gradient, three soft colour blobs (pink, mint, peach), and slow rising bubbles |
| HUD | White cards (score, next balls in sockets), a purple LEVEL pill, white capsule pips on the sky (red for the last two), and a white round restart button |
| Round over | A white card that bounces in, a big score, a gold "New best!" pill, stats, and a chunky gradient Play again button that presses down |
| Text | Nunito (SIL OFL 1.1), weights 800–900, tabular figures for scores |

## Feedback
| Moment | Effect |
|---|---|
| Aim | The held ball bobs over the column; a soft lane in its colour; a ghost ball in a pulsing ring where it will land |
| Land | Squash and a tiny puff of dust |
| Match (highlight) | Balls swell with a soft halo in their colour; shells next to them start to crack |
| Pop | Balloon pop: each ball puffs up and vanishes. Confetti dots and ribbons in its colour (and a lighter tint), a soft ring per group, gold sparkles, and "+points" in white with an ink outline |
| Bigger group / later step | Intensity `(1 + 0.22·(n−4)) · (1 + 0.45·(step−1))`, capped at 3.4: more and faster confetti, bigger rings, more sparkles |
| Chain step 2+ | A gold sparkle trail arcs from the previous burst to this one; a bouncy "×step" with a coloured outline; the board's border flashes in the popped colour, stronger each step; from step 3, a small screen shake (at most 6 px). Older labels clear quickly |
| Shell crack | Cracks spread over the bubble from the side that was hit; it pops into lavender droplets with a ring in the ball's colour; the freed ball boings out and settles |
| Danger | A soft red tint pulsing down nearly full columns |

## Performance rules (measured, see known-bugs.md)
- Anything drawn many times per frame is a baked image (`OrbSprites`); the static board
  is one baked image.
- The HUD is redrawn every frame on top of the game canvas: never put vector-heavy
  drawing there (HUD balls use the baked sprites).
- A paint used with a shader must have an opaque colour (its alpha also fades the
  shader). This bug has happened twice; reset the colour before setting a shader.
- Effects come from one pool of 900 slots and are skipped when it is full.
