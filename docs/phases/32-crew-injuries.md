# Phase 32: Crew injuries

[Previous: Phase 31 - Pirate hunters](31-pirate-hunters.md) | [Next: Phase 33 - Defeat and recovery](33-defeat-and-recovery.md)

## Goal

Make combat damage affect the crew after a battle.

## Add

- Add one crew condition value.
- Let naval combat injure the crew.
- Show crew condition in the ship view.
- Reduce one clear ship action when crew condition is low.
- Restore the crew at the cove or a known port.

## Use from earlier phases

- Ship damage
- Naval attack
- Boarding
- Pirate hunters
- Docking

## Complete when

Combat can injure the crew. An injury has a visible effect until the player reaches a safe port.

## Do not add

- Individual crew members
- Officer injuries
- Wages
- Mutiny
- Crew schedules
- A recruitment market

## Test

1. Start a fight with a full crew condition value.
2. Take enough damage to cause an injury.
3. Confirm that the crew value and one ship action change.
4. Leave combat and dock at the cove.
5. Restore the crew and confirm that the ship action returns to normal.
