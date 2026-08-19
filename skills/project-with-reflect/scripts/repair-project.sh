#!/usr/bin/env bash
# repair-project.sh <project_dir> [--apply] [<workstream>]
# Deterministic structural repair of a project's workstreams — the "project doctor".
# Fixes the drift that behavioral checkin/reflect keep skipping (they only *propose*, and can ask
# questions instead of acting). This script just acts.
#
#   PRE-HEAD lane   — <ws>.md is still an old-format goal/plan log (no `## Basics` head marker):
#                     migrate it → move <ws>.md VERBATIM into plan-log.md, then write a bounded head
#                     (Basics auto-filled from stream.json, Now seeded from the moved log's top entries).
#                     Verbatim-preserving: the old log is never lost — it lands in plan-log.md untouched.
#   missing head    — no <ws>.md at all: scaffold a fresh head skeleton.
#   missing sibling — a head lane with no plan-log.md / log.md: create the stub.
#   stale head      — head `Last updated` stamp older than plan-log's top `### <date>`: FLAG only
#                     (rebalancing `## Now` needs judgment — that is reflect's job, not a mechanical fix).
#
# Default = DRY RUN (report only, writes nothing). Pass --apply to write. Idempotent: a healthy head
# lane is left alone. An optional <workstream> scopes the repair to one lane.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/common.sh"   # pwr_validate_name

PDIR="${1:?usage: repair-project.sh <project_dir> [--apply] [<workstream>]}"; shift
APPLY=0; ONLY=""
while [ $# -gt 0 ]; do
  case "$1" in
    --apply) APPLY=1; shift ;;
    -*) echo "unknown arg: $1" >&2; exit 2 ;;
    *) ONLY="$1"; shift ;;
  esac
done
[ -z "$ONLY" ] || pwr_validate_name "workstream name" "$ONLY"

CFG="$PDIR/config.json"
[ -f "$CFG" ] || { echo "no config.json at $PDIR (is this a registered project?)" >&2; exit 1; }
WSDIR="$PDIR/workstreams"
[ -d "$WSDIR" ] || { echo "no workstreams/ at $PDIR — nothing to repair"; exit 0; }

DATE="$(date +%F)"
MIGRATED=0; FIXED=0; FLAG=0; OKN=0; WARN=0

# write the bounded head markdown to stdout: args = BR, stream.json, plan-log (may be empty/absent), date
gen_head() {
  python3 - "$1" "$2" "$3" "$4" <<'PY'
import json, os, re, sys
br, sj, plan, date = sys.argv[1:5]
d = {}
if os.path.isfile(sj):
    try: d = json.load(open(sj))
    except Exception: d = {}
code = d.get("worktree_path") or ""
branch, base, pr = d.get("branch") or "", d.get("base") or "", d.get("pr_into") or ""
code_line = " · ".join(x for x in [
    code or "(code dir)",
    (f"branch `{branch}`" if branch else ""),
    (f"base `{base}` → PR `{pr}`" if base else ""),
] if x)
wp = (d.get("working_pattern") or "").strip()
if wp:
    teaser = re.sub(r"\s+", " ", wp)
    if len(teaser) > 200: teaser = teaser[:197] + "…"
    pattern = f"{teaser}  (authority: stream.json.working_pattern)"
else:
    pattern = "—"
# top plan-log entries → Now seed
recent = []
if plan and os.path.isfile(plan):
    for ln in open(plan):
        if ln.startswith("### "):
            recent.append(ln[4:].strip())
            if len(recent) >= 3: break
seed = "\n".join(f"  - {r}" for r in recent) if recent else "  - (plan-log.md is the full history)"
print(f"""# {br} — workstream head
> [!note] One-liner
> (migrated from goal/plan log by doctor {date} — fill in what this lane is + its current mission)

Last updated: {date} · by doctor

## Basics
| | |
|---|---|
| code | {code_line} |
| pattern | {pattern} |
| red lines | (fill from [[decisions]] / working_pattern) |

## Delivery handbook
Delivered = (define it in one line). Walk before shipping:
1. (grows via reflect from repeated user feedback)

## Now
- doing: — (draft from plan-log.md top entries below)
- next: —
- risks: —
- plan: — (active pwf plan dir for a long task, e.g. `.planning/<id>`)
recent (from plan-log.md, newest-first):
{seed}

## Next Step
(one imperative line — the single next action; mirrors the active pwf plan's `## Next Step`)

## Read-when
- (doing X → read [[lesson]])

## Archive
plan-log.md (full goal/plan history — migrated {date}) · log.md · [[decisions]]""")
PY
}

