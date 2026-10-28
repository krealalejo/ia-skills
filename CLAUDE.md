# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

The source of truth for krealalejo's whole agentic workspace, not only skills: context (global rules, templates), skills, subagents, hooks and guardrails, the status line, and the reference skills for building MCP servers, LLM apps and evals.

`~/.claude` is a working copy. When the two disagree, this repo wins, after anything worth keeping has been ported back. There is **one install path**: `skills/bootstrap-workspace/assets/install.sh`. There is no plugin packaging on purpose: a plugin cannot install global rules, templates, git hooks or the status line, and it would namespace every skill. `npx skills add krealalejo/ia-skills` stays available for other people who only want the skills.

## Layout by layer

| Layer | Lives in | Installs to |
| --- | --- | --- |
| Context | `skills/bootstrap-workspace/assets/global-*.md`, `skills/prd-first/assets/`, `skills/architecture-baseline/assets/` | `~/.claude/CLAUDE.md`, `AGENTS.md`, `templates/` |
| Skills | `skills/<name>/SKILL.md` | `~/.claude/skills/<name>/` |
| Subagents | `agents/<name>.md` | `~/.claude/agents/` |
| Hooks | `skills/guardrails/assets/`, `skills/context-protocol/assets/session-resume.sh` | `~/.claude/hooks/`, `~/.claude/githooks/`, wired in `settings.json` |
| Status line | `skills/statusline/assets/statusline.sh` | `~/.claude/statusline.sh` |
| MCP, API, evals | reference skills `mcp-server`, `llm-apps`, `llm-evals` | loaded on demand |
| CI | `.github/workflows/validate.yml` | runs on every PR |

Hooks and scripts stay inside the skill that documents them (`assets/`), so a skill installed on its own still carries what it describes.

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
- Bump `metadata.version` when a skill's behaviour changes.

### Companion and asset files

- **`assets/`** holds files the skill installs or copies — templates, scripts, hooks. Precedent: `add-readme/assets/template.md`, `prd-first/assets/PRD.md`, `guardrails/assets/`, `context-protocol/assets/session-resume.sh`.
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
| `context-protocol`       | Context window reaches 60%                        | Document & Clear: session file, `/clear`, resume from the file. Ships the `SessionStart` resume hook. |
| `agent-pipeline`         | Work too large for one context window             | Lead Researcher pattern: decompose, parallel search agents, synthesize, verify. Dispatches the subagents below. |
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

### AI engineering skills

| Skill        | Loads when                                                  | Focus                                                                 |
| ------------ | ----------------------------------------------------------- | --------------------------------------------------------------------- |
| `mcp-server` | Building or reviewing an MCP server, adding a tool to one   | Few whole-task tools, typed inputs, actionable errors, transports, auth |
| `llm-apps`   | Code calling `@anthropic-ai/sdk` or the Claude Agent SDK    | Simplest surface, bounded tool loop, caching, structured outputs, cost |
| `llm-evals`  | Changing a prompt, model or tool set; a new skill description | Golden datasets, calibrated judges, CI regressions, trigger evals     |

Overlapping pairs, resolved: **`aws` vs `cloud-infra`** — `cloud-infra` is templates, policies and deploys; `aws` is the SDK and credentials in running code. A function with its own template loads both. **`css` vs `vue`/`react`** — component styles load `css` too. **`llm-apps` vs the bundled `claude-api`** — `llm-apps` holds the standing decisions, `claude-api` the current API surface; load both. **`mcp-server` vs `serverless-api`** — an MCP server over HTTP loads both.

### Setup skills

| Skill                 | Trigger                     | Purpose                                                                            |
| --------------------- | --------------------------- | ---------------------------------------------------------------------------------- |
| `guardrails`          | `/guardrails`               | Bash guard + global git hooks. Blocks destructive commands, protected-branch writes, secret commits, failing tests. |
| `bootstrap-workspace` | `/bootstrap-workspace`      | Restores the whole `~/.claude` workspace from this repo. `install.sh --dry-run` previews, `scripts/check-drift.sh` audits. |
| `statusline`          | `/statusline`               | Two-line status bar: model, context window, 5-hour and 7-day usage, cost, git state. |

## Subagents

