#!/usr/bin/env bash
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
drift=0

report() { printf '  %-10s %s\n' "$1" "$2"; drift=1; }

compare() {
  local src="$1" dst="$2" label="$3"
  if [ ! -e "$dst" ]; then
    report "missing" "$label"
  elif ! diff -rq "$src" "$dst" >/dev/null 2>&1; then
    report "differs" "$label"
  fi
}

printf 'Repo:   %s\nTarget: %s\n\n' "$REPO" "$DEST"

for d in "$REPO"/skills/*/; do
  n="$(basename "$d")"
  compare "$d" "$DEST/skills/$n" "skills/$n"
done
for f in "$REPO"/agents/*.md; do
  n="$(basename "$f")"
  compare "$f" "$DEST/agents/$n" "agents/$n"
done

A="$REPO/skills/bootstrap-workspace/assets"
compare "$A/global-CLAUDE.md" "$DEST/CLAUDE.md" "CLAUDE.md"
compare "$A/global-AGENTS.md" "$DEST/AGENTS.md" "AGENTS.md"
compare "$REPO/skills/prd-first/assets/PRD.md" "$DEST/templates/PRD.md" "templates/PRD.md"
compare "$REPO/skills/architecture-baseline/assets/CLAUDE.md" "$DEST/templates/CLAUDE.md" "templates/CLAUDE.md"
compare "$REPO/skills/architecture-baseline/assets/AGENTS.md" "$DEST/templates/AGENTS.md" "templates/AGENTS.md"

G="$REPO/skills/guardrails/assets"
compare "$G/guard-bash.sh" "$DEST/hooks/guard-bash.sh" "hooks/guard-bash.sh"
compare "$G/test" "$DEST/hooks/test" "hooks/test"
compare "$G/githooks" "$DEST/githooks" "githooks"
compare "$REPO/skills/context-protocol/assets/session-resume.sh" "$DEST/hooks/session-resume.sh" "hooks/session-resume.sh"
compare "$REPO/skills/statusline/assets/statusline.sh" "$DEST/statusline.sh" "statusline.sh"

for d in "$DEST"/skills/*/; do
  [ -d "$d" ] || continue
  n="$(basename "$d")"
  [ "$n" = "synced" ] && continue
  [ -d "$REPO/skills/$n" ] || report "untracked" "skills/$n (only in $DEST, port it or delete it)"
done
for f in "$DEST"/agents/*.md; do
  [ -f "$f" ] || continue
  n="$(basename "$f")"
  [ -f "$REPO/agents/$n" ] || report "untracked" "agents/$n (only in $DEST, port it or delete it)"
done

if [ "$drift" = 0 ]; then
  echo "No drift: $DEST matches the repo."
else
  printf '\nDrift found. "differs" and "missing": run install.sh (repo wins). "untracked": copy it into the repo first if it is worth keeping.\n'
  printf 'Inspect one with: diff -r <repo path> <target path>\n'
fi
exit "$drift"
