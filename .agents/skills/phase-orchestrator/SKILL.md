---
name: phase-orchestrator
description: Implement one Haven of Tides phase from docs/phases with one implementation agent, one Godot runtime verification agent, and two independent review agents.
---

# Phase Orchestrator

Implement one file from `docs/phases` as one work unit. Keep the root agent as
the controller. Use one implementation agent, one read-only Godot runtime
verification agent, and two read-only review agents.

## Limits

- Follow `AGENTS.md` and `docs/phases/README.md`.
- Work only on the requested phase. Start with Phase 01 when the user does not
  select a phase.
- Keep all mechanics from earlier phases.
- Do not add mechanics, interface, data, or content from a later phase.
- Do not add a phase-document linter, plan todo file, claim record, execution
  log, receipt, or custom commit tool.
- Do not change phase status, commit, or push unless the user asks.
- Do not add or update unit tests unless the user authorizes unit-test work. If
  the phase requires unit tests and the user did not give this authorization,
  stop and ask before implementation.
- Do not let a subagent delegate more work.
- Keep generated Godot MCP files in `.mcp/`. Do not commit them.

Use the available multi-agent tools for all subagents. Set `fork_turns: "none"`
for each new agent and give each agent a self-contained prompt. Do not set a
model override unless the user asks or this skill requires one. The Godot
runtime verification agent is the required exception: use `gpt-5.6-luna` with
`reasoning_effort: "max"`.

## 1. Inspect the phase

Read:

- the complete target phase;
- `docs/phases/README.md`;
- the direct prior phase and dependency, when they exist;
- the relevant sections of `docs/game-design-ideas.md`;
- all applicable repository instruction files;
- the current implementation and its direct consumers; and
- `project.godot` and the main scene when they affect the phase.

Inspect Git status and preserve all existing user changes.

Confirm that the target is the next permitted phase. For Phase 02 and later,
require repository or user evidence that the prior phase passed its completion
test. Stop and ask for this evidence when it is not available.

Stop and ask the user only when there is a material product decision, a phase
dependency is not complete, or unit-test authorization is required.

## 2. Make the verification matrix

Before implementation, map each material phase rule and completion criterion to
one evidence type:

- `MACHINE`: Godot validation or another deterministic check can prove it.
- `CODE_REVIEW`: Source, scene, configuration, or interface inspection can
  prove it.
- `RUNTIME`: Interaction with the running Godot project can prove visible
  state, input behavior, collision, navigation, or another gameplay result.

Keep the matrix in the controller brief. Do not write it to the repository.

Use these criterion results in reports:

- `PASS`: Available evidence proves the criterion.
- `FAIL`: Available evidence proves that the implementation does not meet it.
- `NOT_PROVEN`: The required evidence is not available.

Do not change `NOT_PROVEN` to `PASS` with a different evidence type.

The required Godot quality gate after each gameplay change is:

1. Call `get_project_info` for the project.
2. Call `validate` for every changed GDScript. Validate changed scenes when the
   change can affect scene integrity.
3. Call `run_project`.
4. Call `get_debug_output` and check errors.
5. Call `take_screenshot`.
6. Call `simulate_input` for the phase actions and affected earlier actions.
7. Inspect the resulting state. Take more screenshots when they provide useful
   evidence.
8. Call `get_debug_output` again and check new errors.
9. Call `stop_project`, including after a failed check when the project runs.

Do not report a gameplay change as ready without this runtime evidence.

## 3. Run the implementation agent

Use one implementation agent for the whole phase. The phase task list is
guidance for this one scope. Do not make one agent for each task.

Give the implementation agent this brief:

```text
Implement the complete phase in <absolute phase path>.

Read the phase, docs/phases/README.md, its direct dependency, relevant parts of
docs/game-design-ideas.md, all applicable AGENTS.md files, project.godot, and
the current code. The phase and repository instructions are the source of
truth.

Verification matrix:
<matrix>

Unit-test work is authorized: <yes or no>
Existing worktree state:
<status and relevant diff summary>

Preserve existing user changes. Implement only this phase with Godot 4.x and
GDScript. Keep the game playable. Do not add later-phase mechanics. Run focused
checks that the change needs. Keep generated Godot MCP files in .mcp/. Do not
change phase status, commit, push, review your own work, or delegate.

Edit the files in the assigned workspace. Report the outcome, changed files,
checks and results, unresolved evidence, and blockers.
```

