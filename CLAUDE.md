# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A collection of custom AI skills installable via `npx skills add krealalejo/ia-skills`. Each skill lives in `skills/<name>/SKILL.md` — a structured markdown file with YAML frontmatter that defines how an AI agent should behave when triggered.

It is also the **backup and source of truth** for the full `~/.claude` workspace configuration: global rules, architecture reference, templates and guardrail hooks. `~/.claude` is a working copy; when the two disagree, this repo wins. Restore with `skills/bootstrap-workspace/assets/install.sh`.

## Two kinds of skill

| Kind | Invoked by | Has `## Commands` | Examples |
| --- | --- | --- | --- |
| **Command skill** | An explicit slash command | Yes | `git-commit`, `code-review`, `add-readme` |
| **Reference skill** | Loaded on demand when the agent enters the domain | Only if a real shell command exists | `react`, `postgres`, `plan-gate` |

A reference skill's `description` is a **router**: it must say when to load *and when not to*. That one line is all that sits in context until the skill is actually needed, which is the entire point of keeping domain detail out of `CLAUDE.md`.

## Skill file anatomy

Every `SKILL.md` follows this structure:

```
---
name: <skill-name>
description: >
  One-line purpose + trigger phrase(s).
license: Apache-2.0
metadata:
  author: krealalejo
  version: "x.y"
---

## When to Use
## Critical Patterns
## Workflow          (optional, for multi-step command skills)
## Code Examples     (optional)
## Commands          (command skills; reference skills only if a real command exists)
## Red Flags         (reference skills: the patterns that should stop a review)
## Resources         (optional)
```

- **`name`** must match the folder name under `skills/`.
- **`description`** must include the trigger phrase(s) so the agent knows when to activate the skill. For reference skills, include a negative trigger too (`Not for X, use \`y\``).
- **Commands** section documents the slash command(s) the skill responds to.
- **Red Flags** closes a reference skill with the concrete anti-patterns to catch.
- Reference skills keep code examples inline under their `### ` subsections rather than in a separate `## Code Examples` block — the examples belong next to the rule they illustrate.

### Companion and asset files

- **`assets/`** holds files the skill installs or copies — templates, scripts, hooks. Precedent: `add-readme/assets/template.md`, `prd-first/assets/PRD.md`, `guardrails/assets/`.
- **A sibling `.md`** holds a second large reference area within one domain, and must be linked from `SKILL.md`. Precedent: `php/symfony.md`.

## Available skills

### Command skills

| Skill               | Trigger                           | Purpose                                                                                                          |
| ------------------- | --------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| `git-commit`        | `/commit [ticket-id]`             | Atomic conventional commits (`type(scope): msg`, max 300 chars). Always prefixes git commands with `rtk`.        |
| `code-review`       | `/review [task_description]`      | Diffs against `main`, inserts block comments above problematic lines with Affected Lines / Problem / Suggestion. |
| `typescript-review` | `/typescript [file]`              | Deep TS type review: overloads, generics, discriminated unions, exhaustiveness, utility types.                   |
| `add-readme`        | `/add-readme [context]`           | Creates/updates README following the template in `skills/add-readme/assets/template.md`.                         |
| `release-commit`    | `/release-commit`                 | Creates empty summary commit (`summary: msg`) with plain-English description of all branch changes vs `main`.    |
| `playwright-web`    | `/playwright-web [url] [flow]`    | Generates Playwright E2E tests for web UI flows and browser interactions.                                        |
| `playwright-api`    | `/playwright-api [method] [path]` | Generates Playwright E2E tests for HTTP API endpoints using the request fixture.                                 |

### Governance skills