for WS in "$WSDIR"/*/; do
  [ -f "$WS/stream.json" ] || continue
  BR="$(basename "$WS")"
  [ -z "$ONLY" ] || [ "$ONLY" = "$BR" ] || continue
  HEAD="$WS/$BR.md"; PLAN="$WS/plan-log.md"; LOG="$WS/log.md"

  # a head is marked by its `Last updated:` stamp (universal) or a Basics section in any localization
  # (e.g. `## 基本信息（Basics）`); a <ws>.md with none of these is a pre-head goal/plan log.
  is_head=0
  [ -f "$HEAD" ] && grep -qE '^Last updated:|^## Basics|^## 基本信息|（Basics|Basics）' "$HEAD" && is_head=1

  # --- healthy head: ensure siblings, flag staleness ---
  if [ "$is_head" = 1 ]; then
    made=""
    if [ ! -f "$LOG" ];  then made="log.md";                       [ "$APPLY" = 1 ] && echo "# $BR — stream log" > "$LOG"; fi
    if [ ! -f "$PLAN" ]; then made="${made:+$made, }plan-log.md";  [ "$APPLY" = 1 ] && echo "# $BR — goal/plan log (newest-first)" > "$PLAN"; fi
    stamp="$(grep -oE 'Last updated:[^0-9]*[0-9]{4}-[0-9]{2}-[0-9]{2}' "$HEAD" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1 || true)"
    ptop=""
    [ -f "$PLAN" ] && ptop="$(grep -oE '^### [0-9]{4}-[0-9]{2}-[0-9]{2}' "$PLAN" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1 || true)"
    if [ -n "$made" ]; then
      echo "[fix]  $BR: created missing $made"; FIXED=$((FIXED+1))
    elif [ -n "$stamp" ] && [ -n "$ptop" ] && [[ "$stamp" < "$ptop" ]]; then
      echo "[flag] $BR: head stale (stamp $stamp < plan-log top $ptop) — run reflect to rebalance ## Now"; FLAG=$((FLAG+1))
    else
      echo "[ok]   $BR: head"; OKN=$((OKN+1))
    fi
    continue
  fi

  # --- <ws>.md missing entirely: scaffold a fresh head (nothing to migrate) ---
  if [ ! -f "$HEAD" ]; then
    if [ "$APPLY" = 1 ]; then
      gen_head "$BR" "$WS/stream.json" "$PLAN" "$DATE" > "$HEAD"
      [ -f "$LOG" ]  || echo "# $BR — stream log" > "$LOG"
      [ -f "$PLAN" ] || echo "# $BR — goal/plan log (newest-first)" > "$PLAN"
      echo "[fix]  $BR: scaffolded head (no <ws>.md existed)"
    else
      echo "[fix?] $BR: no <ws>.md — would scaffold a head skeleton"
    fi
    FIXED=$((FIXED+1)); continue
  fi

  # --- PRE-HEAD: <ws>.md is an old-format goal/plan log → migrate ---
  # guard: a plan-log.md that ALREADY holds real entries means both files carry a log — ambiguous, skip.
  if [ -f "$PLAN" ] && grep -qE '^### ' "$PLAN"; then
    echo "[warn] $BR: pre-head <ws>.md AND a non-empty plan-log.md both exist — skipping (merge by hand)"; WARN=$((WARN+1)); continue
  fi
  if [ "$APPLY" = 1 ]; then
    mv "$HEAD" "$PLAN"                          # verbatim: the old log becomes plan-log.md untouched
    gen_head "$BR" "$WS/stream.json" "$PLAN" "$DATE" > "$HEAD"
    [ -f "$LOG" ] || echo "# $BR — stream log" > "$LOG"
    echo "[MIGRATED] $BR: <ws>.md → plan-log.md (verbatim), wrote bounded head"
  else
    lines="$(wc -l < "$HEAD" | tr -d ' ')"
    echo "[MIGRATE?] $BR: pre-head goal/plan log ($lines lines) → would move to plan-log.md + write head"
  fi
  MIGRATED=$((MIGRATED+1))
done

echo
if [ "$APPLY" = 1 ]; then
  echo "doctor(project) summary: $MIGRATED migrated, $FIXED fixed, $FLAG flagged, $OKN ok, $WARN warn"
else
  echo "doctor(project) DRY RUN: $MIGRATED to migrate, $FIXED to fix, $FLAG flagged, $OKN ok, $WARN warn  —  re-run with --apply to write"
fi
[ "$WARN" -gt 0 ] && exit 1 || exit 0
