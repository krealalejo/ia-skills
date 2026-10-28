---
name: agent-pipeline
description: >
  The Lead Researcher multi-agent pattern: an orchestrator decomposes a task into closed
  questions, fans out parallel read-only search agents, synthesizes a plan, then delegates
  implementation and adversarial verification.
  Trigger: /pipeline, "orchestrate this", "use subagents", or a task too large for one context window (migration, cross-cutting feature, codebase audit).
license: Apache-2.0
metadata:
  author: krealalejo
  version: "1.1"
---

## When to Use

Use it for work too large for one context window:

- A migration touching many modules.
- A cross-cutting feature spanning frontend, API and data.
- A codebase audit or "how does X actually work across the repo".
- Any task where the research alone would fill the window.

**Do not use it** for: a single-file change, a bug with a known location, anything below
the `plan-gate` threshold, or exploratory work where the question is not yet closed.
Orchestration has real overhead — one focused agent beats five vague ones.

## Critical Patterns

### Roles

| Role | Count | Context | Subagent | Job |
|------|-------|---------|----------|-----|
| **Lead Researcher** | 1 | PRD + plan + synthesis only | the main session | Decompose, dispatch, synthesize, decide. Writes little or no code. |
| **Search Agent** | N, parallel | Disposable | `pipeline-researcher` | Answer one closed question. Read-only. Returns findings, never file dumps. |
| **Implementation Agent** | 1-3 | Narrow | `pipeline-implementer` | Write code for one bounded slice of the approved plan. |
| **Verifier** | 1 | Fresh, adversarial | `pipeline-verifier` | Try to break the result against the PRD. Never the agent that wrote it. |
| **Security Reviewer** | 0-1 | Fresh, adversarial | `security-reviewer` | Extra verifier when the change touches auth, user input, secrets, IaC or dependencies. |
| **Docs Writer** | 0-1 | Narrow | `docs-writer` | Last slice: bring README, CLAUDE.md and the PRD log in line with the diff. |

The subagent files live in this repo's `agents/` and install to `~/.claude/agents/`. Each one
restricts its own tools: researchers and verifiers cannot edit, so the read-only guarantee is
mechanical, not a promise in the prompt. Dispatch by name; never fall back to a general-purpose
agent for a role that has a file.

### Flow

```
 PRD -> (1) Lead decomposes into closed questions
         |
         |-> (2) Search agents run IN PARALLEL (read-only, one question each)
         |       "where is auth enforced?" - "what writes to orders?" - "which callers break?"
         |
         |-> (3) Lead SYNTHESIZES findings into a plan  --> HUMAN APPROVAL GATE
         |
         |-> (4) Implementation agents execute the approved slices
         |       (parallel only if the file sets are disjoint - otherwise serial)
         |
         |-> (5) Verifier checks result vs PRD, adversarially
         |       (+ security-reviewer in parallel when the change crosses a trust boundary)
         |       verifier FAIL -> back to (4) with its findings, never "fix it yourself" in the Lead
         |
         |-> (5b) docs-writer updates the docs for the final diff
         |
         |-> (6) HUMAN DEFENSE: /whiteboard - the human explains the branch, graded against the diff
         |
         `-> (7) Lead reports: what changed, what was left out, what is unverified, the defense gaps
```

### Rules for the Lead

1. **Decompose into closed questions.** "Which modules import `getProductById`?" is
   closed. "Look into products" is not, and will burn a window returning nothing.
2. **Parallelize reads, serialize writes.** Search agents fan out freely. Two agents
   never hold a write lock on the same file.
3. **Findings, not transcripts.** A subagent returns a conclusion with `file:line`
   citations. If a subagent's raw output lands in your context, you dispatched it wrong.
4. **Never fabricate a pending result.** If an agent has not reported, say it is still
   running. Never predict what it will say.
5. **Verify the reports.** Subagents are confidently wrong sometimes. Spot-check any
   finding the plan depends on before building on it.
6. **The approval gate at step 3 is not skippable** — see `plan-gate`. Neither is the
   defense at step 6: a branch nobody can explain does not get a PR — see `whiteboard-defense`.
7. **Budget up front.** State how many agents and roughly what it costs before fanning
   out. More than ~10 agents needs an explicit go-ahead.
8. **The Lead stays thin.** If the orchestrator is reading source files, it has become a
   worker and will run out of room to synthesize.

### Verification is a separate agent

The agent that wrote the code is the worst possible reviewer of it — it will confirm its
own assumptions. The Verifier starts fresh, reads the PRD and the diff, and tries to find
the case where it breaks. It reports failures, not approval.

## Red Flags

Orchestrating a task one agent could do · open-ended subagent prompts · the Lead reading
source files · raw subagent output in the orchestrator's context · skipping the approval
gate between synthesis and implementation · the author verifying their own work · a general-purpose agent doing a role that has its own subagent file ·
claiming a result from an agent that has not reported · unbounded fan-out with no budget.
