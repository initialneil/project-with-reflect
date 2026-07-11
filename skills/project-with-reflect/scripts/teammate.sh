#!/usr/bin/env bash
# Teammate lifecycle for cooperating workstreams (macOS + iTerm2). Deterministic ops only;
# the MODEL drives the protocol (handoff/pickup, the standby watch, the final flush).
#   teammate.sh <project_dir> assemble <workstream> --commander <lane>
#   teammate.sh <project_dir> dismiss  <workstream> --commander <lane>
#   teammate.sh <project_dir> status   <workstream>
#
# assemble → open an iTerm2 window running `claude "/<name> checkin <ws> --as-teammate-of <lane>"`,
#            write workstreams/<ws>/teammate.lock (iTerm2 session id), add <ws> to the commander
#            lane's stream.json "teammates". Already alive → no-op.
# dismiss  → remove <ws> from the commander's "teammates" + rm the lock. Never kills the window —
#            the model sends the "flush + stand down" baton first; the human closes the window.
# status   → print lock presence + liveness (checkin uses this to re-assemble dead teammates).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/common.sh"   # pwr_validate_name only — works off PDIR, no root needed

PDIR="${1:?usage: teammate.sh <project_dir> <assemble|dismiss|status> <workstream> [--commander <lane>]}"
ACTION="${2:?action required: assemble|dismiss|status}"
WS="${3:?workstream required}"
pwr_validate_name "workstream name" "$WS"
shift 3

LANE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --commander) LANE="${2:?--commander needs a value}"; pwr_validate_name "commander lane" "$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

CFG="$PDIR/config.json"
[ -f "$CFG" ] || { echo "no config.json at $PDIR (is this a registered project?)" >&2; exit 1; }
NAME="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['name'])" "$CFG")"
REPO="$(python3 -c "import json,sys;print(json.load(open(sys.argv[1])).get('repo') or '')" "$CFG")"
WSDIR="$PDIR/workstreams/$WS"
LOCK="$WSDIR/teammate.lock"
[ -d "$WSDIR" ] || { echo "workstream '$WS' not registered (no $WSDIR) — register-workstream first" >&2; exit 1; }

# Liveness = the locked iTerm2 session still exists ON THIS HOST.
# ponytail: session-alive ≠ claude-alive (a Ctrl-C'd claude leaves the shell session up); good enough —
# the model reports staleness when a "live" teammate stops answering batons.
lock_liveness() {
  [ -f "$LOCK" ] || { echo "absent"; return; }
  local host sid
  host="$(python3 -c "import json;print(json.load(open('$LOCK')).get('host',''))" 2>/dev/null || echo "")"
  sid="$(python3 -c "import json;print(json.load(open('$LOCK')).get('sid',''))" 2>/dev/null || echo "")"
  [ "$host" = "$(hostname)" ] || { echo "other-host"; return; }   # vault syncs across machines; lock is machine-local
  [ -n "$sid" ] || { echo "dead"; return; }
  osascript - "$sid" <<'OSA' 2>/dev/null || echo "dead"
on run argv
  set target to item 1 of argv
  tell application "System Events"
    if not (name of processes) contains "iTerm2" then return "dead"
  end tell
  tell application "iTerm"
    repeat with w in windows
      repeat with t in tabs of w
        repeat with s in sessions of t
          if (id of s as text) is target then return "alive"
        end repeat
      end repeat
    end repeat
  end tell
  return "dead"
end run
OSA
}

edit_teammates() {  # edit_teammates <add|remove>
  local op="$1" sj="$PDIR/workstreams/$LANE/stream.json"
  [ -f "$sj" ] || { echo "commander lane '$LANE' has no stream.json" >&2; exit 1; }
  python3 - "$sj" "$WS" "$op" <<'PY'
import json, sys
sj, ws, op = sys.argv[1:4]
d = json.load(open(sj))
t = d.setdefault("teammates", [])
if op == "add" and ws not in t: t.append(ws)
if op == "remove" and ws in t: t.remove(ws)
if not t: d.pop("teammates", None)
json.dump(d, open(sj, "w"), indent=2)
PY
}

case "$ACTION" in
  status)
    echo "ws=$WS lock=$([ -f "$LOCK" ] && echo present || echo absent) liveness=$(lock_liveness)"
    ;;

  assemble)
    [ -n "$LANE" ] || { echo "--commander <lane> required for assemble" >&2; exit 2; }
    [ "$LANE" = "$WS" ] && { echo "a lane can't be its own teammate" >&2; exit 2; }
    if [ "$(lock_liveness)" = "alive" ]; then
      edit_teammates add
      echo "teammate '$WS' already assembled (window alive) — no-op"
      exit 0
    fi
    LAND="$PDIR"; [ -n "$REPO" ] && [ -d "$REPO" ] && LAND="$REPO"
    PROMPT="/$NAME checkin $WS --as-teammate-of $LANE"
    SID="$(osascript - "$LAND" "$PROMPT" <<'OSA'
on run argv
  set landDir to item 1 of argv
  set thePrompt to item 2 of argv
  tell application "iTerm"
    activate
    set newWindow to (create window with default profile)
    tell current session of newWindow
      write text "cd " & quoted form of landDir & " && claude " & quoted form of thePrompt
      return id as text
    end tell
  end tell
end run
OSA
)"
    [ -n "$SID" ] || { echo "iTerm2 launch failed — open a window manually and run: claude \"$PROMPT\"" >&2; exit 1; }
    python3 - "$LOCK" "$SID" "$LANE" <<PY
import json, sys, socket, datetime
lock, sid, lane = sys.argv[1:4]
json.dump({"sid": sid, "commander": lane, "host": socket.gethostname(),
           "started": datetime.datetime.now().strftime("%Y-%m-%d %H:%M")}, open(lock, "w"), indent=2)
PY
    edit_teammates add
    echo "assembled teammate '$WS' (commander: $LANE) — iTerm2 session $SID, lock at $LOCK"
    ;;

  dismiss)
    [ -n "$LANE" ] || { echo "--commander <lane> required for dismiss" >&2; exit 2; }
    LIVE="$(lock_liveness)"
    edit_teammates remove
    rm -f "$LOCK"
    echo "dismissed teammate '$WS' (window was: $LIVE) — lane stays a normal workstream; checkin it in a fresh window anytime"
    ;;

  *) echo "unknown action '$ACTION' (assemble|dismiss|status)" >&2; exit 2 ;;
esac
