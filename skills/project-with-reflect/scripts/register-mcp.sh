#!/usr/bin/env bash
# Register an MCP server connection as a skill under connections/.
#   register-mcp.sh <name> "<add command used>" [docs_url]
# The MODEL wires it FIRST — `claude mcp add --scope user <name> -- <command…>` (or
# `--transport http <name> <url>`), confirming with the user — THEN records it here so the
# re-add line and usage rules live with the connection. mcp__<name>__* tools become available.
# docs_url = the server's docs/repo (recorded for grounding — fetch before coding against it).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/common.sh"; pwr_first_run_guard; pwr_ensure_root
TPL="$HERE/../templates"
NAME="${1:?mcp name required}"; pwr_validate_name "mcp name" "$NAME"; ADDCMD="${2:-}"; DOCS="${3:-}"
CDIR="$PWR_ROOT/connections/$NAME"; mkdir -p "$CDIR"

python3 - "$CDIR/connection.json" "$NAME" "$ADDCMD" "$DOCS" <<'PY'
import json, sys
path, name, addcmd, docs = sys.argv[1:5]
m = {"name": name, "transport": "mcp", "tools": "mcp__%s__*" % name}
if addcmd: m["add_command"] = addcmd
if docs: m["docs_url"] = docs
json.dump(m, open(path, "w"), indent=2)
PY

python3 "$HERE/_note.py" "$CDIR/$NAME.md" "$NAME" connection \
  transport=mcp add_command="$ADDCMD" docs_url="$DOCS"

pwr_install_skill "$CDIR" "$NAME" "$TPL/mcp-SKILL.md.tmpl"
pwr_registry_put connections "$NAME" "{\"transport\":\"mcp\"}"
echo "Registered mcp connection '$NAME' — installed as a Claude/Codex skill. Tools: mcp__${NAME}__*"
echo "Reminder: ensure it's wired in the active agent (for Claude Code: 'claude mcp add --scope user $NAME ...'). Restart/reload your agent if it does not see the new skill yet."
