# 🧠 AI Skills Repository

A curated collection of custom AI skills designed to enhance software engineering workflows, automation, and development best practices.

## 🚀 Included Skills

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
