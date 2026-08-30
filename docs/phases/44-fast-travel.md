# Phase 44: Fast travel

[Previous: Phase 43 - Day and night](43-day-and-night.md) | [Next: Game design ideas](../game-design-ideas.md)

## Work status

**Phase status: DONE**

| Work item | Status |
| --- | --- |
| Add 1: Unlock a port after the player docks there once | DONE |
| Add 2: Add a fast travel action to the sea chart | DONE |
| Add 3: Show the food and time cost before travel | DONE |
| Add 4: Use the food and advance time when the player confirms | DONE |
| Add 5: Block fast travel during combat, a chase, or a nearby major threat | DONE |
| Add 6: Keep all cargo safe during fast travel | DONE |
| Complete when: Fast travel uses the shown cost and follows all limits | DONE |
| Test 1: Open the chart before the first port visit | DONE |
| Test 2: Confirm that the unvisited port is not available | DONE |
| Test 3: Sail to the port and dock there | DONE |
| Test 4: Leave, open the chart, and select the port | DONE |
| Test 5: Confirm the shown food and time cost | DONE |
| Test 6: Travel and confirm food, time, and cargo | DONE |
| Test 7: Start a chase and confirm that travel is blocked | DONE |

## Goal

Let the player travel to a visited port at a clear cost.

## Add

- Unlock a port after the player docks there once.
- Add a fast travel action to the sea chart.
- Show the food and time cost before travel.
- Use the food and advance time when the player confirms.
- Block fast travel during combat, a chase, or a nearby major threat.
- Keep all cargo safe during fast travel.

## Use from earlier phases

- Docking
- Waypoints and the sea chart
- Food use
- Combat and chases
- Cargo
- Day and night

## Complete when

The player can fast travel to a visited port. The action uses the shown food, advances time, and follows all travel limits.

## Do not add

- Travel to unvisited places
- Random cargo loss
- Random encounters during fast travel
- Free travel
- Travel during combat
- A new world map

## Test

1. Open the chart before the first visit to the test port.
2. Confirm that fast travel to that port is not available.
3. Sail to the port and dock there.
4. Leave, open the chart, and select that port.
5. Confirm the shown food and time cost.
6. Fast travel and confirm that food and time change but cargo does not.
7. Start a chase and confirm that fast travel is blocked.
