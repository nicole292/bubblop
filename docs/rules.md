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

## Levels (in-round difficulty)
- Level up every 30 orbs cleared.
- Colour 5 is introduced at level 5.
- In the campaign the same thing happens, but the banner says "Speed up!" so it is not
  confused with the campaign level number.

## Campaign (30 levels)
Defined in `packages/pop_core/lib/src/levels.dart`; same rules as Endless, no new mechanics.
- Each level has a **fixed deal** (seed): every attempt gets the same balls and rows.
- Goals, all of which must be met before the round ends:
  - **Score** N points (the round's score),
  - **Pop** N balls (balls popped in groups; cracked shells don't count),
  - **Chain** ×N (a chain of N steps from one drop).
- The level is **won the moment its goals are met** (after that move plays out), even if
  the same move would also have ended the round. A round that ends first is a loss and
  records nothing.
- Levels 1–20 have one goal (score, pop and chain are each introduced alone, small targets
  first); 21–30 raise the targets and combine two familiar goals.
- Targets and seeds were set with `dart run tool/levels.dart` (a greedy bot that never plans
  chains): early levels are won by the bot ~95–100% of the time, later ones 15–85%. A
  winning move list for every level is in `test/level_solutions.dart`, and
  `levels_test.dart` replays it, so every level is proven winnable.
- Level 1 plays on the tutorial board for a player who hasn't done the tutorial.

## Rewards (app, cosmetic only)
- First clear of a level: 10 coins (levels 1–9), 15 (10–19), 20 (20–30). Replays pay
  nothing more and only keep the best score.
- Gift box after levels 3, 6, 9, 12, 15, 18, 21, 24, 27: 30–75 coins (fixed, shown).
- Special gift after 10, 20, 30: 100 coins plus Candy balls / Sunset sky / Twilight sky.
- Achievements (each once): First win 20, Chain reaction 20, Complete 5 levels 40,
  Complete 10 levels 60, Personal best (Endless) 30, All 30 levels 250 coins.
- Coins unlock Jewel balls (250), Neon balls (400) and the Mint sky (200). No purchases.
- Everything is saved on the device the moment it is earned (`app/lib/progress/`).

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
