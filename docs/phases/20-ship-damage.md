# Phase 20: Ship damage

[← Phase 19: Food use](19-food-use.md) | [Phase 21: Repairs →](21-repairs.md)

## Work status

**Phase status: COMPLETE**

| Work item | Status |
| --- | --- |
| Add 1: Add one hull condition meter | DONE |
| Add 2: Remove a fixed amount of hull condition on a reef hit | DONE |
| Add 3: Give the ship a short damage flash and sound | DONE |
| Add 4: Stop repeated damage for a short time after one hit | DONE |
| Add 5: Keep damage through docking and area changes | DONE |
| Complete when: Reef contact causes clear persistent damage one time per hit | DONE |
| Test 1: Sail into a reef | DONE |
| Test 2: Confirm feedback and lower hull condition | DONE |
| Test 3: Stay against the reef and confirm no per-frame damage | DONE |
| Test 4: Dock and leave again | DONE |
| Test 5: Confirm hull condition stays damaged | DONE |

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