The root controller must inspect the returned changes and the complete changed
files. Confirm that the implementation stayed in phase scope. Then perform the
required Godot quality gate. Run separate focused tests only when the user
authorized test work or the change needs an existing focused test.

Do not start review while a required machine or runtime check fails. Send
supported implementation failures to the same implementation agent for repair.

## 4. Verify with the Godot runtime

After the controller quality gate passes, start one fresh runtime verification
agent with:

- `fork_turns: "none"`;
- `model: "gpt-5.6-luna"`; and
- `reasoning_effort: "max"`.

Give this agent a self-contained brief. Include the phase contract, changed-file
list, current revision and worktree state, machine check results, and each
`RUNTIME` criterion as a concrete scenario with expected visible results.
Include earlier-phase flows that the change can affect. Do not ask the runtime
agent to decide product requirements.

Use this prompt:

```text
Verify the phase implementation with the Godot MCP Runtime. Do not make
changes.

Target phase: <absolute phase path>
Implementation base: <base commit>
Current revision and worktree: <head and status>
Changed files:
<changed-file list>

Machine verification:
<checks and results>

Runtime scenarios:
<preconditions, actions, and expected visible results for each scenario>

Read the phase, docs/phases/README.md, all applicable AGENTS.md files, the
complete changed files, and the direct interface code needed to understand the
scenarios. Do not delegate.

Use the Godot MCP Runtime. First call get_project_info and validate every
changed GDScript. Validate changed scenes when relevant. Run the project, read
debug output, take a screenshot, and use simulate_input for every scenario.
Inspect the actual visible or runtime state after each material action. Take
more screenshots when they provide useful evidence. Read debug output again.
Stop the project after the check. Keep generated MCP files in .mcp/ and do not
commit them.

Do not infer hidden runtime state from source code. Do not edit source, add
tests, change phase status, commit, or push.

For each scenario, report the exact actions, expected result, observed result,
evidence, and one result: PASS, FAIL, or NOT_PROVEN. Use PASS only when runtime
evidence proves the expected result.

Return one outcome: RUNTIME_PASS, RUNTIME_FAILURE, or EVIDENCE_BLOCKED. List
each failed or blocked scenario with the smallest useful reproduction.
```

`RUNTIME_FAILURE` blocks review. Send the complete failure report to the same
implementation agent for repair. Then inspect the changes, run focused checks,
perform the required Godot quality gate, and ask the same runtime agent to check
the affected scenarios and all connected earlier-phase flows again.

`EVIDENCE_BLOCKED` also blocks review when a required `RUNTIME` scenario could
not run or could not produce usable evidence. Exhaust safe in-scope recovery
steps. Stop and ask the user when access, a product decision, or an external
state change is required.

## 5. Run two independent reviews

After machine and runtime verification pass, freeze the base-to-current diff.
Start the two review agents in parallel. Give both agents the same base, current
revision and worktree state, changed-file list, and verification results. Do
not give either agent the other review result.

### Code review agent

Use this prompt:

