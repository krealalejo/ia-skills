---
name: architecture-baseline
description: >
  The authoritative architecture reference for any AI agent entering a repository:
  monorepo boundaries, ten standing design decisions, quality bar and definition of done.
  Trigger: entering an unfamiliar repository, "what are our conventions", setting up AGENTS.md / CLAUDE.md, or a design decision that needs a precedent.
license: Apache-2.0
metadata:
  author: krealalejo
  version: "1.0"
---

## When to Use

- On entering a repository, before reading any source file.
- When a design decision needs a precedent rather than a fresh opinion.
- When bootstrapping `CLAUDE.md` and `AGENTS.md` for a new repo — templates are in
  `assets/` in this skill folder.
- When reviewing whether a change respects module boundaries.

**Read order on entering a repo:** `CLAUDE.md` (rules) → `AGENTS.md` (architecture) →
the active PRD → only then any source file.

## Critical Patterns

### Two files, two jobs

| File | Holds | Rule |
|------|-------|------|
| `CLAUDE.md` | Rules: safety, git policy, workflow preferences | Concise. ~150 lines max. Never credentials, never a technical manual. |
| `AGENTS.md` | Architecture: structure, boundaries, design decisions | The reference for *any* agent — Claude, Cursor, Codex. |

Domain detail belongs in neither — it goes in a skill, loaded on demand. That separation
is what keeps the always-loaded context small.

### Monorepo boundaries

| Directory | Contains | Rule |
|-----------|----------|------|
| `apps/` | Deployable apps | May depend on `packages/`. Never on another app. |
| `packages/` | Shared libraries | No app imports, no cloud SDK, no env reads. Pure and portable. |
| `services/` | Backend services | Own their data. Talk to peers via queue/event/HTTP, never a shared DB. |
| `infra/` | IaC | Every resource declared. Nothing created by hand in a console. |
| `docs/` | Design docs | `docs/prd/`, `docs/adr/`, `docs/sessions/` |

Dependency direction is one-way: `apps → packages` and `services → packages`. An import
that reverses or shortcuts this is a bug, not a shortcut — raise it.

### Ten standing decisions

These are settled. Follow them; to change one, write an ADR and get it approved.

| # | Decision | Consequence |
|---|----------|-------------|
| D1 | Strict typing everywhere | No `any`, no ignore-comments, no non-null assertions to silence the compiler. |
| D2 | Services own their data | Never query another service's table. Add an endpoint or an event. |
| D3 | Relational store for truth, key-value for aggregates/hot paths | Pick by access pattern, not familiarity. Justify in the PRD. |
| D4 | Async by default between services | Prefer a queue/event over a synchronous call. Every consumer is idempotent. |
| D5 | Infrastructure is code | No console clicks. IaC change = normal reviewed change. |
| D6 | Shared contracts live in `packages/` | Do not redeclare a DTO or enum locally. Extend the contract package. |
| D7 | Config via environment, secrets via a secrets manager | Read secrets at runtime by name. Never bake one into a build. |
| D8 | Backward-compatible contract changes only | Additive fields; expand → migrate → contract. A break needs a version. |
| D9 | Migrations forward-only, reversible by design | Two-phase for anything destructive. Rollback must not need a restore. |
| D10 | Tests live beside the behaviour | Same commit as the change. |

### Quality bar

- **Correctness before cleverness.** The boring solution that matches the codebase wins.
- **No speculative generality.** Build the requirement in the PRD, not the imagined one.
- **Errors are values at boundaries.** Validate at the edge; past it, trust the type.
- **Observability is not optional.** Structured logs with a correlation id.
- **Idempotency everywhere async.** Every consumer must survive redelivery.
- **Delete dead code.** Do not comment it out; do not keep `v2` beside `v1`.

### Definition of done

- [ ] Every In Scope item implemented; nothing outside it added.
- [ ] Tests written and passing; failures reported verbatim if any remain.
- [ ] Lint and format clean on the touched projects, scoped not repo-wide.
- [ ] No new escape hatches in the type system, no commented-out code, no debug logging.
- [ ] Contract changes backward-compatible, or versioned and documented.
- [ ] Commits atomic and conventional; branch is not `main`.
- [ ] Anything deliberately left undone is stated explicitly to the user.

## Commands

```bash
cp skills/architecture-baseline/assets/CLAUDE.md ./CLAUDE.md
cp skills/architecture-baseline/assets/AGENTS.md ./AGENTS.md
```

## Red Flags

An app importing another app · a service reading another service's tables · a DTO
redeclared locally · a resource created by hand in a console · a breaking contract change
with no version · architecture detail pasted into `CLAUDE.md` · a design decision made
without checking whether D1-D10 already settled it.
