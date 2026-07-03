#!/usr/bin/env bash
# Register / refresh a project workstream (a reusable lane of work). Deterministic git + stream.json;
# the MODEL is the natural-language front-end (it parses "v081 based on v080, just track" → these flags).
#   register-workstream.sh <project_dir> <workstream> [--base <b>] [--pr-into <p>] [--track-only] [--path <worktree_dir>]
#
# Realization (unless --track-only, which is lineage-only — no git), by config.workstream_mode:
#   worktree → git worktree add <repo>/.claude/worktrees/<workstream> -b <workstream> <base>
#              (default path, auto git-excluded; --path overrides)
#   in-repo  → git checkout -b <workstream> <base>            (switches HEAD — ready to work)
#   logical  → no git (a logical workstream inside the one working tree)
# Re-register (the workstream already exists) = idempotent LINEAGE update: change base/pr_into only;
# preserve cycle + status + log.md; never re-create or touch git.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

source "$HERE/common.sh"   # for pwr_validate_name (no root needed — this script works off PDIR)

PDIR="${1:?usage: register-workstream.sh <project_dir> <workstream> [--base b] [--pr-into p] [--track-only] [--path dir]}"
BR="${2:?workstream name required}"
pwr_validate_name "workstream name" "$BR"   # BR becomes paths + a `rm -rf` target on failure — validate FIRST
shift 2

BASE=""; PRINTO=""; TRACK_ONLY=0; WT_PATH=""
while [ $# -gt 0 ]; do
  case "$1" in
    --base)       BASE="${2:?--base needs a value}"; shift 2 ;;
    --pr-into)    PRINTO="${2:?--pr-into needs a value}"; shift 2 ;;
    --track-only) TRACK_ONLY=1; shift ;;
    --path)       WT_PATH="${2:?--path needs a value}"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

CFG="$PDIR/config.json"
[ -f "$CFG" ] || { echo "no config.json at $PDIR (is this a registered project?)" >&2; exit 1; }
NAME="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['name'])" "$CFG")"
REPO="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1])).get('repo') or '')" "$CFG")"
WSM="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1])).get('workstream_mode') or 'in-repo')" "$CFG")"
LOC="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1])).get('location') or 'local')" "$CFG")"
HOST="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1])).get('host_connection') or '')" "$CFG")"

WS="$PDIR/workstreams/$BR"
SJ="$WS/stream.json"

# ---- Re-register: idempotent lineage-only update (no git; cycle/status/log preserved) ----
if [ -f "$SJ" ]; then
  python3 - "$SJ" "$BASE" "$PRINTO" "$TRACK_ONLY" <<'PY'
import json, sys
sj, base, printo, track = sys.argv[1:5]
d = json.load(open(sj))
if base:   d["base"] = base
if printo: d["pr_into"] = printo
elif base and not d.get("pr_into"): d["pr_into"] = base
if track == "1": d["kind"] = "tracked"
json.dump(d, open(sj, "w"), indent=2)
PY
  bash "$HERE/gen-command.sh" "$NAME" "$BR" workstream "$PDIR" >/dev/null
  NEWBASE="$(python3 -c "import json;print(json.load(open('$SJ'))['base'])")"
  echo "Updated lineage for '$BR' (base=$NEWBASE). Re-register is lineage-only — cycle / log / git untouched."
  exit 0
fi

# ---- New workstream: validate up front ----
[ -n "$BASE" ] || { echo "--base <b> required for a new workstream" >&2; exit 2; }
PRINTO="${PRINTO:-$BASE}"
# Remote project: no local checkout to run git in, so a workstream is lineage-only. Auto-degrade a
# would-be local-git realization (worktree / in-repo) to tracked, with a notice — the user creates
# the actual git branch on the host themselves if they want one.
if [ "$LOC" = "remote" ] && [ "$TRACK_ONLY" != "1" ] && { [ "$WSM" = "worktree" ] || [ "$WSM" = "in-repo" ]; }; then
  echo "  remote project ($NAME) — recording lineage only (no local git). To make a real branch on" >&2
  echo "  the host: /${HOST:-<host>} 'git -C <root> checkout -b $BR origin/$BASE'." >&2
  TRACK_ONLY=1
