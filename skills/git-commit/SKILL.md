---
name: git-commit
description: >
  Handles atomic commits with the /commit command.
  Trigger: When the user says "/commit" or asks to commit changes.
license: Apache-2.0
metadata:
  author: krealalejo
  version: "1.1"
---

## When to Use

- When uncommitted changes exist in the workspace.
- When the user wants to group changes into atomic, logical commits.
- When following conventional commit standards with specific ticket IDs or scopes.

## Critical Patterns

- **RTK Golden Rule**: **Always prefix git commands with `rtk`**. This is crucial for token efficiency.
- **Atomic Commits**: Group related files together by their primary module/folder. Do not commit unrelated changes (e.g., frontend and backend) in a single commit unless they are tightly coupled.
- **English Only**: All commit messages MUST be in English.
- **Length Limit**: Messages MUST NOT exceed 300 characters.
- **Conventional Format**: `type(scope): message`.
  - `type`: Use `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, or `style`.
  - `scope`:
    - If a ticket ID is provided (e.g., `/commit ITBUILD-01`), use `feat(ITBUILD-01): message`.
    - If no ticket ID is provided, use a descriptive scope (e.g., `admin`, `api`, `ui`, `infra`).
- **Multiple Repositories**: If the workspace contains multiple independent git repositories, the agent must identify them and perform atomic commits within each one separately.
- **Output Constraint**: After completing the commits, the AI MUST respond ONLY with the word "DONE" followed by a list of the commits created. No other explanation or summary is allowed.

## Workflow

1. **Analyze Status**: Run `rtk git status --short` to see all changed files.
2. **Deep Analysis**: Use `rtk git diff` or `rtk git diff <file>` to understand the changes before grouping.
3. **Group Changes**: Identify logical units based on file paths and the content analyzed with `rtk`.
4. **Generate Messages**:
   - For each group, create a concise English message.
   - Example: `feat(api): add blog post controller tests`.
   - Example with ticket: `feat(ITBUILD-01): implement user registration`.
5. **Commit**:
   - `rtk git add <files>`
   - `rtk git commit -m "type(scope): message"`

## Commands

```bash
# Example usage:
# /commit ITBUILD-01
# /commit
```
