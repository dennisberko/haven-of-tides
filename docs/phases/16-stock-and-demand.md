# Phase 16: Stock and demand

[← Phase 15: Price states](15-price-states.md) | [Phase 17: Port conditions →](17-port-conditions.md)

## Goal

Make the amount that a port can buy or sell clear and limited.

## Add

- Show one to three stock marks on each Cheap good.
- Remove one stock mark when the player buys one cargo lot.
- Do not sell the good when it has no stock marks.
- Show one to three demand marks on each Valuable good.
- Remove one demand mark when the player sells one cargo lot.
- Change the good to Normal when it has no demand marks.
- Return each used mark after two completed voyages. Show the return voyage.

## Use from earlier phases

- Docking at the port.
- Buying and selling cargo.
- Cheap, Normal, and Valuable price states.
- Limited ship cargo space.

## Complete when

The player can use all stock or demand at one port and can see when it will return.

## Do not add

- Port conditions.
- A trade journal.
- Hidden price changes.
- Regional supply simulation.

## Test

1. Dock at the port.
2. Buy all marks of one Cheap good.
3. Confirm that the port cannot sell more of that good.
4. Sell to all marks of one Valuable good.
5. Confirm that the good becomes Normal.
6. Complete two voyages and confirm that the used marks return.
