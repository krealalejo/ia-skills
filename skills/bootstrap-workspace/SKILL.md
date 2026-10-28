---
name: bootstrap-workspace
description: >
  Restores the complete agentic workspace onto a machine: every skill and subagent, the global rules
  and architecture files, the PRD and repo templates, and both guardrail layers.
  Trigger: /bootstrap-workspace, "set up a new machine", "restore my Claude config", "install all my skills".
license: Apache-2.0
metadata:
  author: krealalejo
  version: "1.1"
---

## When to Use

- Setting up a new machine or a fresh container.
- Restoring after `~/.claude` was lost, corrupted or reset.
- Bringing a second machine in line with the first.
- Auditing drift: run `--dry-run` to see what would change without changing it.

## Critical Patterns

### What this repo is, and what it is not

This repo is the **source of truth**; `~/.claude` is a working copy. Edits made directly
in `~/.claude` are not backed up until they are ported back here. When the two disagree,
this repo wins — that is the point of having a restore point.

### What gets installed

| From this repo | To | Purpose |
|----------------|-----|---------|
| `skills/*/` | `~/.claude/skills/` | every skill, loaded on demand |
| `agents/*.md` | `~/.claude/agents/` | pipeline subagents for `/pipeline` |
| `bootstrap-workspace/assets/global-CLAUDE.md` | `~/.claude/CLAUDE.md` | global hard rules, always in context |
| `bootstrap-workspace/assets/global-AGENTS.md` | `~/.claude/AGENTS.md` | architecture reference for any agent |
| `prd-first/assets/PRD.md` | `~/.claude/templates/` | PRD template |
| `architecture-baseline/assets/*.md` | `~/.claude/templates/` | per-repo `CLAUDE.md` / `AGENTS.md` starters |
| `guardrails/assets/guard-bash.sh` + `test/` | `~/.claude/hooks/` | Layer 1 Bash guard |
| `guardrails/assets/githooks/` | `~/.claude/githooks/` | Layer 2 git hooks |
| `context-protocol/assets/session-resume.sh` | `~/.claude/hooks/` | `SessionStart` resume hook |
| `statusline/assets/statusline.sh` | `~/.claude/statusline.sh` | two-line status bar |

It also wires the `PreToolUse` Bash hook, the `SessionStart` resume hook and the `statusLine` command into
`~/.claude/settings.json` with `jq`, preserving any other keys already configured there.

### Safety properties of the installer

- **Backs up before replacing.** Every file it would overwrite is copied to
  `<file>.bak-<timestamp>` first.
- **`--dry-run` changes nothing** and prints every action it would take. Use it first.
- **Does not touch global git config unless asked.** `core.hooksPath` is a machine-wide
  change that overrides every repo's own hooks, so it is behind `--git-hooks` and prints
  the undo command when it runs.
- **Verifies at the end** by running the guard's 38-case suite. An install that does not
  end in `38/38 passed` is not finished.
- **Idempotent.** Running it twice produces the same result, plus one more backup.

### One install path

The installer is the only supported way onto a machine. There is deliberately no plugin
packaging: a plugin cannot install global rules, templates, git hooks or the status line,
and it would namespace every skill. `npx skills add` exists for other people who want the
skills alone.

### Drift: port back before you install

`scripts/check-drift.sh` compares every installed file with the repo and exits 1 on drift:

- **differs** — read the diff first. If `~/.claude` holds the newer change, port it into the
  repo; if the repo is newer, `install.sh` will apply it.
- **missing** — not installed yet; `install.sh` adds it.
- **untracked** — exists only in `~/.claude`; copy it into the repo or delete it.

Running the installer over a "differs" you have not read throws away the live change.

### Global versus repo scope

Installing here makes these rules apply to **every** repository on the machine. A
repo-level `CLAUDE.md` may add rules or tighten them, never loosen them — the hard rules
are a floor. Repo-specific domain knowledge belongs in that repo's `.claude/skills/`,
which takes precedence over the global copies.

### After installing

Restart Claude Code — skills, agents and hooks are read at session start. Then confirm the guard
is live by checking that a deliberately blocked command is refused.

## Commands

```bash
./scripts/check-drift.sh

./skills/bootstrap-workspace/assets/install.sh --dry-run

# Install skills, global docs, templates and the Bash guard
./skills/bootstrap-workspace/assets/install.sh

# Also enable the global git hooks (machine-wide)
./skills/bootstrap-workspace/assets/install.sh --git-hooks

# Verify afterwards
GUARD=~/.claude/hooks/guard-bash.sh \
  python3 ~/.claude/hooks/test/run.py ~/.claude/hooks/test/cases.json

# Install target can be redirected
CLAUDE_CONFIG_DIR=/tmp/claude-test ./skills/bootstrap-workspace/assets/install.sh --dry-run
```

## Red Flags

Editing `~/.claude` and never porting it back here · installing over drift without reading it · running the installer without
`--dry-run` on a machine with an existing config you care about · enabling `--git-hooks`
on a machine whose repos rely on husky or lefthook without reading the delegation caveat
in `guardrails` · declaring the install done without the test suite passing · treating
the working copy as the backup.
