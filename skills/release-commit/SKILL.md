---
name: release-commit
description: >
  Creates an empty summary commit describing all changes introduced in the current branch.
  Trigger: /release-commit or "create release commit", "add summary commit".
license: Apache-2.0
metadata:
  author: krealalejo
  version: "1.0"
---

## When to Use

- Before merging a feature branch to leave a human-readable summary of what changed.
- When a changelog-style commit is needed without modifying any files.
- When the branch has multiple atomic commits and a single plain-English summary is desired.

## Critical Patterns

- **RTK Golden Rule**: Always prefix git commands with `rtk`.
- **Empty Commit**: Use `git commit --allow-empty`. No files are staged or modified.
- **Format**: `summary: <message>` — no conventional-commit type prefix, no scope.
- **Human Language**: Message must be plain English prose, not a technical changelog. Explain _what_ changed and _why_ at a product/feature level, not file-by-file.
- **Length Limit**: Message MUST NOT exceed 300 characters.
- **Single Commit**: Always one commit, never split.
- **Output Constraint**: After committing, respond ONLY with "DONE" followed by the full commit message used. No other explanation.

## Workflow

1. **Analyze Branch**: Run `rtk git log main..HEAD --oneline` to list all commits in the branch.
2. **Deep Diff**: Run `rtk git diff main...HEAD --stat` for a file-level overview, then `rtk git diff main...HEAD` to understand the actual changes.
3. **Synthesize Summary**: Write one concise English sentence (or two at most) describing the overall change introduced by the branch — what feature was added, what bug was fixed, or what refactor was made. Focus on intent and user-facing impact, not implementation details.
4. **Commit Empty**: Run:
   ```bash
   rtk git commit --allow-empty -m "summary: <message>"
   ```
5. **Output**: Reply with `DONE` + the commit message. Nothing else.

## Commands

```bash
# Basic usage
/release-commit

# Example output commit
# summary: add user authentication flow with JWT tokens and refresh token rotation
```
