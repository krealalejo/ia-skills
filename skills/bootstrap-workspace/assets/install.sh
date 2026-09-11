#!/usr/bin/env bash
# Restore the full agentic workspace from this repo onto a machine.
#
#   ./install.sh                 skills + global docs + templates + Bash guard
#   ./install.sh --git-hooks     the above, and set core.hooksPath globally
#   ./install.sh --dry-run       print what would happen, change nothing
#
# Existing files are backed up to <file>.bak-<timestamp> before being replaced.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
STAMP="$(date +%Y%m%d-%H%M%S)"
GIT_HOOKS=0
DRY=0
for a in "$@"; do
  case "$a" in
    --git-hooks) GIT_HOOKS=1 ;;
    --dry-run)   DRY=1 ;;
    *) echo "unknown option: $a" >&2; exit 2 ;;
  esac
done

say()  { printf '  %s\n' "$*"; }
head_() { printf '\n\033[1m%s\033[0m\n' "$*"; }
run()  { if [ "$DRY" = 1 ]; then say "[dry-run] $*"; else eval "$@"; fi; }
backup() { [ -e "$1" ] && run "cp -R '$1' '$1.bak-$STAMP'" && say "backed up $(basename "$1")"; return 0; }

head_ "Target: $DEST"
run "mkdir -p '$DEST/skills' '$DEST/templates' '$DEST/hooks' '$DEST/githooks'"

head_ "1. Skills"
for d in "$REPO"/skills/*/; do
  n="$(basename "$d")"
  run "rm -rf '$DEST/skills/$n'"
  run "cp -R '$d' '$DEST/skills/$n'"
  say "$n"
done

head_ "2. Global rules and architecture"
A="$REPO/skills/bootstrap-workspace/assets"
backup "$DEST/CLAUDE.md"; run "cp '$A/global-CLAUDE.md' '$DEST/CLAUDE.md'";  say "CLAUDE.md"
backup "$DEST/AGENTS.md"; run "cp '$A/global-AGENTS.md' '$DEST/AGENTS.md'";  say "AGENTS.md"

head_ "3. Templates"
run "cp '$REPO/skills/prd-first/assets/PRD.md' '$DEST/templates/PRD.md'"; say "PRD.md"
run "cp '$REPO/skills/architecture-baseline/assets/CLAUDE.md' '$DEST/templates/CLAUDE.md'"; say "CLAUDE.md (repo template)"
run "cp '$REPO/skills/architecture-baseline/assets/AGENTS.md' '$DEST/templates/AGENTS.md'"; say "AGENTS.md (repo template)"

head_ "4. Guardrails"
G="$REPO/skills/guardrails/assets"
run "cp '$G/guard-bash.sh' '$DEST/hooks/guard-bash.sh'"
run "chmod +x '$DEST/hooks/guard-bash.sh'"
run "rm -rf '$DEST/hooks/test'"
run "cp -R '$G/test' '$DEST/hooks/test'"
run "cp '$G/githooks/'* '$DEST/githooks/'"
run "chmod +x '$DEST/githooks/'*"
say "Bash guard + git hooks copied"

head_ "5. Status line"
run "cp '$REPO/skills/statusline/assets/statusline.sh' '$DEST/statusline.sh'"
run "chmod +x '$DEST/statusline.sh'"
say "statusline.sh copied"

head_ "6. settings.json"
if command -v jq >/dev/null 2>&1; then
  SETTINGS="$DEST/settings.json"
  [ -f "$SETTINGS" ] || run "echo '{}' > '$SETTINGS'"
  backup "$SETTINGS"
  HOOK_CMD="$DEST/hooks/guard-bash.sh"
  STATUS_CMD="$DEST/statusline.sh"
  if [ "$DRY" = 1 ]; then
    say "[dry-run] would wire PreToolUse:Bash -> $HOOK_CMD"
    say "[dry-run] would wire statusLine -> $STATUS_CMD"
  else
    jq --arg cmd "$HOOK_CMD" --arg status "$STATUS_CMD" '
      .hooks //= {} |
      .hooks.PreToolUse //= [] |
      .hooks.PreToolUse |= (map(select(.matcher != "Bash")) +
        [{matcher:"Bash", hooks:[{type:"command", command:$cmd, timeout:15}]}]) |
      .statusLine = {type:"command", command:$status, padding:0, refreshInterval:30}
    ' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
    say "wired PreToolUse:Bash guard into settings.json"
    say "wired statusLine into settings.json"
  fi
else
  say "jq not found - add this to $DEST/settings.json by hand:"
  say '  "hooks": { "PreToolUse": [ { "matcher": "Bash", "hooks":'
  say "    [ { \"type\": \"command\", \"command\": \"$DEST/hooks/guard-bash.sh\", \"timeout\": 15 } ] } ] },"
  say "  \"statusLine\": { \"type\": \"command\", \"command\": \"$DEST/statusline.sh\","
  say '    "padding": 0, "refreshInterval": 30 }'
fi

head_ "7. Global git hooks"
if [ "$GIT_HOOKS" = 1 ]; then
  run "git config --global core.hooksPath '$DEST/githooks'"
  say "core.hooksPath -> $DEST/githooks"
  say "undo with: git config --global --unset core.hooksPath"
else
  say "skipped (changes global git config). To enable:"
  say "  git config --global core.hooksPath $DEST/githooks"
fi

head_ "8. Verify"
if [ "$DRY" = 1 ]; then
  say "[dry-run] would run the guard test suite"
else
  GUARD="$DEST/hooks/guard-bash.sh" python3 "$DEST/hooks/test/run.py" "$DEST/hooks/test/cases.json" | tail -1
fi

head_ "Done. Restart Claude Code so it picks up the new skills and hooks."
