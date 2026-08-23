# Phase 23: Naval attack

[← Phase 22: Target inspection](22-target-inspection.md) | [Phase 24: Ammunition →](24-ammunition.md)

## Goal

Let the player position the ship, fire cannons, and damage a target hull.

## Add

- Add one broadside attack on each side of the player ship.
- Show the active firing area before the shot.
- Give the attack a short reload time.
- Damage a target hull when it is in the firing area.
- Show target hull condition and clear hit feedback.
- Disable the target when its hull condition reaches zero.

## Use from earlier phases

- Ship steering and positioning.
- Target inspection.
- Hull condition.

## Complete when

The player can move into a firing position and disable one target with broadside attacks.

## Do not add

- Ammunition use.
- Sail damage.
- Boarding.
- Prize actions.
- Heat changes.

## Test

1. Inspect one target.
2. Move it into a broadside firing area.
3. Fire and confirm the hit feedback and lower target hull condition.
4. Fire during reload and confirm that no shot occurs.
5. Continue until the target is disabled.
