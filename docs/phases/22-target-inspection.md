# Phase 22: Target inspection

[← Phase 21: Repairs](21-repairs.md) | [Phase 23: Naval attack →](23-naval-attack.md)

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
