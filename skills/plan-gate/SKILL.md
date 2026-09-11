---
name: plan-gate
description: >
  Forces a written plan and explicit human approval before any change that touches three
  or more files, a dependency, a data model, infrastructure, or crosses a module boundary.
  Trigger: /plan, "plan this", or automatically before starting any multi-file change, migration, refactor or rename.
license: Apache-2.0
metadata:
  author: krealalejo
  version: "1.0"
---

## When to Use

Produce a plan and **wait for approval** before editing, whenever the change:

- touches **3 or more files**, or
- adds, removes or upgrades a **dependency**, or
- alters a **data model** — SQL schema, DynamoDB keys, an API contract, a shared type, or
- changes **infrastructure** — IaC templates, IAM, CI, or
- is a **migration, refactor or rename** crossing a module or workspace boundary.

Below the threshold, just do the work. A plan for a one-line fix is noise.

## Critical Patterns

### What the plan must contain

1. **Goal** — one sentence, traceable to an In Scope item in the PRD.
2. **Files to touch** — the actual list, with what changes in each. If you cannot list
   them, you have not finished exploring and are not ready to plan.
3. **Order of operations** — what has to land before what, and why.
4. **Risk** — what breaks if this is wrong, and how it would show up.
5. **Rollback** — how to undo it. "Revert the commit" only counts if no migration ran.
6. **Verification** — the exact command or steps that prove it worked.

### Rules

- **The gate is not skippable.** Not by an agent deciding the change is simple, not by
  splitting one change into several sub-threshold edits to slip under the limit.
- Counting is honest: a rename touching 9 files is a 9-file change, not one.
- **Explore before planning, never during.** Read the code, then write the plan. A plan
  full of "investigate whether…" is a research task, not a plan.
- **Approval is explicit.** Silence is not approval. Neither is the user answering a
  different question.
- If the plan changes materially mid-execution, stop and re-approve. Do not drift.
- Below-threshold work that *reveals* a threshold-crossing change stops and plans.

### Scaling to bigger work

If the plan needs more than roughly eight steps, or spans more than two domains, it is a
candidate for `agent-pipeline` — decompose it, research in parallel, then synthesize one
plan and bring *that* to the gate.

## Red Flags

Editing before approval · a plan with no file list · a plan with no rollback · splitting
a change to dodge the threshold · "I'll plan as I go" · re-planning silently after the
approved plan stopped matching reality · a plan that restates the request instead of
describing the change.
