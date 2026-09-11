#!/usr/bin/env bash
# Shared helpers for the global git hooks (~/.claude/githooks).
# Installed via: git config --global core.hooksPath ~/.claude/githooks
set -euo pipefail

PROTECTED_RE='^(main|master|production|release)$'

red()  { printf '\033[31m%s\033[0m\n' "$*" >&2; }
ylw()  { printf '\033[33m%s\033[0m\n' "$*" >&2; }
die()  { red ""; red "✖ blocked by global git hook: $1"; red ""; shift; for l in "$@"; do red "  $l"; done; red ""; exit 1; }

repo_root() { git rev-parse --show-toplevel 2>/dev/null || pwd; }

# symbolic-ref works on an unborn branch (fresh repo, no commits); rev-parse does not.
current_branch() { git symbolic-ref --short -q HEAD 2>/dev/null || git rev-parse --abbrev-ref HEAD 2>/dev/null || echo ""; }

# Global hooks override .git/hooks entirely, so re-run whatever the repo defines itself.
delegate() {
  local name="$1"; shift
  local root; root="$(repo_root)"

  if [ -x "$root/.git/hooks/$name" ]; then
    "$root/.git/hooks/$name" "$@" || die "repo hook .git/hooks/$name failed" "Fix the reported problem."
  fi
  if [ -f "$root/lefthook.yml" ] || [ -f "$root/lefthook.yaml" ]; then
    if command -v lefthook >/dev/null 2>&1; then
      lefthook run "$name" || die "lefthook $name failed" "Fix the reported problem."
    elif [ -x "$root/node_modules/.bin/lefthook" ]; then
      "$root/node_modules/.bin/lefthook" run "$name" || die "lefthook $name failed" "Fix the reported problem."
    fi
  fi
  if [ -x "$root/.husky/$name" ]; then
    "$root/.husky/$name" "$@" || die "husky $name failed" "Fix the reported problem."
  fi
}

# git config agent.<key>, defaulting to $2
cfg() { git config --get "agent.$1" 2>/dev/null || printf '%s' "$2"; }

run_tests() {
  local phase="$1" root; root="$(repo_root)"
  [ "${SKIP_TESTS:-0}" = "1" ] && { ylw "⚠ tests skipped (SKIP_TESTS=1)"; return 0; }
  [ "$(cfg "${phase}Tests" true)" = "true" ] || return 0
  [ -f "$root/package.json" ] || return 0
  node -e 'process.exit(require(process.argv[1]).scripts?.test?0:1)' "$root/package.json" 2>/dev/null || return 0

  ylw "▶ running tests (${phase})…  disable: git config agent.${phase}Tests false   skip once: SKIP_TESTS=1"
  ( cd "$root" && npm test --silent ) || die "tests failed" \
      "Commits and pushes are blocked while tests fail." \
      "Run them yourself, fix the failures, then retry." \
      "One-off escape hatch: SKIP_TESTS=1 git ${phase/pre/} …"
}