| Skill                    | Loads when                                       | Purpose                                                                                     |
| ------------------------ | ------------------------------------------------ | ------------------------------------------------------------------------------------------- |
| `prd-first`              | Starting any non-trivial task                     | PRD with Mission / In Scope / Out of Scope / Architecture. Forbids inventing out-of-scope features. |
| `plan-gate`              | A change touching 3+ files, deps, data or infra   | Written plan + explicit approval before editing. Six required parts.                        |
| `context-protocol`       | Context window reaches 60%                        | Document & Clear: session file, `/clear`, resume from the file.                             |
| `agent-pipeline`         | Work too large for one context window             | Lead Researcher pattern: decompose, parallel search agents, synthesize, verify.              |
| `architecture-baseline`  | Entering a repo, or a design decision needs a precedent | Ten standing decisions, monorepo boundaries, quality bar, definition of done.          |

### Domain reference skills

| Skill            | Loads when                                    | Focus                                                            |
| ---------------- | --------------------------------------------- | ---------------------------------------------------------------- |
| `react`          | `.tsx`/`.jsx`, hooks, component tests          | State ownership, effects, data fetching, a11y, RTL               |
| `vue`            | `.vue`, composables, Pinia stores, Nuxt        | `<script setup>`, `ref` over `reactive`, composable cleanup       |
| `javascript`     | Framework-free `.js`/`.mjs`                    | ESM, safe DOM, event delegation, `AbortController`                |
| `css`            | Stylesheets, `<style>` blocks, design tokens   | Strict BEM, mobile-first, custom-property theming                 |
| `serverless-api` | Handlers, endpoints, queue/event consumers     | Thin handlers, edge validation, error mapping, idempotency        |
| `php`            | Any PHP; `symfony.md` for the framework        | PHP 8.x strict types, enums, readonly; Symfony DI, Doctrine       |
| `postgres`       | SQL, schema, indexes, migrations               | Indexing, keyset pagination, expand/migrate/contract              |
| `aws`            | SDK calls and credentials in application code  | Never hardcode, least privilege, SDK v3, retries                  |
| `cloud-infra`    | IaC, IAM policies, CI pipelines                | Least privilege, environment isolation, deploy safety             |

Overlapping pairs, resolved: **`aws` vs `cloud-infra`** — `cloud-infra` is templates, policies and deploys; `aws` is the SDK and credentials in running code. A function with its own template loads both. **`css` vs `vue`/`react`** — component styles load `css` too.

### Setup skills

| Skill                 | Trigger                     | Purpose                                                                            |
| --------------------- | --------------------------- | ------------------------------------------------------------------------------------ |
| `guardrails`          | `/guardrails`               | Bash guard + global git hooks. Blocks destructive commands, protected-branch writes, secret commits, failing tests. |
| `bootstrap-workspace` | `/bootstrap-workspace`      | Restores the whole `~/.claude` workspace from this repo. `install.sh --dry-run` previews. |
| `statusline`          | `/statusline`               | Two-line status bar: model, context window, 5-hour and 7-day usage, cost, git state. |

## README template

`skills/add-readme/assets/template.md` is the canonical structure enforced by the `add-readme` skill. It requires: title, description, `**Stack:**` line, Prerequisites, Quick Start, Commands table, Pages/Endpoints table, Architecture (Mermaid diagram), Source layout, Configuration table, Deployment paragraph.

## Adding a new skill

1. Create `skills/<name>/SKILL.md` following the anatomy above.
2. Ensure the `name` frontmatter field matches the folder name.
3. Include a clear trigger phrase in `description` and a `## Commands` section (command skills) or a `## Red Flags` section (reference skills).
4. For a reference skill, give the description a negative trigger so it does not load for unrelated work.
5. Add a row to the matching table in this file, and a section in `README.md`.
6. Run `python3 scripts/validate-skills.py` — it checks every skill is discoverable and well-formed.

## Validating

```bash
python3 scripts/validate-skills.py            # structure, frontmatter, table coverage
GUARD=skills/guardrails/assets/guard-bash.sh \
  python3 skills/guardrails/assets/test/run.py skills/guardrails/assets/test/cases.json
```
