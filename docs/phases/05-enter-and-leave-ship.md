# Phase 05: Enter and leave the ship

[Previous: resident requests](04-resident-requests.md) | [Next: sailing](06-sailing.md)

## Goal

The player can change between walking in the cove and standing on the ship.

## Add

- Place the ship at the damaged dock.
- Show an interaction prompt at the ship entry point.
- Move the player to the ship when the player enters it.
- Let the player leave the ship only at the dock.
- Restore the correct player position and control mode after each change.

## Use from earlier phases

- Walking
- Interaction

## Complete when

The player can enter and leave the ship five times without a bad position, wrong control mode, or blocked input.

## Do not add

- Ship movement
- Docking at other places
- A ship interior
- Cargo preparation
- A departure menu

## Test

1. Walk from the cove fire to the ship.
2. Enter the ship.
3. Confirm that walking control is off.
4. Leave the ship and confirm that walking control returns.
5. Repeat from different positions near the entry point.