Each file in `agents/` is a Claude Code subagent: YAML frontmatter (`name` matching the file name, a routing `description`, a restricted `tools` list, `model`) followed by the system prompt. Read-only roles get no `Edit` or `Write`, so the guarantee is mechanical.

| Agent                  | Used by          | Tools                               | Model  | Role                                                             |
| ---------------------- | ---------------- | ----------------------------------- | ------ | ---------------------------------------------------------------- |
| `pipeline-researcher`  | `agent-pipeline` | Read, Grep, Glob, Bash              | sonnet | Answers one closed question, read-only, with citations           |
| `pipeline-implementer` | `agent-pipeline` | Read, Edit, Write, Grep, Glob, Bash | opus   | Builds one approved slice, touching only its files               |
| `pipeline-verifier`    | `agent-pipeline` | Read, Grep, Glob, Bash              | opus   | Adversarial check against the PRD; reports failures, never edits |
| `security-reviewer`    | `agent-pipeline`, any merge touching a trust boundary | Read, Grep, Glob, Bash | opus | Injection, access control, secrets, IaC, LLM tool abuse; exploit scenario per finding |
| `docs-writer`          | `agent-pipeline` last slice | Read, Edit, Write, Grep, Glob, Bash | sonnet | Brings markdown docs in line with the diff; edits `*.md` only |

## Hooks

| Hook | Event | Source | Does |
| --- | --- | --- | --- |
| Bash guard | `PreToolUse` (Bash) | `guardrails/assets/guard-bash.sh` | Blocks destructive, protected-branch, secret and deploy commands. Per-repo opt-out `git config --local claude.guardBash false`, settable by the human only. |
| Session resume | `SessionStart` | `context-protocol/assets/session-resume.sh` | Points the new session at the newest `docs/sessions/*.md`, so multi-day work resumes from the file. |
| Git hooks | `pre-commit`, `pre-push` | `guardrails/assets/githooks/` | Same rules for humans; opt-in with `install.sh --git-hooks`. |

The installer wires the first two into `~/.claude/settings.json` idempotently and leaves every other key and hook in place.

## README template

`skills/add-readme/assets/template.md` is the canonical structure enforced by the `add-readme` skill. It requires: title, description, `**Stack:**` line, Prerequisites, Quick Start, Commands table, Pages/Endpoints table, Architecture (Mermaid diagram), Source layout, Configuration table, Deployment paragraph.

## Adding a new skill

1. Create `skills/<name>/SKILL.md` following the anatomy above.
2. Ensure the `name` frontmatter field matches the folder name.
3. Include a clear trigger phrase in `description` and a `## Commands` section (command skills) or a `## Red Flags` section (reference skills).
4. For a reference skill, give the description a negative trigger so it does not load for unrelated work.
5. Add a row to the matching table in this file, and to `README.md`.
6. Run `python3 scripts/validate-skills.py` — it checks every skill is discoverable and well-formed.

## Adding a new agent

1. Create `agents/<name>.md` with `name` matching the file name, a `description` that says when to use it and when not to, and the narrowest `tools` list that does the job.
2. Add a row to the Subagents table in this file and in `README.md`.
3. If a skill dispatches it, name it in that skill.
4. Run `python3 scripts/validate-skills.py`.

## Adding a new hook

1. Put the script in the `assets/` of the skill that documents it, executable, passing `shellcheck -S warning`.
2. Copy and wire it in `install.sh` with the same idempotent `jq` pattern, and add it to `scripts/check-drift.sh`.
3. Add a row to the Hooks table and a smoke test to `.github/workflows/validate.yml`.

## Changing `~/.claude` directly

Port it back here before anything else. `scripts/check-drift.sh` lists what differs, what is missing and what exists only in `~/.claude`; never run `install.sh` over a "differs" you have not read, because the repo version wins.

## Validating

```bash
python3 scripts/validate-skills.py
GUARD=skills/guardrails/assets/guard-bash.sh \
  python3 skills/guardrails/assets/test/run.py skills/guardrails/assets/test/cases.json
scripts/check-drift.sh
CLAUDE_CONFIG_DIR=/tmp/claude-test skills/bootstrap-workspace/assets/install.sh
```

CI (`.github/workflows/validate.yml`) runs all of these plus `shellcheck` on every PR.
