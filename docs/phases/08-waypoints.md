# Phase 08: Waypoints

[Previous: docking](07-docking.md) | [Next: visible sea opportunities](09-visible-sea-opportunities.md)

## Goal

The player can select one known location and see its direction while sailing.

## Add

- Add a simple sea chart with the cove, island, port, and player position.
- Let the player select one known location as a waypoint.
- Show the selected waypoint on the chart.
- Show its direction in the sailing view.
- Clear or replace the waypoint when the player selects another location.

## Use from earlier phases

- Sailing
- The cove, island, and port docks

## Complete when

The player can select each known location and follow the direction marker to it.

## Do not add

- Fast travel
- Undiscovered locations
- Quest markers
- Route planning
- Distance or arrival-time calculations
- A complex chart

## Test

1. Open the chart at the cove.
2. Select the port as the waypoint.
3. Sail toward the direction marker and dock at the port.
4. Select the island as a new waypoint.
5. Confirm that the old marker is gone and the new marker points to the island.
