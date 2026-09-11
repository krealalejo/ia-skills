# AGENTS.md — Architecture & Agent Contract

**Audience:** any AI agent entering a repository — Claude Code, Cursor, Codex, Copilot,
Gemini, or a subagent spawned by one of them.

**Authority:** this file is the *architecture* reference. `CLAUDE.md` is the *rules*
reference and outranks it on anything about permissions, git, or safety. A repo-level
`AGENTS.md` overrides this one for that repo; this file is the fallback baseline.

**Read order on entering a repo:** `CLAUDE.md` → repo `AGENTS.md` (or this one) →
the active PRD → only then any source file.

---

## 1. Architectural model

### 1.1 Shape

Event-driven serverless behind a thin API edge, with browser apps talking to it over
HTTP and a monorepo holding all of it.

```
 Browser apps (Vue/Nuxt · Angular · React, Vite)
        │  HTTPS / JSON
        ▼
 API Gateway ──► Lambda handlers (TypeScript, AWS SAM)
        │                │
        │                ├──► Aurora PostgreSQL (+PostGIS)   relational truth
        │                ├──► DynamoDB                        aggregates / hot state
        │                └──► SQS ──► worker Lambdas ──► EventBridge ──► …
        │
        └──► isolated services (Symfony/PHP, Ruby) via their own contracts
```

### 1.2 Monorepo layout (npm workspaces + Nx)

| Directory   | Contains                          | Rule |
|-------------|-----------------------------------|------|
| `apps/`     | Deployable user-facing apps       | May depend on `packages/`. Never on another app. |
| `packages/` | Shared libraries                  | No app imports, no AWS SDK, no env reads. Pure and portable. |
| `services/` | Backend services (one stack each) | Own their data. Talk to peers via queue/event/HTTP, never a shared DB. |
| `layers/`   | Lambda layers                     | Heavy deps only. Version-pinned. |
| `infra/`    | IaC (`template.yaml`, CFN)        | Every resource declared. Nothing created by hand in the console. |
| `docs/`     | Cross-cutting design docs         | `docs/prd/`, `docs/adr/`, `docs/sessions/` |

Dependency direction is one-way: `apps → packages` and `services → packages`.
An import that reverses or shortcuts this is a bug, not a shortcut — raise it.

---

## 2. Standing design decisions

These are settled. Follow them; to change one, write an ADR and get it approved.

| # | Decision | Why | Consequence for you |
|---|----------|-----|---------------------|
| D1 | **TypeScript strict everywhere.** | Types are the cheapest test. | No `any`, no `@ts-ignore`, no non-null `!` to silence the compiler. Model the type properly. |
| D2 | **Services own their data.** | Independent deploy and blast-radius containment. | Never query another service's table. Add an endpoint or an event. |
| D3 | **Postgres for relational truth, DynamoDB for aggregates/hot paths.** | Right tool per access pattern. | Pick by access pattern, not familiarity. Justify the choice in the PRD. |
| D4 | **Async by default between services.** | Backpressure and retries for free. | Prefer SQS/EventBridge over a synchronous call. Every consumer is idempotent. |
| D5 | **Infrastructure is code.** | Reproducibility, review, rollback. | No console clicks. IaC change = normal reviewed change. |
| D6 | **Shared contracts live in `packages/`.** | One definition, many consumers. | Do not redeclare a DTO/enum locally. Extend the contract package. |
| D7 | **Config via environment, secrets via Secrets Manager/SSM.** | Nothing sensitive in the repo. | Read secrets at runtime by name. Never bake one into a build. |
| D8 | **Backward-compatible contract changes only.** | Consumers deploy independently. | Additive fields, expand→migrate→contract. A breaking change needs a version. |
| D9 | **Migrations are forward-only and reversible-by-design.** | Rollback must not need a restore. | Two-phase for anything destructive. Never drop in the same release that stops writing. |
| D10 | **Tests live beside the behaviour.** | Coupling to code, not to a test tree. | Unit next to source, e2e under the app. Same commit as the change. |

