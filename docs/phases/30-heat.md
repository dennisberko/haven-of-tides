# Phase 30: Heat

[← Phase 29: Prize actions](29-prize-actions.md) | [Phase 31: Pirate hunters →](31-pirate-hunters.md)

## Goal

Make attacks on peaceful ships cause one clear, persistent consequence.

## Add

- Add one heat meter for the full world.
- Mark peaceful ships during target inspection.
- Show the estimated heat increase before the player attacks.
- Add the shown amount when the first attack hits a peaceful ship.
- Do not add more heat for later hits on the same ship.
- Keep heat after travel, docking, and loading the game.
- Reduce heat by one step after a completed voyage with no attack on a peaceful ship.

## Use from earlier phases

- Target inspection.
- Naval attacks.
- Boarding and prize actions.
- The voyage count.

## Complete when

An attack on a peaceful ship raises the heat meter by the amount shown before the attack.

## Do not add

- Pirate hunters.
- Port service refusal.
- Separate heat for each nation.
- Laws, bribes, or wanted levels.
- Resident reactions.

## Test

1. Inspect a peaceful ship and note the estimated heat increase.
2. Attack it and confirm that heat rises by that amount.
3. Hit it again and confirm that heat does not rise again.
4. Dock and load the game, then confirm that heat stays the same.
5. Complete one voyage with no peaceful attack and confirm that heat falls one step.
