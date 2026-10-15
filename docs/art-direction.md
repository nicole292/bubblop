# Art direction: "Lit Glass at Night"

Tokens: `app/lib/game/palette.dart`. Orb and shell material: `app/shaders/orb.frag`
(Canvas fallback in `app/lib/render/orb_material.dart`). Effects: `app/lib/render/effects.dart`.

## Principles
- **One light source, top-left**, for every orb, shell, bezel edge and panel.
- **Dark, calm stage; bright pieces.** Light is what draws the eye, so only orbs and
  effects glow.
- **Motion explains the rules.** Effects fire on land, pop, crack, chain and rise.
  At rest there is only slow ambient life (nebula drift, twinkling stars, rising motes,
  a glint sweeping across the orbs every 7 s).
- **Never colour alone.** Every colour has a symbol: coral ●, saffron ▲, mint ■,
  azure ◆, orchid ✦.
- **Light adds up.** Glows, sparks and rings use additive blending, so overlaps brighten
  like real light instead of stacking flat discs.

## Pieces
| Piece | Look |
|---|---|
| Orb | Per-pixel glass (shader): thin and clear in the middle, thick and deep at the edge; light gathering inside toward the lower right, in the orb's own colour; sky reflection at grazing angles; bounce light on the lower rim; a soft oval hot spot and a crescent along the upper-left rim; symbol set inside the glass |
| Shell | Frosted casing (clear centre, milky edge, inner light ring, shadowed lower lip) over a smaller fully coloured core with a bold white symbol |
| Board | Dark metal bezel with a lit top edge; recessed well with an inner top shadow, rounded column channels, a floor that pools light and takes on the colour of the last pop, and a faint glass sheen |
| Next row | Recessed sockets in a dock under the board; shells bob gently, socket rims turn red with 2 drops left and pulse at 1 |
| Background | Night gradient, slowly drifting nebula (baked at quarter resolution), twinkling stars, a few rising colour motes, and a pool of stage light behind the board |
| HUD | Glass panels with lit top edges; the score counts up; next orbs sit in sockets that match the dock |

## Feedback (scales with the moment)
| Moment | Effect |
|---|---|
| Aim | Beam in the held orb's colour, pulsing landing ring with a ghost orb, held orb over the column |
| Land | 90 ms squash and a soft puff of light |
| Match (highlight) | Orbs swell, glow and brighten toward white; neighbouring shells start to crack |
| Pop | Per orb: a burst of light, streak sparks (every third one white-hot), a rising mote. Per group: a shockwave ring. "+points" rises from the burst |
| Bigger group / later step | Intensity `(1 + 0.22·(n−4)) · (1 + 0.45·(step−1))`, capped at 3.4: more and faster sparks, bigger flashes and rings |
| Chain step 2+ | A beam of light runs from the previous burst to this one; "×step" in the group's colour; a second white ring; board and floor flare in the popped colour, stronger each step; from step 3, a small screen shake (at most 7 px) |
| Shell crack | Cracks spread from the side that was hit; the casing shatters into glass shards with a white flash and a ring; the freed core swells, flashes in its colour, then settles |
| Danger | Red light pulsing down from the top of nearly full columns |

## Typography
Sora (SIL OFL 1.1), bundled. Tabular figures for scores. Weights are set through the
variable font's `wght` axis (`app/lib/ui/type.dart`).

## Performance rules (measured, see known-bugs.md)
- Anything drawn many times per frame is baked into images first (`OrbSprites`): orbs,
  shells, halos, bloom and ring sprites.
- **Never draw vector material inside the HUD.** The HUD is redrawn every frame on top of
  the game canvas; three vector orb icons there cost ~8 ms of raster time per frame. HUD
  icons use the baked sprites.
- A paint used with a shader must keep an opaque colour (its alpha also fades the shader).
- Effects come from one pool of 900 slots and are skipped when it is full.
