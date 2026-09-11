# 🧠 AI Skills Repository

A curated collection of custom AI skills designed to enhance software engineering workflows, automation, and development best practices.

## 🚀 Included Skills

Two kinds of skill live here:

- **Command skills** — invoked explicitly with a slash command (`/commit`, `/review`).
- **Reference skills** — passive domain knowledge loaded on demand when the agent
  enters that domain. No command; they simply apply when relevant.

### ⚙️ Command Skills

### 🛠️ git-commit

**Purpose**: Automates the creation of atomic commits following the [Conventional Commits](https://www.conventionalcommits.org/) standard.

**Key Features**:

- **Atomic Commits**: Automatically groups changes logically by module or functionality.
- **Ticket Support**: Integrates ticket IDs (e.g., Jira, GitHub Issues) into the commit scope.
- **Character Limit**: Ensures concise messages (max 300 characters).

### 🔍 code-review

**Purpose**: Performs a comprehensive code review of the current branch against `main`, focusing on TypeScript, best practices, and SOLID principles.

**Key Features**:

- **Automatic Diff**: Compares implementation with the `main` branch.
- **In-Line Suggestions**: Adds comments directly above the code with problem descriptions and corrections.
- **Clean Code & SOLID**: Enforces high-quality architectural standards.

### 🔷 typescript-review

**Purpose**: Specialized review for TypeScript types and advanced patterns.

**Key Features**:

- **Advanced Patterns**: Enforces function overloads, generics, type predicates, and mapped types.
- **Exhaustiveness Checking**: Ensures all cases in unions are handled using the `never` type.
- **Utility Types**: Promotes the use of `Pick`, `Omit`, `Record`, and other built-in utilities.
- **Flexible Scope**: Supports individual file review or automatic detection via `git status`.

### 🏷️ release-commit

**Purpose**: Creates an empty summary commit with a plain-English description of all changes introduced in the current branch vs `main`.

**Key Features**:

- **Empty Commit**: No files staged or modified — purely a human-readable changelog entry.
- **Branch Summary**: Analyzes the full diff (`main...HEAD`) and synthesizes a single concise sentence.
- **Fixed Format**: Commit message always follows `summary: <message>` (max 300 characters).

### 🎭 playwright-web

**Purpose**: Generates Playwright E2E tests for web UI flows and browser interactions.

**Key Features**:

- **Pre-research phase**: Greps `data-test-id` selectors, reads unit tests and store files, identifies async timing anchors and lazy boundaries before writing any test.
- **Conventions-first**: Enforces `gotoAppReady()`, `data-test-id` selectors, dynamic data (no hardcoded IDs), and proper auth state reuse.
- **Context hints**: Accepts `unit-tests:`, `components:`, `known-selectors:`, `async-anchors:` to target research.
- **Scenario coverage**: Scaffolds happy path + edge cases not already covered by unit tests.

### 🔌 playwright-api

**Purpose**: Generates Playwright E2E tests for HTTP API endpoints using the `request` fixture.

**Key Features**:

- **No `fetch`/`axios`**: Uses Playwright's `APIRequestContext` exclusively.
- **Auth setup**: Token/cookie acquired in `beforeAll` and reused across tests.
- **Scenario coverage**: 200 success, 401 unauthenticated, 400/422 validation, 404 not found.
- **Teardown**: Cleans up created resources in `afterAll` when the endpoint supports DELETE.

### 📝 add-readme

**Purpose**: Creates or updates a README.md file following the `assets/template.md` structure.

**Key Features**:

- **Standardized Structure**: Enforces a consistent layout (Stack, Quick Start, Commands, Architecture) across all portfolio projects.
- **Visual Excellence**: Includes support for Mermaid diagrams and architectural descriptions.

## 🧭 Governance Skills

How work is scoped, planned and handed off. These encode process, not syntax.

### 📋 prd-first

**Purpose**: Starts every non-trivial task from a lightweight PRD and forbids the agent from inventing features that are not in scope.

**Key Features**:

- **Four mandatory sections**: Mission, In Scope, Out of Scope, Architecture.
- **Binding scope**: In Scope is exhaustive — a password-reset flow, caching or a new dependency that is not listed does not get built.
- **Approval gate**: no code is written while `status: draft`.
- **Template included**: `assets/PRD.md`.

### 🚦 plan-gate

**Purpose**: Forces a written plan and explicit approval before any change that crosses a risk threshold.

**Key Features**:

- **Clear threshold**: 3+ files, a dependency, a data model, infrastructure, or a cross-boundary rename.
- **Six required parts**: goal, file list, order, risk, rollback, verification.
- **Anti-gaming**: splitting one change into sub-threshold edits to dodge the gate is explicitly forbidden.

### 🧠 context-protocol

**Purpose**: The 60% Document & Clear protocol — dump progress to a session file, clear, resume from the file.

**Key Features**:

- **Beats auto-compaction**: a summary loses decisions; a session file keeps them.
- **Structured handoff**: Done, In progress (file:line), Next steps, Decisions, Gotchas, Open questions.
- **Deliberate timing**: act at 60%, not at 95% under pressure.

### 🕸️ agent-pipeline

**Purpose**: The Lead Researcher multi-agent pattern for work too large for one context window.

**Key Features**:

- **Four roles**: Lead Researcher, parallel Search Agents, Implementation Agents, adversarial Verifier.
- **Closed questions**: subagents answer one bounded question and return findings with citations, never file dumps.
- **Parallel reads, serial writes**: no two agents hold a write lock on the same file.
- **Knows when not to fire**: one focused agent beats five vague ones.

### 🏛️ architecture-baseline

**Purpose**: The authoritative architecture reference for any agent entering a repository.

**Key Features**:

- **Ten standing design decisions** with their consequences, settled by ADR rather than re-litigated per task.
- **Monorepo boundaries**: one-way dependency direction, services own their data.
- **Definition of done** checklist.
- **Templates included**: per-repo `CLAUDE.md` and `AGENTS.md` in `assets/`.

## 📚 Domain Reference Skills

Passive rule sets, loaded only when the work enters that domain. Each ends with a **Red Flags** section listing the patterns that should stop a review.

| Skill | Loads when | Focus |
| --- | --- | --- |
| `react` | `.tsx`/`.jsx`, hooks, component tests | State ownership, effects, data fetching, a11y, RTL |
| `vue` | `.vue`, composables, Pinia, Nuxt | `<script setup>`, `ref` over `reactive`, composable cleanup |
| `javascript` | Framework-free `.js`/`.mjs` | ESM, safe DOM, event delegation, `AbortController` |
| `css` | Stylesheets, `<style>`, design tokens | Strict BEM, mobile-first, custom-property theming |
| `serverless-api` | Handlers, endpoints, queue consumers | Thin handlers, edge validation, error mapping, idempotency |
| `php` | Any PHP (+ `symfony.md` companion) | PHP 8.x strict types, enums, readonly; Symfony DI, routing, Doctrine |
| `postgres` | SQL, schema, indexes, migrations | Indexing, keyset pagination, expand/migrate/contract |
| `aws` | SDK calls, credentials in app code | Never hardcode, least privilege, SDK v3, retries |
| `cloud-infra` | IaC, IAM policies, CI pipelines | Least privilege, environment isolation, deploy safety |

## 🛡️ Setup & Guardrails

### 🔒 guardrails

**Purpose**: Deterministic safety rails that do not depend on an AI choosing to obey them.

**Key Features**:

- **Two layers**: a `PreToolUse` Bash guard (agent-facing) and global git `pre-commit` / `pre-push` hooks (human and agent alike).
- **Blocks**: destructive deletes, protected-branch commits and pushes, force-push without a lease, credential reads and commits, piping a download into a shell, ad-hoc `DROP`/`TRUNCATE`, deploys, repo-wide fan-out scripts.
- **Delegates, never replaces**: re-runs each repo's own hooks (lefthook, husky, `.git/hooks`).
- **Tested**: a 35-case suite ships in `assets/test/`.
- **Honest about limits**: shell variables are not expanded, so it fails closed.

### 📦 bootstrap-workspace

**Purpose**: Restores the complete workspace — every skill, global rules, templates and both guardrail layers — onto a machine.

**Key Features**:

- **One command**: `install.sh`, with `--dry-run` to preview and `--git-hooks` to opt into the machine-wide git config change.
- **Backs up before replacing**, and is idempotent.
- **Self-verifying**: ends by running the guard test suite.
- **This repo is the source of truth**; `~/.claude` is a working copy.

### 📊 statusline

**Purpose**: A two-line Claude Code status bar that keeps model, context and quota usage permanently visible.

**Key Features**:

- **Line 1**: active model with its real context window size (`/1M` vs `/200k`), reasoning effort, fast mode, directory, and git branch — **red on `main`/`master`**.
- **Line 2**: context usage bar, the 5-hour `session` window and the 7-day `week` window with time to reset, plus estimated cost and duration.
- **Degrades, never lies**: `rate_limits` only exists for Pro/Max after the first API response, so absent segments disappear instead of rendering `0%`.
- **Cheap**: one `jq` pass for every field, ~19 ms per render.

## 📦 Dependencies

This repository depends on the following tools:

- **[RTK (AI Agent Tooling)](https://github.com/rtk-ai/rtk)**: The underlying framework used by the skills to interact with the environment (git, filesystem, etc.).

## 🛠️ How to Use This Repository

Install all skills via the [skills.sh](https://www.skills.sh) CLI:

```bash
npx skills add krealalejo/ia-skills
```

Or install manually by copying the desired skill folder into your local skills directory. Ensure the agent has the necessary permissions to execute the commands defined in the `SKILL.md` file.

---

_Developed with ❤️ by krealalejo_
