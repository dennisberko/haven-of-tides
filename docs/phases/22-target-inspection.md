# Phase 22: Target inspection

[← Phase 21: Repairs](21-repairs.md) | [Phase 23: Naval attack →](23-naval-attack.md)

## Work status

**Phase status: DONE**

| Work item | Status |
| --- | --- |
| Add 1: Add an Inspect action for one nearby ship | DONE |
| Add 2: Show its owner or flag | DONE |
| Add 3: Show its ship class and likely speed | DONE |
| Add 4: Show its general cargo type | DONE |
| Add 5: Show a Low, Medium, or High threat estimate | DONE |
| Add 6: Show whether it is peaceful | DONE |
| Add 7: Show an estimated heat cost without changing heat | DONE |
| Add 8: Label all values as estimates | DONE |
| Complete when: Inspect a nearby ship and make a clear attack choice | DONE |
| Test 1: Sail near a merchant ship | DONE |
| Test 2: Use Inspect | DONE |
| Test 3: Confirm that all estimate fields are visible | DONE |
| Test 4: Sail out of range and confirm that the view closes | DONE |
| Test 5: Inspect a different ship and confirm different values | DONE |

## Goal

Give the player enough information to choose whether to attack a ship.

## Add

- Add an Inspect action for one nearby ship.
- Show its owner or flag.
- Show its ship class and likely speed.
- Show its general cargo type.
- Show a Low, Medium, or High threat estimate.
- Show whether it is peaceful.
- Show an estimated heat cost. This value does not change heat yet.
- Label all values as estimates.

## Use from earlier phases

- Sailing near visible ships.
- The interaction input.
- Sea waypoints and opportunities.

## Complete when

The player can inspect a nearby ship and can make a clear attack choice from the result.

## Do not add

- Naval attacks.
- An active heat meter.
- Exact hidden cargo.
- Hidden threats that make the normal estimate false.
- Separate faction records.

## Test

1. Sail near a merchant ship.
2. Use Inspect.
3. Confirm that all estimate fields are visible.
4. Sail out of inspection range and confirm that the view closes.
5. Inspect a different ship and confirm that its values are different.
