# Phase 20: Ship damage

[← Phase 19: Food use](19-food-use.md) | [Phase 21: Repairs →](21-repairs.md)

## Goal

Make unsafe sailing cause visible damage to the ship.

## Add

- Add one hull condition meter.
- Remove a fixed amount of hull condition when the ship hits a reef.
- Give the ship a short damage flash and sound.
- Stop repeated damage for a short time after one hit.
- Keep the damage when the player docks or changes areas.

## Use from earlier phases

- Ship steering.
- Sailing collisions.
- Docking.

## Complete when

Reef contact causes clear, persistent hull damage one time per hit.

## Do not add

- Repairs.
- Sail damage.
- Crew injuries.
- Naval attacks.
- Ship defeat or recovery.

## Test

1. Sail into a reef.
2. Confirm the damage feedback and the lower hull condition.
3. Stay against the reef and confirm that damage does not occur each frame.
4. Dock and leave again.
5. Confirm that the hull condition stays damaged.
