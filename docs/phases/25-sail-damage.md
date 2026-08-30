# Phase 25: Sail damage

[← Phase 24: Ammunition](24-ammunition.md) | [Phase 26: Boarding →](26-boarding.md)

## Work status

**Phase status: DONE**

| Work item | Status |
| --- | --- |
| Add 1: Add Hull and Sails as two attack choices | DONE |
| Add 2: Add a sail condition meter to target ships | DONE |
| Add 3: Make a Sails attack reduce sails but not hull | DONE |
| Add 4: Reduce target speed in clear sail-condition steps | DONE |
| Add 5: Keep a small minimum speed at zero sail condition | DONE |
| Add 6: Use normal broadside ammunition for both choices | DONE |
| Complete when: Spend ammunition to slow and catch a target without disabling its hull | DONE |
| Test 1: Chase a target that is faster than the player ship | DONE |
| Test 2: Select Sails and fire one broadside | DONE |
| Test 3: Confirm sails fall and hull does not | DONE |
| Test 4: Confirm the target becomes slower | DONE |
| Test 5: Catch the target without reducing hull to zero | DONE |

## Goal

Let the player slow a target instead of only damaging its hull.

## Add

- Add Hull and Sails as two attack choices.
- Add a sail condition meter to target ships.
- Make a Sails attack reduce sail condition but not hull condition.
- Reduce target speed in clear steps as sail condition falls.
- Keep a small minimum speed when sail condition reaches zero.
- Use the normal broadside ammunition cost for both attack choices.

## Use from earlier phases

- Target inspection.
- Broadside attacks.
- Ammunition.
- Ship pursuit and steering.

## Complete when

The player can spend ammunition to slow a target and catch it without disabling its hull.

## Do not add

- Boarding.
- Sail repair.
- Special ammunition.
- Crew injuries.
- Permanent ship modules.

## Test

1. Chase a target that is faster than the player ship.
2. Select Sails and fire one broadside.
3. Confirm that sail condition falls and hull condition does not.
4. Confirm that the target becomes slower.
5. Catch the target without reducing its hull condition to zero.
