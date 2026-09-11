---
slug: <kebab-case-id>
status: draft        # draft | approved | in-progress | done | abandoned
owner: <name>
created: <YYYY-MM-DD>
approved_by:         # REQUIRED before any code is written
---

# PRD — <Title>

> Copy to `docs/prd/<slug>.md`. Nothing gets implemented while `status: draft`.
> Delete every `<…>` placeholder and every instructional quote line before approval.

## Mission

<One paragraph, maximum five sentences. What changes for the user or the system, and
why now. Written so someone with no context can restate the goal. No solution design
here — this is the "why", not the "how".>

**Done when:** <a single observable condition. "A device row created in region X appears
in the backoffice list within 5s." Not "the feature works".>

---

## In Scope

> Everything the agent is allowed to build. This list is exhaustive and binding.
> Each item is independently verifiable. If it is not on this list, it does not exist.

- [ ] <Item 1 — concrete and testable>
- [ ] <Item 2>
- [ ] <Item 3>

---

## Out of Scope

> Name the things a reasonable agent would otherwise add on its own. Being explicit here
> is what prevents scope invention — an empty section is a failed section.

- <e.g. Password reset / account recovery flow>
- <e.g. Rate limiting, caching, retry policy>
- <e.g. Migrating the remaining legacy callers>
- <e.g. Any UI beyond the single screen named above>
- <e.g. New dependencies of any kind>
- <e.g. Refactoring code that is merely nearby>

**Rule:** if something here turns out to be genuinely required, **stop and ask**.
Do not implement it, and do not implement a smaller version of it.

---

## Architecture

**Approach:** <2–4 sentences. The chosen design and the one real alternative you rejected,
with the reason.>

**Touches:**

| Path | Change |
|------|--------|
| `<workspace/file>` | <what and why> |

**Data model:** <schema/table/index changes, or "none". Migration strategy if destructive.>

**Contracts:** <API or shared-type changes, or "none". State backward compatibility.>

**Dependencies:** <new packages, or "none" — new deps require explicit approval.>

**Risk & rollback:** <what can break, how you detect it, how you undo it.>

---

## Verification

| # | Check | How | Result |
|---|-------|-----|--------|
| 1 | <In-Scope item 1 works> | <exact command or steps> | |
| 2 | <nothing regressed> | <scoped test command> | |

---

## Log

> Appended as work proceeds. Feeds the Document & Clear handoff at 60% context.

- `<YYYY-MM-DD>` — <decision, blocker, or deviation and its reason>
