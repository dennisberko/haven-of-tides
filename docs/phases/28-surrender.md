# Phase 28: Surrender

[← Phase 27: On-foot combat](27-on-foot-combat.md) | [Phase 29: Prize actions →](29-prize-actions.md)

## Goal

Let a surviving defender stop fighting when morale breaks.

## Add

- Add a small morale meter to the defender.
- Reduce morale when the defender takes damage.
- Let the defender surrender before health reaches zero.
- Stop all attacks from a surrendered defender.
- Disable player attacks against a surrendered defender.
- Show a clear surrender pose and end the fight.

## Use from earlier phases

- On-foot health and attacks.
- Hit feedback.
- Boarding combat state.

## Complete when

A defender can surrender, end the fight, and remain safe from player attacks.

## Do not add

- Executions.
- Ransom.
- Prisoners.
- Crew trading.
- Prize actions.
- Relationship reactions.

## Test

1. Board the target ship.
2. Damage the defender without reducing health to zero.
3. Confirm that morale reaches zero and the defender surrenders.
4. Try to attack the surrendered defender.
5. Confirm that the attack cannot cause damage.
