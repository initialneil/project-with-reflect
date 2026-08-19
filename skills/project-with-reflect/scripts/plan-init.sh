#!/usr/bin/env bash
# plan-init.sh <code_dir> "<slug or title>"
# RESOLVE-THEN-INIT the pwf (planning-with-files) plan for a long task — the auto-init a settled
# plan triggers. Never clobbers a plan the user already has:
#   • an active pwf plan already resolves under <code_dir> (user's own .active_plan / PLAN_ID /
#     legacy task_plan.md) → ADOPT it (print its path; touch nothing). Creating a second one would
#     flip pwf's .active_plan pointer and silently disable the user's plan injection + gate.
#   • none → pwf `init-session.sh --gated "<title>"` = autonomous+gate (Stop hook refuses "done"
#     while a phase is in_progress; per-tool-call injection dropped) + `inject-smart` token (turn-start
#     injection = title/Goal/Next Step/Current Phase/1 in_progress phase only — ~225 tok/turn, the
#     leanest shape). Adds `.planning/` to the repo's local .git/info/exclude so it never rides a commit.
# Prints `ADOPTED <plan_dir>` or `CREATED <plan_dir>` on the last line. pwf missing → `NO_PWF` + exit 3.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/common.sh"

CODE="${1:?usage: plan-init.sh <code_dir> \"<title>\"}"
TITLE="${2:?title required}"
[ -d "$CODE" ] || { echo "no such dir: $CODE" >&2; exit 2; }

PWF="$(pwr_pwf_scripts)" || { echo "planning-with-files not installed (no resolve-plan-dir.sh found) — falling back to plan-log.md only"; echo "NO_PWF"; exit 3; }

cd "$CODE"
# --- resolve: does a plan already exist here? (pwf's own resolver = the same one its hooks use) ---
EXISTING="$(sh "$PWF/resolve-plan-dir.sh" 2>/dev/null || true)"
if [ -n "$EXISTING" ] && [ -f "$EXISTING/task_plan.md" ]; then
  echo "an active pwf plan already resolves here — adopting it (not creating a second one)."
  echo "ADOPTED $EXISTING"; exit 0
fi
if [ -f "$CODE/task_plan.md" ]; then
  echo "a legacy root task_plan.md already exists here — adopting it."
  echo "ADOPTED $CODE"; exit 0
fi

# --- init: gated + smart ---
OUT="$(sh "$PWF/init-session.sh" --gated "$TITLE" 2>&1)" || { echo "$OUT" >&2; exit 1; }
NEW="$(sh "$PWF/resolve-plan-dir.sh" 2>/dev/null || true)"
[ -n "$NEW" ] && [ -f "$NEW/task_plan.md" ] || { echo "init ran but no plan resolves:" >&2; echo "$OUT" >&2; exit 1; }
# leanest injection shape: add inject-smart to the mode tokens (space-separated per pwf)
if [ -f "$NEW/.mode" ] && ! grep -q 'inject-smart' "$NEW/.mode"; then
  printf ' inject-smart' >> "$NEW/.mode"
fi
# keep .planning/ out of the repo's git status (local exclude, same trick as .claude/worktrees/)
if GD="$(git rev-parse --git-dir 2>/dev/null)"; then
  EXCL="$GD/info/exclude"; mkdir -p "$(dirname "$EXCL")"
  grep -qxF ".planning/" "$EXCL" 2>/dev/null || printf '.planning/\n' >> "$EXCL"
fi
echo "$OUT" | grep -E 'Created|Mode:' | sed 's/^/  /'
echo "mode: $(cat "$NEW/.mode")"
echo "CREATED $NEW"
