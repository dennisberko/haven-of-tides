# Phase 19: Food use

[← Phase 18: Trade journal](18-trade-journal.md) | [Phase 20: Ship damage →](20-ship-damage.md)

## Goal

Make travel use a visible supply.

## Add

- Add a food supply to the ship.
- Use one food unit after a fixed amount of sailing.
- Show the current food amount in the sea view.
- Show a warning when only one food unit remains.
- Show a no-food warning when the supply is empty.
- Let the player continue to sail when food is empty.

## Use from earlier phases

- Sailing.
- Buying and selling food.
- Ship cargo space.
- Cove storage.

## Complete when

A normal voyage uses a visible amount of food and never hides the next use.

## Do not add

- Hunger for individual crew members.
- Crew injuries.
- Spoilage.
- Fast travel food costs.
- A hard voyage limit.

## Test

1. Load three food units on the ship.
2. Sail until the ship uses one unit.
3. Confirm that the sea view shows two units.
4. Continue until the low-food and no-food warnings appear.
5. Confirm that the player can still sail.