```text
Review the complete implementation diff. Do not make changes.

Phase: <absolute phase path>
Implementation base: <base commit>
Current revision and worktree: <head and status>
Changed files:
<changed-file list>

Verification:
<checks, runtime scenarios, and results>

Read project.godot, each complete changed file, and the direct callers,
consumers, scene resources, signals, input mappings, and data boundaries. Check
GDScript correctness, node lifecycle, scene-tree assumptions, invalid and
boundary state, physics and frame-loop behavior, signal connections, input
handling, resource paths, error handling, maintainability, security, and
conflicts with repository instructions. Confirm that all earlier mechanics
remain and the change does not add a later-phase mechanic. Do not delegate.

Report all supported findings with these priorities:

- P0: broad failure that can cause unrecoverable data loss, a security
  compromise, or failure to start the game.
- P1: phase-critical correctness failure with no practical path through the
  required gameplay.
- P2: material correctness, reliability, or maintainability failure.
- P3: small issue that does not block the phase.
- P4: informational and not actionable.

P0, P1, and P2 findings block the phase. Each finding must include a file,
line, exact source excerpt read during this review, observed behavior, impact,
one-line proof, and smallest valid repair. A clean report is valid. Complete
the full review after you find a blocker.

Return STATUS, SCOPE, FINDINGS, REVIEW COVERAGE, and VERIFICATION. In REVIEW
COVERAGE, list each applicable Godot and GDScript area that you checked. Do not
edit, commit, push, or delegate.
```

### Phase-contract review agent

Use this prompt:

```text
Audit the complete phase implementation. Do not make changes.

Target phase: <absolute phase path>
Phase sequence rules: <absolute path to docs/phases/README.md>
Direct prior phase: <path or none>
Implementation base: <base commit>
Current revision and worktree: <head and status>
Changed files:
<changed-file list>

Verification matrix and results:
<matrix, checks, runtime scenarios, and results>

Rebuild the phase contract from its goal, Add list, earlier-phase use, Complete
when list, Do not add list, and Test steps. Inspect every complete changed file
and the direct unchanged code needed to trace behavior.

For each material rule and completion criterion, report its owner, direct
implementation evidence, verification evidence, evidence type, and one result:
PASS, FAIL, or NOT_PROVEN. Confirm that all earlier mechanics remain and no
later mechanic was added.

Return one outcome: TECHNICAL_PASS, IMPLEMENTATION_GAPS, DECISION_REQUIRED, or
EVIDENCE_BLOCKED. TECHNICAL_PASS requires PASS for every criterion. A
NOT_PROVEN criterion requires EVIDENCE_BLOCKED. List each blocking gap with a
file, line, expected behavior, observed behavior, evidence, and smallest valid
repair.

Complete the full audit after you find a blocker. Do not edit, commit, push, or
delegate.
```

## 6. Repair and check again

Wait for both complete reports before a repair.

Combine all P0, P1, and P2 code findings and all supported implementation gaps.
Send the complete repair brief to the same implementation agent. Do not let a
review agent repair code.

After each repair:

1. Inspect the changed files.
2. Run affected focused checks.
3. Perform the complete Godot quality gate.
4. Ask the runtime verification agent to run the affected scenarios and
   connected earlier-phase flows again. Require `RUNTIME_PASS`.
5. Freeze the new diff.
6. Send the new diff to the same code review agent to check the earlier
   findings.
7. Send the new diff to the same phase-contract review agent for a complete
   contract check.

Any code or scene change makes the prior machine and runtime results invalid.
If a repair changes behavior outside the smallest valid repair, use a fresh
code review agent for one complete review of the new diff. Continue the loop
while supported in-scope blockers remain. Stop and ask the user if a repair
needs a material product decision or more authority.

Do not start a second fresh review pair by default. Use a fresh reviewer only
if an active reviewer is unavailable or cannot complete the assigned review.

## 7. Finish

The implementation is technically ready only when:

- Godot project information is available;
- all changed GDScripts and relevant scenes pass validation;
- the project runs with no related runtime error;
- runtime verification returns `RUNTIME_PASS`;
- the code review has no P0, P1, or P2 finding;
- the phase-contract review returns `TECHNICAL_PASS`; and
- each criterion is `PASS`.

Report `Phase Ready` when all technical evidence passes. Do not change phase
status unless the user asks.

The final report must include:

- target phase;
- implementation, runtime verification, and review agents used;
- implementation base and final worktree state;
- changed files;
- focused checks and Godot validation results;
- runtime scenarios, screenshots or other evidence, errors, and outcome;
- code review result;
- phase-contract criterion table and outcome;
- repaired blocking findings;
- unresolved technical evidence; and
- whether the phase is blocked or ready.
