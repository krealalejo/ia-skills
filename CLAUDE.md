# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A collection of custom AI skills installable via `npx skills add krealalejo/ia-skills`. Each skill lives in `skills/<name>/SKILL.md` — a structured markdown file with YAML frontmatter that defines how an AI agent should behave when triggered.

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
## Workflow          (optional, for multi-step skills)
## Code Examples     (optional)
## Commands
```

- **`name`** must match the folder name under `skills/`.
- **`description`** must include the trigger phrase(s) so the agent knows when to activate the skill.
- **Commands** section documents the slash command(s) the skill responds to.

## Available skills

| Skill               | Trigger                           | Purpose                                                                                                          |
| ------------------- | --------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| `git-commit`        | `/commit [ticket-id]`             | Atomic conventional commits (`type(scope): msg`, max 300 chars). Always prefixes git commands with `rtk`.        |
| `code-review`       | `/review [task_description]`      | Diffs against `main`, inserts block comments above problematic lines with Affected Lines / Problem / Suggestion. |
| `typescript-review` | `/typescript [file]`              | Deep TS type review: overloads, generics, discriminated unions, exhaustiveness, utility types.                   |
| `add-readme`        | `/add-readme [context]`           | Creates/updates README following the template in `skills/add-readme/assets/template.md`.                         |
| `release-commit`    | `/release-commit`                 | Creates empty summary commit (`summary: msg`) with plain-English description of all branch changes vs `main`.    |
| `playwright-web`    | `/playwright-web [url] [flow]`    | Generates Playwright E2E tests for web UI flows and browser interactions.                                        |
| `playwright-api`    | `/playwright-api [method] [path]` | Generates Playwright E2E tests for HTTP API endpoints using the request fixture.                                 |

## README template

`skills/add-readme/assets/template.md` is the canonical structure enforced by the `add-readme` skill. It requires: title, description, `**Stack:**` line, Prerequisites, Quick Start, Commands table, Pages/Endpoints table, Architecture (Mermaid diagram), Source layout, Configuration table, Deployment paragraph.

## Adding a new skill

1. Create `skills/<name>/SKILL.md` following the anatomy above.
2. Ensure the `name` frontmatter field matches the folder name.
3. Include a clear trigger phrase in `description` and a `## Commands` section.
