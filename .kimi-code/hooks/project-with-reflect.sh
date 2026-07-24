#!/bin/sh
# Kimi Code hook adapter for project-with-reflect.
# Delegates to the canonical hook-autolog.sh script. Kimi passes event JSON via stdin.
# For PreToolUse we also emit {"decision":"allow"} so the tool is never blocked.
CTX="${1:-}"
[ -n "$CTX" ] || exit 0

# Locate the canonical hook-autolog.sh. Prefer the canonical scripts/ tree next to this repo,
# then fall back to a user-scope install.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SH="$REPO_ROOT/skills/project-with-reflect/scripts/hook-autolog.sh"
if [ ! -f "$SH" ]; then
  SH="$HOME/.agents/skills/project-with-reflect/scripts/hook-autolog.sh"
fi
if [ ! -f "$SH" ]; then
  SH="$HOME/.kimi-code/skills/project-with-reflect/scripts/hook-autolog.sh"
fi
if [ ! -f "$SH" ]; then
  SH="$HOME/.codex/skills/project-with-reflect/scripts/hook-autolog.sh"
fi
[ -f "$SH" ] || exit 0

if [ "$CTX" = "pretool" ]; then
  # Run the nudge, then explicitly allow the tool call.
  sh "$SH" "--context=$CTX" >&2 || true
  printf '{"decision":"allow"}\n'
  exit 0
fi

exec sh "$SH" "--context=$CTX"
