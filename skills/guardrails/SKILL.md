---
name: guardrails
description: >
  Deterministic safety rails that do not depend on an AI choosing to obey them: a
  PreToolUse Bash guard plus global git pre-commit/pre-push hooks blocking destructive
  commands, protected-branch writes, secret commits and failing tests.
  Trigger: /guardrails, "install safety hooks", "block dangerous commands", "prevent pushes to main", or setting up a new machine.
license: Apache-2.0
metadata:
  author: krealalejo
  version: "1.0"
---

## When to Use

- Setting up a new machine or a new workspace.
- When an agent has done something destructive, or nearly did.
- When a rule keeps getting broken despite being written in `CLAUDE.md` — that is the
  signal it belongs in a hook, not in prose.
- Auditing what is actually enforced versus merely documented.

## Critical Patterns

### The core idea

**A rule an AI can choose to ignore is not a rule.** Anything whose violation is
expensive or irreversible must be mechanical. Prose in `CLAUDE.md` sets intent; hooks set
limits. Every rule below was moved out of prose deliberately.

### Layer 1 — Bash guard (agent-facing)

`assets/guard-bash.sh` runs before **every** Bash call the agent makes. Exit 2 blocks the
call and returns the reason to the agent.

| Rule | Blocks |
|------|--------|
| `no-verify` | flags whose purpose is skipping hooks |
| `push-protected` | pushes to `main`/`master`/`production`/`release` |
| `force-push` | force-push without a lease |
| `commit-protected` | committing while HEAD is on a protected branch |
| `pr-create` | agent-opened pull requests |
| `reset-hard` / `git-clean` | hard resets, untracked-file deletion |
| `rm-rf` | recursive force-delete outside known build-artifact paths |
| `chmod-777` | recursive world-writable |
| `curl-pipe-sh` | piping a download straight into a shell |
| `secret-read` | reading `.env*`, `*.pem`, `id_rsa`, cloud credential files |
| `deploy` / `infra-destroy` | deploys and all infrastructure destroys |
| `destructive-sql` | ad-hoc `DROP` / `TRUNCATE` / unbounded `DELETE` |
| `repo-wide-script` | fan-out `npm run build/test/lint` with no workspace filter |

Allowed on purpose: deleting `node_modules`, pushing a feature branch, a lease-guarded
force-push, a workspace-scoped build or test.

**Heredoc bodies are data, not code** — writing documentation that mentions a forbidden
command is fine. Bodies piped into an interpreter are still scanned.

### Layer 2 — git hooks (apply to human and agent alike)

`assets/githooks/` installs globally via `core.hooksPath`.

- **pre-commit** — blocks commits on a protected branch; blocks staged credential files;
  scans the staged diff for cloud keys, private keys, provider tokens, JWTs and
  `password=` literals; delegates to the repo's own hooks; blocks if tests fail.
- **pre-push** — blocks pushes to a protected branch; blocks remote branch deletion;
  delegates to the repo's own hooks; blocks if tests fail.

### Delegation, not replacement

A global `core.hooksPath` **overrides** `.git/hooks` entirely, so `_common.sh` re-runs
whatever the repo defines for itself — `.git/hooks/<name>`, lefthook, or husky. Without
that, installing these silently disables every repo's existing hooks.

### The caveat that bites

A **local** `core.hooksPath` beats the global one. Repos using husky set
`core.hooksPath=.husky/_` locally, so the global hooks never fire there. Layer 1 still
does. Chain them explicitly:

```bash
# in that repo's .husky/pre-commit
~/.claude/githooks/pre-commit || exit 1
```

Check with `git config --local core.hooksPath`.

### Escape hatches

Deliberately noisy, and unavailable to the agent since Layer 1 blocks hook-skipping flags:

| Need | Command |
|------|---------|
| Skip tests once | `SKIP_TESTS=1 git commit ...` |
| Skip the secret scan once | `SKIP_SECRET_SCAN=1 git commit ...` |
| Stop pre-commit tests in a repo | `git config agent.precommitTests false` |
| Stop pre-push tests in a repo | `git config agent.prepushTests false` |

Tests on pre-commit get slow on a monorepo — turning them off at commit and keeping them
at push gives the same protection with a far better inner loop.

### Known limitations — state them, do not pretend otherwise

- **Shell variables are not expanded.** `rm -rf $DIR` is blocked because `$DIR` cannot be
  resolved. It fails closed, which is the correct direction.
- **It reads shell syntax, not intent.** A destructive action inside a script the command
  merely *writes* is not caught; running that script later is.
- Layer 1 covers the Bash tool only.

### Change a rule, run the tests

`assets/test/cases.json` holds 35 cases. Always add a matching **allow** case alongside a
new block rule — the expensive failure mode of a guard is not a missed block, it is
blocking legitimate work until someone switches the whole thing off.

## Commands

```bash
# Layer 1 — wire the Bash guard into ~/.claude/settings.json
mkdir -p ~/.claude/hooks
cp -R skills/guardrails/assets/guard-bash.sh skills/guardrails/assets/test ~/.claude/hooks/
chmod +x ~/.claude/hooks/guard-bash.sh
# then add to ~/.claude/settings.json:
#   "hooks": { "PreToolUse": [ { "matcher": "Bash",
#     "hooks": [ { "type": "command",
#                  "command": "<HOME>/.claude/hooks/guard-bash.sh", "timeout": 15 } ] } ] }

# Layer 2 — install the git hooks globally
cp -R skills/guardrails/assets/githooks ~/.claude/githooks
chmod +x ~/.claude/githooks/*
git config --global core.hooksPath ~/.claude/githooks

# Verify
python3 ~/.claude/hooks/test/run.py ~/.claude/hooks/test/cases.json

# Uninstall
git config --global --unset core.hooksPath
# and remove the "hooks" key from ~/.claude/settings.json
```

## Red Flags

A safety rule that exists only as prose · installing a global `core.hooksPath` without
delegating to repo hooks · adding a block rule with no matching allow test · an escape
hatch the agent can reach · claiming a rule is enforced without having run the suite ·
a guard so noisy the user disables it.
