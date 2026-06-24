#!/usr/bin/env bash
# Register a plain-markdown KNOWLEDGE note — reference only, the kind that piles up over time
# (reflect/meta-reflect promote learnings into these). Flat file: knowledge/<slug>.md.
#   register-knowledge.sh <slug>
# Knowledge is NOT a skill and NOT operable. For things you operate, register a CONNECTION:
#   register-api (HTTP/WS APIs), register-mcp (MCP servers), register-machine (ssh),
#   register-device (serial/USB). Those become skills under connections/.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/common.sh"; pwr_first_run_guard; pwr_ensure_root
NAME="${1:?knowledge slug required}"
mkdir -p "$PWR_ROOT/knowledge"
KFILE="$PWR_ROOT/knowledge/$NAME.md"
[ -f "$KFILE" ] || printf -- '---\ntags:\n  - knowledge\n---\n# %s\n' "$NAME" > "$KFILE"
pwr_registry_put knowledge "$NAME" "{\"path\":\"knowledge/$NAME.md\"}"
echo "Registered knowledge note '$NAME' at $KFILE (plain md)."
echo "Link to a project: /<project> use-knowledge $NAME"