fi
# worktree mode: default the worktree dir to <repo>/.claude/worktrees/<workstream> unless the user passed
# --path. Zero-friction, lives with the repo, trivially cleaned; kept out of the repo's git status via
# a local .git/info/exclude entry (below) so it never pollutes commits.
DEFAULT_WT=0
if [ "$TRACK_ONLY" != "1" ] && [ "$WSM" = "worktree" ] && [ -z "$WT_PATH" ]; then
  [ -n "$REPO" ] || { echo "no repo in config — cannot place a worktree" >&2; exit 2; }
  WT_PATH="$REPO/.claude/worktrees/$BR"; DEFAULT_WT=1
fi

resolve_start() {  # echo a valid start-point for $1 (prefer origin/), or return 1
  if git -C "$REPO" rev-parse --verify --quiet "origin/$1" >/dev/null 2>&1; then echo "origin/$1"; return 0; fi
  if git -C "$REPO" rev-parse --verify --quiet "$1"        >/dev/null 2>&1; then echo "$1";        return 0; fi
  return 1
}

mkdir -p "$WS"
[ -f "$WS/log.md" ] || echo "# $BR — stream log" > "$WS/log.md"
KIND="logical"; WORKTREE_PATH=""

if [ "$TRACK_ONLY" = "1" ]; then
  KIND="tracked"                                   # lineage only, no git
else
  case "$WSM" in
    worktree)
      START="$(resolve_start "$BASE")" || { echo "base '$BASE' not found (origin/$BASE or $BASE)" >&2; rm -rf "$WS"; exit 1; }
      mkdir -p "$(dirname "$WT_PATH")"
      # keep the default in-repo worktree location out of the repo's git status (local exclude only)
      if [ "$DEFAULT_WT" = "1" ]; then
        EXCL="$REPO/.git/info/exclude"
        [ -f "$EXCL" ] && ! grep -qxF ".claude/worktrees/" "$EXCL" 2>/dev/null && \
          printf '.claude/worktrees/\n' >> "$EXCL"
      fi
      git -C "$REPO" worktree add "$WT_PATH" -b "$BR" "$START" || { rm -rf "$WS"; exit 1; }
      KIND="worktree"; WORKTREE_PATH="$(cd "$WT_PATH" && pwd)" ;;
    in-repo)
      START="$(resolve_start "$BASE")" || { echo "base '$BASE' not found (origin/$BASE or $BASE)" >&2; rm -rf "$WS"; exit 1; }
      git -C "$REPO" checkout -b "$BR" "$START" || { rm -rf "$WS"; exit 1; }
      KIND="branch" ;;
    logical|*) KIND="logical" ;;
  esac
fi

python3 - "$SJ" "$BR" "$BASE" "$PRINTO" "$KIND" "$WORKTREE_PATH" <<'PY'
import json, sys
sj, br, base, printo, kind, wt = sys.argv[1:7]
json.dump({"branch": br, "base": base, "pr_into": printo, "kind": kind,
           "worktree_path": (wt or None), "status": "active", "cycle": 1},
          open(sj, "w"), indent=2)
PY

bash "$HERE/gen-command.sh" "$NAME" "$BR" workstream "$PDIR" >/dev/null
# Next step is always: check into the workstream (loads log+base+lessons, runs the cwd decision, recaps).
NEXT="Next → /$NAME-$BR checkin   (picks up the workstream: load log+base+lessons, handle the working dir, recap)"
case "$KIND" in
  tracked)  echo "Registered '$BR' (tracked: lineage on $BASE, no git)."; echo "$NEXT" ;;
  branch)   echo "Registered '$BR' (in-repo branch off $BASE; HEAD switched)."; echo "$NEXT" ;;
  worktree) echo "Registered '$BR' (worktree off $BASE at $WORKTREE_PATH)."; echo "$NEXT" ;;
  logical)  echo "Registered '$BR' (logical workstream on $BASE; same working tree)."; echo "$NEXT" ;;
esac
