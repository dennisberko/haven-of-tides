# Phase 02: Interaction

[Previous: walking](01-walking.md) | [Next: dialogue](03-dialogue.md)

## Goal

The player can use one button to interact with an object in the cove.

## Add

- Mark one sign as an interactive object.
- Show a prompt when the player is close enough to use the sign.
- Let the player press one button to read a short sign message.
- Hide the prompt when the player moves away.

## Use from earlier phases

- Walking
- Collision in the cove

## Complete when

The prompt appears only near the sign, and one button shows its message one time for each press.

## Do not add

- Resident dialogue
- Dialogue choices
- Requests
- Item pickup
- More interaction types

## Test

1. Walk toward the sign.
2. Confirm that the prompt appears at the correct distance.
3. Press the interaction button and read the message.
4. Move away and confirm that the prompt disappears.
5. Approach from another direction and use the sign again.
