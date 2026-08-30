# Phase 28: Surrender

[← Phase 27: On-foot combat](27-on-foot-combat.md) | [Phase 29: Prize actions →](29-prize-actions.md)

## Work status

**Phase status: DONE**

| Work item | Status |
| --- | --- |
| Add 1: Add a small morale meter to the defender | DONE |
| Add 2: Reduce morale when the defender takes damage | DONE |
| Add 3: Let the defender surrender before health reaches zero | DONE |
| Add 4: Stop all attacks from a surrendered defender | DONE |
| Add 5: Disable player attacks against a surrendered defender | DONE |
| Add 6: Show a clear surrender pose and end the fight | DONE |
| Complete when: Defender can surrender, end the fight, and remain safe from player attacks | DONE |
| Test 1: Board the target ship | DONE |
| Test 2: Damage defender without reducing health to zero | DONE |
| Test 3: Confirm morale reaches zero and defender surrenders | DONE |
| Test 4: Try to attack the surrendered defender | DONE |
| Test 5: Confirm the attack cannot cause damage | DONE |

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
