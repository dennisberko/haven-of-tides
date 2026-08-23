# Phase 26: Boarding

[← Phase 25: Sail damage](25-sail-damage.md) | [Phase 27: On-foot combat →](27-on-foot-combat.md)

## Goal

Let the player move from naval combat to a target ship deck.

## Add

- Mark a target as ready to board when its hull or sails are weak.
- Require the player ship to pull alongside the target.
- Show one Board prompt when position and target condition are valid.
- Move the player to one compact target deck after confirmation.
- Let the player walk on the empty deck and return to the player ship.

## Use from earlier phases

- Hull and sail damage.
- Ship positioning.
- Interaction.
- Walking.

## Complete when

The player can weaken a ship, pull alongside it, board it, and return.

## Do not add

- Defenders.
- On-foot combat.
- Surrender.
- Prize actions.
- Ship capture.

## Test

1. Damage one target until it is ready to board.
2. Try to board from far away and confirm that no prompt appears.
3. Pull alongside and use the Board prompt.
4. Walk across the target deck.
5. Use the return point and confirm that control returns to the player ship.
