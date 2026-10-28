#!/usr/bin/env bash
set -euo pipefail

MAX_AGE_DAYS="${SESSION_RESUME_MAX_AGE_DAYS:-14}"

input="$(cat || true)"
cwd=""
if command -v jq >/dev/null 2>&1 && [ -n "$input" ]; then
  cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)"
fi
cwd="${cwd:-$PWD}"

root="$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$cwd")"
sessions="$root/docs/sessions"
[ -d "$sessions" ] || exit 0

latest="$(find "$sessions" -maxdepth 1 -type f -name '*.md' -mtime "-$MAX_AGE_DAYS" -printf '%T@ %p\n' 2>/dev/null \
  | sort -rn | head -1 | cut -d' ' -f2-)"
[ -n "$latest" ] || exit 0

title="$(grep -m1 '^# ' "$latest" | sed 's/^# //' || true)"
rel="${latest#"$root"/}"

printf 'context-protocol: an open session file exists in this repo: %s' "$rel"
[ -n "$title" ] && printf ' (%s)' "$title"
printf '.\nIf the task continues that work, read it first (PRD, then this file, then only the files it names) instead of re-exploring the codebase.\n'
