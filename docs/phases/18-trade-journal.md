# Phase 18: Trade journal

[← Phase 17: Port conditions](17-port-conditions.md) | [Phase 19: Food use →](19-food-use.md)

## Work status

**Phase status: DONE**

| Work item | Status |
| --- | --- |
| Add 1: Add one trade journal screen | DONE |
| Add 2: Record the last price state seen for each good at a visited port | DONE |
| Add 3: Record the last stock or demand marks seen there | DONE |
| Add 4: Record the voyage number when the player saw the market | DONE |
| Add 5: Record a known port condition with the entry | DONE |
| Add 6: Mark the entry as old after a completed voyage | DONE |
| Add 7: Update the entry only when the player visits the port again | DONE |
| Complete when: Keep the last market view without live remote updates | DONE |
| Test 1: Visit the port and open its market | DONE |
| Test 2: Open the journal and confirm that its values match | DONE |
| Test 3: Leave and complete one voyage | DONE |
| Test 4: Confirm that the entry is marked as old | DONE |
| Test 5: Return and confirm that the entry updates | DONE |

## Goal

Let the player keep useful market information without making it live information.

## Add

- Add one trade journal screen.
- Record the last price state seen for each good at a visited port.
- Record the last stock or demand marks seen there.
- Record the voyage number when the player saw the market.
- Record a known port condition with the entry.
- Mark the entry as old after the player completes a voyage.
- Update the entry only when the player visits the port again.

## Use from earlier phases

- Port price states.
- Stock and demand marks.
- Port conditions.
- The voyage count.

## Complete when

The journal keeps the last market view, marks it as old, and does not update it from a distance.

## Do not add

- Live market updates.
- Rumors from residents or ships.
- Journal upgrades from cove buildings.
- Trade route advice.

## Test

1. Visit the port and open its market.
2. Open the journal and confirm that its values match the market.
3. Leave and complete one voyage.
4. Confirm that the entry is marked as old.
5. Return to the port and confirm that the entry updates.
