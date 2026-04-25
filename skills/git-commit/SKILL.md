---
name: git-commit
description: >
  Handles atomic commits with the /commit command.
  Trigger: When the user says "/commit" or asks to commit changes.
license: Apache-2.0
metadata:
  author: krealalejo
  version: "1.0"
---

## When to Use

- When uncommitted changes exist in the workspace.
- When the user wants to group changes into atomic, logical commits.
- When following conventional commit standards with specific ticket IDs or scopes.

## Critical Patterns

- **Atomic Commits**: Group related files together by their primary module/folder. Do not commit unrelated changes (e.g., frontend and backend) in a single commit unless they are tightly coupled.
- **English Only**: All commit messages MUST be in English.
- **Length Limit**: Messages MUST NOT exceed 300 characters.
- **Conventional Format**: `type(scope): message`.
  - `type`: Use `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, or `style`.
  - `scope`:
    - If a ticket ID is provided (e.g., `/commit ITBUILD-01`), use `feat(ITBUILD-01): message`.
    - If no ticket ID is provided, use a descriptive scope (e.g., `admin`, `api`, `ui`, `infra`).
- **Token Efficiency**: Use `rtk git status --short` and `rtk git diff` to analyze changes.
- **Multiple Repositories**: If the workspace contains multiple independent git repositories, the agent must identify them and perform atomic commits within each one separately.

## Workflow

1. **Analyze Status**: Run `rtk git status --short` to see all changed files.
2. **Group Changes**: Identify logical units based on file paths and content.
3. **Generate Messages**:
   - For each group, create a concise English message.
   - Example: `feat(api): add blog post controller tests`.
   - Example with ticket: `feat(ITBUILD-01): implement user registration`.
4. **Commit**:
   - `rtk git add <files>`
   - `rtk git commit -m "type(scope): message"`

## Commands

```bash
# Example usage:
# /commit ITBUILD-01
# /commit
```
