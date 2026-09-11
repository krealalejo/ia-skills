---
name: statusline
description: >
  The Claude Code status line: a two-line bar showing the active model, context window
  usage, the 5-hour session and 7-day rate-limit windows, session cost and git state.
  Covers the stdin JSON contract, which fields are absent when, and how to extend it.
  Trigger: /statusline, "change my status line", "show context usage in the status bar", "add X to the status line", or setting up a new machine.
license: Apache-2.0
metadata:
  author: krealalejo
  version: "1.0"
---

## When to Use

- Setting up a new machine — `bootstrap-workspace` installs this automatically.
- Adding, removing or reordering a field in the bar.
- The bar shows a wrong value, an empty gap, or nothing at all.
- Deciding whether a piece of session state is worth a permanent slot.

## Critical Patterns

### What it renders

```
Opus 5/1M · xhigh ⚡  ~/work/api  ⎇ feat/login +2 *3
ctx ▓▓▓▓▓▓▓░░░ 73%  ·  session 41% 2h13m  ·  week 93% 2d7h  ·  $1.23 30m
```

| Slot | Source field | Why it earns a slot |
|------|--------------|---------------------|
| model + window size | `model.display_name`, `context_window.context_window_size` | `/1M` vs `/200k` proves which model alias actually took effect |
| effort, fast mode | `effort.level`, `fast_mode` | both change cost and latency silently |
| directory | `workspace.current_dir` | `cwd` drifts during a session |
| branch + counts | `git` | red on `main`/`master` — a visual echo of the never-commit-on-main rule |
| `ctx` bar | `context_window.used_percentage` | the 60% Document & Clear trigger has to be visible before it is missed |
| `session` | `rate_limits.five_hour` | the window that actually throttles a working day |
| `week` | `rate_limits.seven_day` | the one that ends a working week |
| `spend` | `rate_limits.spend_limit` | only rendered behind a gateway spend limit |
| cost + duration | `cost.total_cost_usd`, `cost.total_duration_ms` | client-side estimate at list price, not the bill |

Three thresholds, one colour scale everywhere: green under 70%, yellow 70–89%, red 90%+.

### The stdin contract

Claude Code pipes one JSON object to the command on every render. Everything printed to
stdout becomes the bar; one line of output is one row. ANSI colours and OSC 8 links pass
through. Full field list: <https://code.claude.com/docs/en/statusline>.

### Absent is not zero

The bar must degrade to fewer fields, never to wrong ones.

| Field | Missing when |
|-------|--------------|
| `rate_limits` | not a Pro/Max subscriber, or before the first API response of the session. Each window disappears independently once its `resets_at` passes |
| `context_window.used_percentage` | `null` early in a session |
| `context_window.current_usage` | `null` before the first API call, and again after `/compact` |
| `effort.level` | the model has no effort parameter |
| `workspace.repo`, `pr`, `worktree` | outside a git repo, with no open PR, outside a worktree session |

`jq -r '.rate_limits.five_hour.used_percentage // empty'` yields an empty string, and the
script skips the whole segment rather than printing `0%`. A default of `0` on a usage
field is a lie that reads as "plenty of headroom left".

### One jq call, not fourteen

The bar re-renders on every event. The script makes a single `jq` pass emitting one field
per line into a bash array via `mapfile`, then indexes it. Measured cost of a full render
including the git calls: ~19 ms.

Do **not** parse the tab-separated form with `IFS=$'\t' read`: tab is whitespace to bash,
so consecutive empty fields collapse and every value after the first absent one lands in
the wrong variable. Newline-delimited output plus `mapfile` preserves empty fields.

### Wiring

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh",
    "padding": 0,
    "refreshInterval": 30
  }
}
```

`refreshInterval` re-runs the command every N seconds on top of the event-driven updates.
It is what keeps the `resets_at` countdowns moving while the session sits idle; without it
the reset times freeze until the next tool call.

A custom status line suppresses most of the built-in footer hints, including
`esc to interrupt`. That is the real cost of adding one.

### Extending it

1. Confirm the field exists in the docs and note when it is absent.
2. Add it to the `jq` array **at the end** — the array is positional, so inserting in the
   middle shifts every variable after it.
3. Add the matching `F[n]` assignment and render it behind a `[ -n "$X" ]` guard.
4. Test against a payload with the field and one without it before installing.

## Commands

```bash
# Install (bootstrap-workspace does this as part of a full restore)
cp skills/statusline/assets/statusline.sh ~/.claude/statusline.sh
chmod +x ~/.claude/statusline.sh
jq '. + {statusLine: {type: "command", command: "~/.claude/statusline.sh", padding: 0, refreshInterval: 30}}' \
  ~/.claude/settings.json > /tmp/s.json && mv /tmp/s.json ~/.claude/settings.json

# Render a full payload without starting a session
echo '{"model":{"display_name":"Opus 5"},"workspace":{"current_dir":"'"$PWD"'"},
  "effort":{"level":"xhigh"},"context_window":{"used_percentage":73,"context_window_size":1000000},
  "cost":{"total_cost_usd":1.23,"total_duration_ms":1830000},
  "rate_limits":{"five_hour":{"used_percentage":41,"resets_at":'"$(( $(date +%s) + 8000 ))"'},
  "seven_day":{"used_percentage":93,"resets_at":'"$(( $(date +%s) + 200000 ))"'}}}' \
  | ./skills/statusline/assets/statusline.sh

# Render the degraded case: no rate limits, no git, nothing yet measured
echo '{}' | ./skills/statusline/assets/statusline.sh

# Uninstall
jq 'del(.statusLine)' ~/.claude/settings.json > /tmp/s.json && mv /tmp/s.json ~/.claude/settings.json
```

## Red Flags

Defaulting an absent usage field to `0%` · one `jq` call per field on a bar that
re-renders constantly · parsing tab-separated `jq` output with `read` · a field added to
the middle of the positional array · a bar so wide it wraps on a split terminal ·
shelling out to a network call on every render · claiming a layout works without having
run the empty-payload case.

## Resources

- [Status line documentation](https://code.claude.com/docs/en/statusline)
- `assets/statusline.sh` — the installed script
- `bootstrap-workspace` — installs it and wires `settings.json`
