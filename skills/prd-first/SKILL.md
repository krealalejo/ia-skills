---
name: prd-first
description: >
  Starts every non-trivial task from a lightweight PRD (Mission, In Scope, Out of Scope,
  Architecture) and forbids the agent from inventing features that are not in scope.
  Trigger: /prd [slug], "start a new task", "write a PRD", or the beginning of any feature, migration or refactor.
license: Apache-2.0
metadata:
  author: krealalejo
  version: "1.0"
---

## When to Use

- At the start of any feature, migration, refactor or bug-fix that is more than a one-liner.
- When a request is vague and you need the scope pinned before writing code.
- When an agent has started inventing adjacent features and needs pulling back.
- Skip only for a genuinely trivial change you could describe in one sentence.

## Critical Patterns

### The PRD is the contract

- Lives at `docs/prd/<slug>.md`, copied from `assets/PRD.md` in this skill folder.
- Has exactly four mandatory sections: **Mission**, **In Scope**, **Out of Scope**,
  **Architecture**. Verification and Log are strongly recommended.
- Carries `status: draft | approved | in-progress | done | abandoned` in frontmatter.
  **No code is written while `status: draft`.** Approval is a human act, recorded in
  `approved_by`.

### Scope invention is the failure this prevents

- **In Scope is exhaustive and binding.** If it is not listed, it does not get built.
- The classic violations, all forbidden unless explicitly listed: adding a password-reset
  or account-recovery flow, adding caching, adding retry logic, adding rate limiting,
  adding a new dependency, "while I was in there" refactors, extra endpoints, extra
  config options, speculative abstraction for a future requirement.
- **Out of Scope must be populated.** An empty Out of Scope section is a failed section —
  its job is to name the things a reasonable agent would otherwise add on its own.
- Silence in the PRD means *"not now"*, never *"use your judgement"*.
- If something out of scope turns out to be genuinely required: **stop and ask.** Do not
  implement it, and do not implement a smaller version of it.

### Writing a good one

- **Mission** is the "why", max five sentences, restatable by someone with no context.
  It ends with a single observable *Done when* condition — "a row created in region X
  appears in the list within 5s", not "the feature works".
- **In Scope** items are independently verifiable checkboxes, not themes.
- **Architecture** names the approach, the one real alternative you rejected and why, the
  files touched, data-model and contract changes, new dependencies, risk and rollback.
- **Log** is appended as work proceeds — it feeds the handoff in `context-protocol`.

### How it interacts with the rest

- `plan-gate` decides whether a plan is needed *within* an approved PRD.
- `context-protocol` resumes from the PRD plus the session file after a `/clear`.
- `agent-pipeline` treats the PRD as the single source of truth a Lead Researcher
  decomposes and a Verifier checks against.

## Commands

```bash
# Start a task
mkdir -p docs/prd docs/sessions
cp skills/prd-first/assets/PRD.md docs/prd/<slug>.md

# Then: fill Mission / In Scope / Out of Scope / Architecture,
#       set approved_by, flip status to `approved`.
```

## Red Flags

Coding from a `draft` PRD · an empty Out of Scope section · an In Scope item that is not
verifiable · a Done-when that says "works correctly" · a feature in the diff that is not
in the PRD · silently implementing a "small version" of an out-of-scope item · a PRD
written after the code.
