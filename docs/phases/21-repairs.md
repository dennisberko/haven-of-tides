# Phase 21: Repairs

[← Phase 20: Ship damage](20-ship-damage.md) | [Phase 22: Target inspection →](22-target-inspection.md)

## Goal

Let the player spend useful cargo to restore the ship.

## Add

- Add one Repair hull action while the ship is docked.
- Require one timber cargo lot for the action.
- Remove the timber when the player confirms the repair.
- Restore a fixed amount of hull condition.
- Show the repair amount before confirmation.
- Disable the action when the hull is full or the ship has no timber.

## Use from earlier phases

- Hull condition.
- Timber cargo.
- Cargo storage.
- Docking.

## Complete when

The player can trade one timber lot for a clear amount of hull condition.

## Do not add

- Repairs during combat.
- Repair prices.
- Sail repairs.
- Workshop bonuses.
- Automatic repairs.

## Test

1. Damage the ship on a reef.
2. Put one timber lot in the ship cargo.
3. Dock and inspect the repair action.
4. Confirm the repair.
5. Confirm that the timber is gone and the hull condition is higher.
