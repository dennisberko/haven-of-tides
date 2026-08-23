# Phase 14: Buying and selling

[Previous: construction](13-construction.md) | [Next: price states](15-price-states.md)

## Goal

The player can buy one trade good at the port and sell it at the cove.

## Add

- Give the player a money total.
- Add one trader at the port and one buyer at the cove.
- Show one good with fixed buy and sell prices.
- Let the player buy one cargo lot if there is money and cargo space.
- Let the player sell that lot and update money and cargo.

## Use from earlier phases

- Walking and interaction
- Dialogue or a simple trader view
- Sailing and docking
- Cargo limits

## Complete when

The player can buy one lot at the port, carry it to the cove, sell it, and see the correct money and cargo totals.

## Do not add

- Cheap, Normal, or Valuable states
- Stock or demand
- Market changes
- A trade journal
- Taxes, fees, loans, or debt
- More than one trade route

## Test

1. Dock at the port and open the trader view.
2. Buy one cargo lot and confirm its cost and cargo slot.
3. Try to buy without enough money or free cargo space.
4. Sail to the cove and sell the lot.
5. Confirm the final money and cargo totals.
