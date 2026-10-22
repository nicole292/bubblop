# Project POP — Gameplay Rules (v0.3)

Status: draft spec for the first prototype. Every number here lives in
`RulesConfig` (packages/pop_core) so it can be tuned without code changes.

## Board
- 6 columns × 11 rows, portrait. Row 0 is the bottom.
- **A round starts with 1 row of shells at the bottom and 2 rows of ordinary balls on
  top**, coloured so that no group is already complete (v0.3). Early drops can complete
  groups that crack the shells below.
- Each cell is empty, an **orb** (colour), or a **shell** (colour, encased).

## Input
- Drag in the lower half to aim a column; release to drop. Tapping a column also drops.
- A ghost orb shows the exact landing cell.
- Dropping into a full column is rejected (no state change, column shakes).

## Queue and randomness
- The current orb plus the next 2 are visible.
- Colours come from a shuffled **bag** (each active colour ×2 per bag).
- All randomness comes from a single seeded RNG, so the same seed always produces the same game.
- Start with 4 colours; the 5th joins at level 5.

## Resolving a move (deterministic)
1. The orb lands in the lowest empty cell of the chosen column.
2. Set chain step k = 1.
3. Find every group of **≥ 4** same-colour orbs connected orthogonally (no diagonals). Shells never join groups.
4. If there are none, the move ends.
5. Pop all of those groups at once.
6. Every shell orthogonally adjacent to a popped orb cracks and becomes a normal orb of its colour.
7. Apply gravity: everything (orbs and shells) falls straight down.
8. k = k + 1 and go back to step 3.

## Pressure (shells)
- A countdown starts at 9 pips. Every drop ticks it by 1.
- At 0, **after the move has fully resolved**, a row of 6 shells rises from the bottom
  and pushes everything up by one. The countdown resets to the current level's interval.
- Interval: 9 at level 1, down 1 every **2** levels, minimum 4 (9, 9, 8, 8, 7, 7, 6, 6, 5…).
- **The next row is visible** before it rises, so its shell colours can be planned for.
  Rows are generated one rise ahead; a level-up affects the row after the previewed one.
- Optional `chainRelief` (off by default): a 2+ step chain adds drops back to the
  countdown, capped at the interval.
- Shell colours come from a second generator derived from the same seed, so rising rows
  never change which orbs you are dealt. They are visible faintly through the glass.

## Scoring
- Group of n orbs: `10n + 15(n−4)(n−3)` → 4 = 40, 5 = 80, 6 = 150, 7 = 250.
- Chain step k multiplies everything popped in that step by **k²**.
- Several colours popping in the same step: +50% for each extra colour (applied before k²).
- Cracked shell: 5 × k².
- Board fully cleared after a move: +1000 × level.

## Levels
- Level up every 30 orbs cleared.
- Colour 5 is introduced at level 5.

## Game over
- A rising row would push any cell above row 9 → game over.
- Every column is full → game over.
- Columns at row 8 and above show a warning (presentation only).

## Animation timing (presentation only; never affects rules)
| Event | Duration |
|---|---|
| Drop fall | 90 ms + 15 ms per row fallen |
| Landing squash | 90 ms |
| Chain step: highlight → pop + crack → gravity | 100 + 150 + 150 ms |
| Later chain steps | −15% each, floor ≈ 250 ms per step |
| Row rise | 250 ms |
| Input during animation | remaining animations play at 3× speed; the move is accepted immediately |

## Experiment: shells vs stones
A debug toggle switches risen rows between **Shells** (crack → reveal colour) and
**Stones** (grey blocks that vanish when hit). Compare longest chain, % of chains that
involve a revealed shell, moves survived, and subjective strategy/fun ratings (1–5).
Keep shells only if they clearly win.

**Result (2026-10-15): shells win.** Playtest: shells 4/5 strategy, 4/5 fun; stones 2/5, 2/5.
Simulation (500 games, greedy bot): shells produce ~6× more chains than stones, and
~83% of chains are fed by a cracked shell. Shells are the default; stones stay as a
debug toggle for comparison only.

**Update (2026-10-15):** stones are removed from the playable game (user decision: less fun
and less strategic). `RisingRowKind.stones` stays in pop_core only so the simulator can
keep comparing against it. Revisit only for a genuinely different mechanic.

## Balance notes (v0.2)
Run `dart run tool/simulate.dart` in packages/pop_core to compare configurations.
- v0.1 stacked two difficulty jumps at level 4 (5th colour + interval 5); the median
  bot game ended there. v0.2 halves the pressure ramp and moves colour 5 to level 5:
  median game 85 → 103 moves, with the same pop and chain rates.
- 3-match pops on ~44% of moves (vs ~28%) and keeps the board emptier; likely less
  planning. 4-match stays the default; 3-match stays a debug toggle for playtests.
- Chain relief had no measurable effect for the bot; left off to keep the rules simple.

## Balance notes (v0.3): the first 10 seconds
Starting with an empty board, **0%** of simulated games popped anything within the first
5 moves (4 matching balls are needed). Starting with shell rows alone did not help
(shells never match) and only shortened games. Starting with **1 shell row + 2 rows of
balls** gave a pop within 5 moves in **66%** of games and the most chains (2.0 per
100 moves). With the first countdown raised from 8 to 9, the median game length is
unchanged (101 moves, against 103).
