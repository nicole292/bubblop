# Project POP — Gameplay Rules (v0.1)

Status: draft spec for the first prototype. Every number here lives in
`RulesConfig` (packages/pop_core) so it can be tuned without code changes.

## Board
- 6 columns × 10 rows, portrait. Row 0 is the bottom.
- Each cell is empty, an **orb** (colour), or a **shell** (colour, encased).

## Input
- Drag in the lower half to aim a column; release to drop. Tapping a column also drops.
- A ghost orb shows the exact landing cell.
- Dropping into a full column is rejected (no state change, column shakes).

## Queue and randomness
- The current orb plus the next 2 are visible.
- Colours come from a shuffled **bag** (each active colour ×2 per bag).
- All randomness comes from a single seeded RNG, so the same seed always produces the same game.
- Start with 4 colours; the 5th joins at level 4.

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
- A countdown starts at 8 pips. Every drop ticks it by 1.
- At 0, **after the move has fully resolved**, a row of 6 shells rises from the bottom
  and pushes everything up by one. The countdown resets to the current level's interval.
- Interval: 8 at level 1, down 1 per level, minimum 4.
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
- Colour 5 is introduced at level 4.

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