---

## 3. Quality bar

- **Correctness before cleverness.** The boring solution that matches the codebase wins.
- **No speculative generality.** Build for the requirement in the PRD, not the imagined one.
- **Errors are values at boundaries.** Validate at the edge (zod or equivalent); once past
  the boundary, trust the type.
- **Observability is not optional.** Structured logs with a correlation id; no `console.log`
  in a Lambda handler.
- **Idempotency everywhere async.** Every queue/event consumer must survive redelivery.
- **Delete dead code.** Do not comment it out, do not keep `v2` beside `v1`.

---

## 4. Multi-agent pipeline — Lead Researcher pattern

For tasks too large for one context window (migrations, cross-cutting features, audits,
"how does X work across the monorepo"). For anything smaller, a single agent is cheaper
and better — do not orchestrate by reflex.

### 4.1 Roles

| Role | Count | Context | Job |
|------|-------|---------|-----|
| **Lead Researcher** (orchestrator) | 1 | Holds PRD + plan + synthesis only | Decompose, dispatch, synthesize, decide. Writes little or no code. |
| **Search Agent** | N, parallel | Disposable | Answer one closed question about the codebase. Read-only. Returns findings, never file dumps. |
| **Implementation Agent** | 1–3, serial per file-set | Narrow | Write code for one bounded slice of the approved plan. |
| **Verifier** | 1 | Fresh, adversarial | Try to break the result against the PRD. Never the agent that wrote it. |

### 4.2 Flow

```
 PRD ─► ① Lead decomposes into closed questions
         │
         ├─► ② Search agents run IN PARALLEL (read-only, one question each)
         │      "where is auth enforced?" · "what writes to orders?" · "which callers break?"
         │
         ├─► ③ Lead SYNTHESIZES findings into a plan  ──► HUMAN APPROVAL GATE
         │
         ├─► ④ Implementation agents execute the approved slices
         │      (parallel only if the file sets are disjoint — otherwise serial)
         │
         ├─► ⑤ Verifier checks result vs PRD, adversarially
         │
         └─► ⑥ Lead reports: what changed, what was left out, what is unverified
```

### 4.3 Rules for the Lead

1. **Decompose into closed questions.** "Which modules import `getDeviceById`?" is closed.
   "Look into orders" is not, and will burn a window to return nothing.
2. **Parallelize reads, serialize writes.** Search agents fan out freely. Two agents never
   hold a write lock on the same file.
3. **Findings, not transcripts.** A subagent returns a conclusion with file:line citations.
   If a subagent's raw output lands in your context, you dispatched it wrong.
4. **Never fabricate a pending result.** If an agent has not reported, say it is still running.
5. **Verify the reports.** Subagents are confidently wrong sometimes. Spot-check any finding
   the plan depends on before building on it.
6. **The approval gate at ③ is not skippable** — see the Plan Mode gate in `CLAUDE.md`.
7. **Budget up front.** State how many agents and roughly what it costs before fanning out.
   More than ~10 agents needs an explicit go-ahead.
8. **The Lead stays thin.** If the orchestrator is reading source files, it has become a
   worker and will run out of room to synthesize.

### 4.4 When NOT to use it

Single-file changes · a bug with a known location · anything under the Plan Mode
threshold · exploratory work where the question is not yet closed. Orchestration has
real overhead; one focused agent beats five vague ones.

---

## 5. Definition of done

- [ ] Every *In Scope* item in the PRD is implemented; nothing outside it was added.
- [ ] Tests written and passing; failures reported verbatim if any remain.
- [ ] Lint + format clean on the touched projects (scoped, not repo-wide).
- [ ] No new `any`, no `@ts-ignore`, no commented-out code, no stray debug logging.
- [ ] Contract changes are backward-compatible, or versioned and documented.
- [ ] Commits atomic and conventional; branch is not `main`.
- [ ] Anything deliberately left undone is stated explicitly to the user.
