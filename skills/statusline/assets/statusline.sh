#!/usr/bin/env bash
set -uo pipefail

input=$(cat)

RESET=$'\033[0m'; DIM=$'\033[2m'; BOLD=$'\033[1m'
RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'
BLUE=$'\033[34m'; MAGENTA=$'\033[35m'; CYAN=$'\033[36m'

mapfile -t F < <(printf '%s' "$input" | jq -r '
  [ (.model.display_name // "?")
  , (.effort.level // "")
  , (if .fast_mode then "fast" else "" end)
  , (.workspace.current_dir // .cwd // "")
  , (.context_window.used_percentage // 0 | floor)
  , (.context_window.context_window_size // 0)
  , (.rate_limits.five_hour.used_percentage // "" | if . == "" then "" else floor end)
  , (.rate_limits.five_hour.resets_at // "")
  , (.rate_limits.seven_day.used_percentage // "" | if . == "" then "" else floor end)
  , (.rate_limits.seven_day.resets_at // "")
  , (.rate_limits.spend_limit.used_percentage // "" | if . == "" then "" else floor end)
  , (.cost.total_cost_usd // 0)
  , (.cost.total_duration_ms // 0)
  , (.workspace.git_worktree // "")
  ] | .[] | tostring')

MODEL=${F[0]:-?}
EFFORT=${F[1]:-}
FAST=${F[2]:-}
DIR=${F[3]:-$PWD}
CTX_PCT=${F[4]:-0}
CTX_SIZE=${F[5]:-0}
H5=${F[6]:-}
H5_AT=${F[7]:-}
D7=${F[8]:-}
D7_AT=${F[9]:-}
SPEND=${F[10]:-}
COST=${F[11]:-0}
DUR_MS=${F[12]:-0}
BRANCH_HINT=${F[13]:-}

pct_color() {
  if   [ "${1:-0}" -ge 90 ]; then printf '%s' "$RED"
  elif [ "${1:-0}" -ge 70 ]; then printf '%s' "$YELLOW"
  else printf '%s' "$GREEN"; fi
}

bar() {
  local pct=${1:-0} width=${2:-10} filled i out=""
  [ "$pct" -gt 100 ] && pct=100
  filled=$(( pct * width / 100 ))
  for ((i = 0; i < width; i++)); do
    if [ "$i" -lt "$filled" ]; then out+="▓"; else out+="░"; fi
  done
  printf '%s' "$out"
}

until_reset() {
  local at=${1:-} now left h m
  [ -z "$at" ] && return 0
  now=$(date +%s)
  left=$(( at - now ))
  [ "$left" -le 0 ] && return 0
  h=$(( left / 3600 )); m=$(( (left % 3600) / 60 ))
  if   [ "$h" -ge 24 ]; then printf ' %s' "$(( h / 24 ))d$(( h % 24 ))h"
  elif [ "$h" -gt 0 ];  then printf ' %s' "${h}h${m}m"
  else printf ' %s' "${m}m"; fi
}

human_ctx() {
  local n=${1:-0}
  if   [ "$n" -ge 1000000 ]; then printf '%sM' "$(( n / 1000000 ))"
  elif [ "$n" -ge 1000 ];    then printf '%sk' "$(( n / 1000 ))"
  else printf '%s' "$n"; fi
}

L1="${BOLD}${MAGENTA}${MODEL}${RESET}"
[ "$CTX_SIZE" != "0" ] && L1+="${DIM}/$(human_ctx "$CTX_SIZE")${RESET}"
[ -n "$EFFORT" ] && L1+=" ${DIM}·${RESET} ${CYAN}${EFFORT}${RESET}"
[ -n "$FAST" ] && L1+=" ${YELLOW}⚡${RESET}"

SHORT_DIR="${DIR/#$HOME/\~}"
L1+="  ${BLUE}${SHORT_DIR}${RESET}"

if git -C "$DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  GB=$(git -C "$DIR" rev-parse --abbrev-ref HEAD 2>/dev/null)
  [ "$GB" = "HEAD" ] && GB=$(git -C "$DIR" rev-parse --short HEAD 2>/dev/null)
  PORCELAIN=$(git -C "$DIR" status --porcelain 2>/dev/null)
  STAGED=$(printf '%s\n' "$PORCELAIN" | grep -c '^[MADRC]' || true)
  DIRTY=$(printf '%s\n' "$PORCELAIN" | grep -c '^.[MD?]' || true)
  case "$GB" in
    main|master) BCOL="$RED" ;;
    *)           BCOL="$GREEN" ;;
  esac
  L1+="  ${BCOL}⎇ ${GB}${RESET}"
  [ "${STAGED:-0}" -gt 0 ] && L1+=" ${GREEN}+${STAGED}${RESET}"
  [ "${DIRTY:-0}" -gt 0 ] && L1+=" ${YELLOW}*${DIRTY}${RESET}"
fi
[ -n "$BRANCH_HINT" ] && L1+=" ${DIM}(wt:${BRANCH_HINT})${RESET}"

CC=$(pct_color "$CTX_PCT")
L2="${DIM}ctx${RESET} ${CC}$(bar "$CTX_PCT")${RESET} ${CC}${CTX_PCT}%${RESET}"

if [ -n "$H5" ]; then
  C5=$(pct_color "$H5")
  L2+="  ${DIM}·${RESET}  ${DIM}session${RESET} ${C5}${H5}%${RESET}${DIM}$(until_reset "$H5_AT")${RESET}"
fi
if [ -n "$D7" ]; then
  C7=$(pct_color "$D7")
  L2+="  ${DIM}·${RESET}  ${DIM}week${RESET} ${C7}${D7}%${RESET}${DIM}$(until_reset "$D7_AT")${RESET}"
fi
if [ -n "$SPEND" ]; then
  CS=$(pct_color "$SPEND")
  L2+="  ${DIM}·${RESET}  ${DIM}spend${RESET} ${CS}${SPEND}%${RESET}"
fi

MINS=$(( DUR_MS / 60000 ))
L2+="  ${DIM}·${RESET}  ${YELLOW}$(printf '$%.2f' "$COST")${RESET} ${DIM}${MINS}m${RESET}"

printf '%b\n%b\n' "$L1" "$L2"
