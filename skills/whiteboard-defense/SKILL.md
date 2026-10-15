---
name: whiteboard-defense
description: >
  Interrogates the human about the branch they are about to ship, then grades their answers
  against the real diff — the Whiteboard Defense standard: you must be able to explain and
  justify any system you release, without the agent in the room.
  Trigger: /whiteboard [scope], "defend this branch", "quiz me on this", or before opening a PR on work an agent wrote.
license: Apache-2.0
metadata:
  author: krealalejo
  version: "1.0"
---

## When to Use

- Before opening a pull request on a branch an agent largely wrote.
- Before a demo, a handover, or any conversation where someone will ask *why*.
- When you have been approving diffs faster than you have been reading them.
- Any time you could not currently be pulled aside and asked to explain, at a whiteboard,
  how the thing you shipped actually works.

**Not for** reviewing code quality — that is `code-review`. This skill reviews the
*engineer's understanding*, not the code. The code may be perfect and the defense still fail.

## Critical Patterns

### The standard

Mitchell Hashimoto's bar: any engineer can be pulled aside at any moment and must be able
to explain clearly how the system they shipped to the customer works.

**Understanding, not memorization.** Nobody is expected to recall a generated function name
or an import order. The engineer *is* expected to answer why this technology and not the
other one, where the data goes, and where it breaks.

### Ask, never tell

This is the rule the whole skill rests on, and it is the one an agent will be most tempted
to break:

- **One question at a time.** Ask, stop, wait for a human answer. No batching.
- **Never reveal the answer before the human answers.** No hints, no multiple choice, no
  "as you can see in `handler.ts`…", no restating the question with the answer embedded.
- **Never soften a gap.** "I don't know" is a valid, recorded answer. Do not coach, do not
  offer a second chance, do not rephrase until the human stumbles into the answer.
- **Do not teach during the defense.** Explanations come after the last question, and only
  for the gaps.

An agent that explains the system to the human has destroyed the point of the exercise:
the human ends the session with one more generated artifact and the same empty hands.

### Deriving the questions

Questions are **derived from evidence, never invented**:

| Source | Yields |
|--------|--------|
| `rtk git diff main...HEAD` | What actually changed, and the boundaries it crosses |
| `docs/prd/<slug>.md` → *Architecture* | The chosen approach and the rejected alternative |
| The approved plan, if in session | Stated risk, rollback and order of operations |
| `AGENTS.md` / `architecture-baseline` | Which standing decision this change leans on |

Five categories. **Five to seven questions total — a hard cap**, never more:

1. **Choice** — why this approach and not the alternative the PRD named. What would have
   had to be true for the other one to win.
2. **Flow** — where the data enters, what transforms it, what crosses a module, service or
   network boundary, and where it comes to rest.
3. **Failure** — what happens under load, on retry, on a partial write, when a dependency
   is down. Which failure is silent.
4. **Trade** — what was given up, and what would make that trade wrong six months from now.
5. **Blind spot** — what is not covered by a test, and why that is acceptable.

**Forbidden question shapes**, because they test recall instead of understanding:

- "What does `processBatch()` do?"
- "How many files did this change touch?"
- "What is the name of the new column?"
- Anything answerable by reading one line of the diff aloud.

### Grading

After each answer, compare it against the diff and mark it — with evidence:

| Verdict | Meaning |
|---------|---------|
| `matches` | The answer is consistent with what the code does. Cite `file:line`. |
| `partial` | Directionally right, missing a consequence that matters. Name the missing piece. |
| `gap` | Wrong, or absent. Cite the `file:line` that contradicts it. |

Every verdict carries a `file:line` from the real diff. A verdict with no evidence is an
opinion, and this skill does not trade in opinions.

### The report

**Output the gaps only.** Never a summary of what the human got right — that is flattery,
and it is also one more generated document nobody will read.

- A `gap` on a **Choice** question means the decision was never actually made. It should
  become an ADR under `docs/adr/`, or be reopened before merge.
- A `gap` on a **Failure** question means the branch ships a failure mode nobody owns.
- If a PRD exists, append the gaps to its `## Log` section, dated.
- With no PRD, print the gaps and stop. Do not create a file nobody asked for.
- **Zero gaps on a non-trivial branch is a failure of the question set**, not a pass.
  Say so, and sharpen the questions.

### Scope and honesty

- Default scope is the current branch against `main`. A path or PRD slug narrows it.
- This skill cannot verify that a human understands anything. It compares their words to
  the source and reports the distance. That is exactly what a real whiteboard does.
- The report is for the engineer. It is not PR evidence, not a status update, and not
  something to paste anywhere.

## Workflow

1. **Scope** — resolve the target: `rtk git diff main...HEAD --stat`, plus the PRD if the
   branch names one. If the branch is empty or trivial, say so and stop.
2. **Read** — read the full diff and the PRD *Architecture* section. Enough to grade with,
   before a single question is asked.
3. **Build** — derive 5–7 questions across the five categories, weighted to what the diff
   actually did. Do not show this list to the human.
4. **Interrogate** — ask one question. Wait. Record the answer verbatim. Grade it silently.
   Next question. No commentary between questions.
5. **Report** — after the last answer, output the gaps only, each with its `file:line`
   evidence and what it implies for the merge.
6. **Record** — append gaps to the PRD `## Log` if one exists; otherwise print and stop.

## Commands

```bash
# Defend the current branch against main
/whiteboard

# Narrow to one area
/whiteboard services/device-registry

# Defend against a specific PRD
/whiteboard device-provisioning
```

## Red Flags

Answering from the diff open on screen · the agent revealing an answer before the human
answers · more than seven questions · questions about function names or file counts ·
a defense run on a branch the human did not ship · grading with no `file:line` evidence ·
a report listing what went well · zero gaps on a real branch · pasting the report into a
PR · running this instead of `code-review` and calling the code reviewed.
