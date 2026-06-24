#!/usr/bin/env bash
# Register an MCP server connection as a skill under connections/.
#   register-mcp.sh <name> "<add command used>" ["tools/usage note"]
# The MODEL wires it FIRST — `claude mcp add --scope user <name> -- <command…>` (or
# `--transport http <name> <url>`), confirming with the user — THEN records it here so the
# re-add line and usage rules live with the connection. mcp__<name>__* tools become available.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/common.sh"; pwr_first_run_guard; pwr_ensure_root
TPL="$HERE/../templates"
NAME="${1:?mcp name required}"; ADDCMD="${2:-}"; NOTE="${3:-}"
CDIR="$PWR_ROOT/connections/$NAME"; mkdir -p "$CDIR"

python3 - "$CDIR/connection.json" "$NAME" "$ADDCMD" <<'PY'
import json, sys
path, name, addcmd = sys.argv[1:4]
m = {"name": name, "transport": "mcp", "tools": "mcp__%s__*" % name}
if addcmd: m["add_command"] = addcmd
json.dump(m, open(path, "w"), indent=2)
PY

python3 "$HERE/_note.py" "$CDIR/$NAME.md" "$NAME" connection \
  transport=mcp add_command="$ADDCMD"

pwr_install_skill "$CDIR" "$NAME" "$TPL/mcp-SKILL.md.tmpl"
pwr_registry_put connections "$NAME" "{\"transport\":\"mcp\"}"
echo "Registered mcp connection '$NAME' — skill at ~/.claude/skills/$NAME. Tools: mcp__${NAME}__*"
echo "Reminder: ensure it's wired — 'claude mcp add --scope user $NAME ...' (verify 'claude mcp get $NAME'). /reload-plugins to load."
