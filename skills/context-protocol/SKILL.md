---
name: context-protocol
description: >
  The 60% Document & Clear protocol: at 60% of the context window, dump plan and progress
  to a markdown session file, clear the session, and resume from that file.
  Trigger: /handoff, "context is filling up", "document and clear", or automatically on reaching 60% of the context window.
license: Apache-2.0
metadata:
  author: krealalejo
  version: "1.0"
---

## When to Use

- Automatically, on reaching **60% of the context window**.
- Before starting a large new sub-task inside an already long session.
- When handing work to another person, another agent, or tomorrow's session.
- Any time you are about to be auto-compacted — get ahead of it deliberately.

## Critical Patterns

### Why 60% and not 90%

Waiting until the window is nearly full means the summary itself gets written under
pressure, and auto-compaction decides what to keep. **A summary preserves narrative and
loses decisions**; a session file preserves decisions and drops narrative — which is the
right trade. 60% leaves enough room to write a good handoff instead of a panicked one.

### The protocol

1. **Stop taking on new work.** Finish the current edit; do not start the next one.
2. **Write `docs/sessions/<YYYY-MM-DD>-<slug>.md`** containing:
   - **Mission** — one line, copied from the PRD.
   - **Done** — what is complete and verified, with how it was verified.
   - **In progress** — the exact file and line, and what the next edit is.
   - **Next steps** — ordered, specific, each actionable without re-deriving anything.
   - **Decisions made** — and the reasoning. This is the part a summary destroys.
   - **Gotchas** — dead ends, surprises, things that look wrong but are correct.
   - **Open questions** — what needs a human answer.
3. **Tell the user** the file is written and that you are clearing.
4. **`/clear`.**
5. **Resume** by reading, in order: the PRD → the session file → only the files it names.

### Rules

- Write **file paths and line numbers**, never "the auth file". The next session has no
  memory of what you were looking at.
- Record decisions with their *reasons*. "Used a queue here because the consumer can be
  slow and we need retries" survives; "used a queue" does not.
- Never write a handoff that says "continue where I left off". Say where that is.
- **Keep the main window thin between handoffs**: delegate wide searches to subagents so
  their raw output never lands in your context. The orchestrator holds conclusions.
- The session file is disposable once the PRD Log is updated and the work is merged.

## Commands

```bash
mkdir -p docs/sessions
# Write docs/sessions/<YYYY-MM-DD>-<slug>.md, then /clear, then re-read it.
```

## Red Flags

Letting auto-compaction happen mid-task · a handoff without file:line · "continue where
I left off" · decisions recorded without reasons · starting a new sub-task above 60% ·
resuming by re-reading the whole codebase instead of the session file · a session file
nobody updated as the work moved.
