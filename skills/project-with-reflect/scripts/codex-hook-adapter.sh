#!/bin/sh
# Codex JSON-protocol adapter for project-with-reflect's cross-agent hook.
# Lives in the canonical skill so plugin/user-scope hooks work from any cwd.
CTX="$1"
[ -n "$CTX" ] || exit 0

HERE="$(CDPATH= cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)"
SH="$HERE/hook-autolog.sh"
[ -f "$SH" ] || exit 0

if [ "$CTX" = "pretool" ]; then
  sh "$SH" "--context=$CTX" >&2 || true
  printf '{"decision":"allow"}\n'
  exit 0
fi

if [ "$CTX" = "sessionstart" ]; then
  OUT="$(sh "$SH" "--context=$CTX" 2>/dev/null || true)"
  [ -n "$OUT" ] || exit 0
  python3 - "$OUT" <<'PY'
import json, sys
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": sys.argv[1],
    }
}))
PY
  exit 0
fi

# Codex ignores plain stdout from PreCompact. The canonical hook still writes
# its disk checkpoint; wrap its status as supported JSON for visibility.
if [ "$CTX" = "precompact" ]; then
  OUT="$(sh "$SH" "--context=$CTX" 2>/dev/null || true)"
  [ -n "$OUT" ] || exit 0
  python3 - "$OUT" <<'PY'
import json, sys
print(json.dumps({"systemMessage": sys.argv[1]}))
PY
  exit 0
fi

exec sh "$SH" "--context=$CTX"
