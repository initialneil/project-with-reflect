#!/usr/bin/env bash
# done-check.sh <project_dir> <workstream> [<code_dir>]
# The termination oracle for a "done" claim — deterministic, like doctor. It judges the ARTIFACTS on
# disk, not the transcript, so "I finished phase 1–2 → all done" can't pass silently.
#
#   1. Active pwf plan (resolved by pwf's own resolve-plan-dir.sh from <code_dir>, default $PWD):
#      phases complete/total, the in_progress + pending phase names, the plan's ## Next Step.
#      → any phase not complete = NOT DONE (exit 1).
#   2. The lane head's ## Delivery handbook checklist — printed for the agent to walk line by line
#      (it's the project's own definition of "delivered"; pwf knows nothing about it).
#
# No pwf plan resolves → reports that (short task / not a pwf run) and exits 0 on the plan axis;
# the Delivery handbook still prints. Never modifies anything.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/common.sh"

PDIR="${1:?usage: done-check.sh <project_dir> <workstream> [<code_dir>]}"
WS="${2:?workstream required}"
CODE="${3:-$PWD}"
pwr_validate_name "workstream name" "$WS"

HEAD="$PDIR/workstreams/$WS/$WS.md"
RC=0

echo "done-check · $WS"
echo "════════════════════════════════════════"

# ---- 1. pwf plan ----
PLAN=""
if PWF="$(pwr_pwf_scripts)"; then
  PDIR_RESOLVED="$(cd "$CODE" 2>/dev/null && sh "$PWF/resolve-plan-dir.sh" 2>/dev/null)"
  if [ -n "$PDIR_RESOLVED" ] && [ -f "$PDIR_RESOLVED/task_plan.md" ]; then
    PLAN="$PDIR_RESOLVED/task_plan.md"
  elif [ -f "$CODE/task_plan.md" ]; then
    PLAN="$CODE/task_plan.md"          # pwf legacy root-mode plan
  fi
fi

if [ -z "$PLAN" ]; then
  # ---- fallback oracle (no pwf): the plan-log's TOP entry as a checklist ----
  # A multi-phase plan written as `- [ ]` items in plan-log.md is countable without pwf; the agent ticks
  # `- [x]` as it goes. No checklist there → nothing to count (short task) → PASS on the plan axis.
  PLOG="$PDIR/workstreams/$WS/plan-log.md"
  if [ -f "$PLOG" ] && grep -qE '^### ' "$PLOG"; then
    TOP="$(awk '/^### /{n++} n==1{print} n>1{exit}' "$PLOG")"
    HDR="$(printf '%s\n' "$TOP" | head -1 | sed 's/^### //')"
    NCHK="$(printf '%s\n' "$TOP" | grep -cE '^\s*- \[[xX]\]' || true)"; : "${NCHK:=0}"
    NUN="$(printf '%s\n' "$TOP" | grep -cE '^\s*- \[ \]' || true)";   : "${NUN:=0}"
    NT=$((NCHK+NUN))
    echo "plan   : (no pwf plan under $CODE) → plan-log top entry: $HDR"
    if [ "$NT" -gt 0 ]; then
      echo "items  : $NCHK/$NT checked"
      if [ "$NUN" -gt 0 ]; then
        RC=1
        printf '%s\n' "$TOP" | grep -E '^\s*- \[ \]' | sed 's/^\s*- \[ \] */         ○ /'
        echo "verdict: ❌ NOT DONE — $NUN plan-log item(s) unchecked. Tick them (- [x]) as they finish, or re-plan explicitly."
      else
        echo "verdict: ✅ all $NT plan-log items checked"
      fi
    else
      echo "items  : (top entry has no - [ ] checklist — short task or prose plan; nothing to count)"
    fi
  else
    echo "plan   : (no active pwf plan under $CODE, no plan-log entries — short task)"
  fi
else
  # same counting rules as pwf check-complete.sh (both **Status:** and [inline] forms, per-field max)
  TOTAL=$(grep -c '^### Phase' "$PLAN" 2>/dev/null || true); : "${TOTAL:=0}"
  cnt() { local a b; a=$(grep -cF "**Status:** $1" "$PLAN" 2>/dev/null || true); b=$(grep -c "\[$1\]" "$PLAN" 2>/dev/null || true); : "${a:=0}"; : "${b:=0}"; [ "$b" -gt "$a" ] && echo "$b" || echo "$a"; }
  DONE=$(cnt complete); INPROG=$(cnt in_progress); PEND=$(cnt pending)
  NEXT="$(awk '/^## Next Step/{f=1;next} /^## /{f=0} f&&NF{print;exit}' "$PLAN")"
  echo "plan   : $PLAN"
  echo "phases : $DONE/$TOTAL complete · $INPROG in_progress · $PEND pending"
  [ -n "$NEXT" ] && echo "next   : $NEXT"
  if [ "$TOTAL" -gt 0 ] && [ "$DONE" -lt "$TOTAL" ]; then
    RC=1
    awk '
      /^### Phase/ { h=substr($0,5); next }
      /\*\*Status:\*\* in_progress/ || /\[in_progress\]/ { print "         ⏳ in_progress → " h; next }
      /\*\*Status:\*\* pending/     || /\[pending\]/     { print "         ○ pending     → " h; next }
    ' "$PLAN"
    echo "verdict: ❌ NOT DONE — $((TOTAL-DONE)) phase(s) unfinished. Finish them or explicitly re-plan (new plan-log entry) before claiming done."
  elif [ "$TOTAL" -gt 0 ]; then
    echo "verdict: ✅ all $TOTAL phases complete"
  fi
fi

# ---- 2. Delivery handbook (the project's own definition of delivered) ----
echo "────────────────────────────────────────"
if [ -f "$HEAD" ]; then
  # section starts at a line matching "## … Delivery handbook …" in any localization; ends at next "## "
  HB="$(awk 'f&&/^## /{exit} f{print} /^## .*(Delivery handbook|交付手册)/{f=1}' "$HEAD")"
  if [ -n "$HB" ]; then
    echo "delivery handbook ($WS.md) — walk EVERY line, report each as met / not met / n-a:"
    printf '%s\n' "$HB" | sed '/^[[:space:]]*$/d' | sed 's/^/   /'
  else
    echo "delivery handbook: (head has no Delivery handbook section — fill it; until then, define 'delivered' explicitly in your report)"
  fi
else
  echo "delivery handbook: (no head at $HEAD — run doctor)"
fi
echo "════════════════════════════════════════"
[ "$RC" = 0 ] && echo "done-check: PASS (plan axis) — now walk the handbook above and report line-by-line" \
              || echo "done-check: FAIL — do not report 'done'"
exit "$RC"
