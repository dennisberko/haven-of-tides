# Phase 11: Cargo limit

[Previous: salvage](10-salvage.md) | [Next: cove storage](12-cove-storage.md)

## Goal

Limited ship space makes the player choose which cargo to keep.

## Add

- Give the ship a small number of cargo slots.
- Show used and free slots in the cargo view.
- Make each cargo lot use one slot.
- Place more useful salvage lots at the wreck than the ship can hold.
- Let the player keep a new lot, leave it, or replace one carried lot.

## Use from earlier phases

- Sailing
- Salvage
- Cargo carried on the ship

## Complete when

A full ship cannot take another lot until the player leaves the new lot or removes a carried lot.

## Do not add

- Cargo modules
- Item weight
- Different lot sizes
- Sorting or filters
- Cove storage
- Selling cargo

## Test

1. Start with all but one cargo slot full.
2. Sail to the wreck and take one salvage lot.
3. Try to take another lot.
4. Replace one carried lot with the new lot.
5. Confirm that used cargo slots never exceed the ship limit.
