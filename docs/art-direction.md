# Art direction: "Lit Glass at Night"

Colour tokens live in `app/lib/game/palette.dart`; materials in `app/lib/render/orb_material.dart`.

## Principles
- **One light source, top-left**, for every orb, shell, board edge and panel.
- **Dark, calm stage; bright pieces.** The board is a recessed indigo tray; only orbs glow.
- **Motion explains the rules.** Effects appear only when something happens (land,
  pop, crack, rise). Nothing idles, glows or emits particles on its own.
- **Never colour alone.** Every colour has a symbol: coral ●, saffron ▲, mint ■,
  azure ◆, orchid ✦.

## Pieces
| Piece | Look |
|---|---|
| Orb | Glass with a light-to-deep body gradient, inner glow toward the lower right, rim light on the lower edge, etched symbol, soft highlight and a crisp hot spot, thin dark edge |
| Shell | Frosted casing (clear centre, frosty edge) around a smaller, fully saturated core with a bold white symbol, plus frost facets and a bright rim at the top-left |
| Stone | Matte slate block (experiment only) |
| Board | Recessed tray with an inner top shadow, faint column grooves, and a rim that catches the light |
| Next row | Mini shells in a slim tray under the board; they brighten when 2 drops are left and pulse at 1 |

## Feedback (restrained)
| Moment | Effect |
|---|---|
| Aim | Soft beam in the held orb's colour, landing ring, held orb over the column |
| Land | 90 ms squash |
| Match | Glow, then a ring of light plus 5–7 sparks per orb |
| Chain step 2+ | Banner "Chain ×n"; the board edge flares in the popped colour, stronger with each step |
| Shell crack | Glass shards; the casing swells and fades while the core grows into a full orb |
| Danger | Red glow pulsing from the top of nearly full columns |

## Typography
Sora (SIL OFL 1.1), bundled. Tabular figures for scores. Weights are set through the
variable font's `wght` axis (`app/lib/ui/type.dart`).

## Performance
Orbs are drawn once per screen size into images (`OrbSprites`), then drawn as images
every frame. Particles come from a fixed pool of 320 and are skipped if it is full.

## Not done yet
Sound, haptics, menus, app icon, and a final review of the colours on a real phone screen.
