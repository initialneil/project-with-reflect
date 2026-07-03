#!/usr/bin/env bash
# Register a reusable sub-agent definition.
#   register-agent.sh <name>
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/common.sh"; pwr_first_run_guard; pwr_ensure_root
NAME="${1:?agent name required}"
pwr_validate_name "agent name" "$NAME"
ADIR="$PWR_ROOT/agents/$NAME"; mkdir -p "$ADIR"
[ -f "$ADIR/agent.md" ] || printf '# %s — reusable sub-agent\n\n**Role:** \n**Use when:** \n**Tools:** \n' "$NAME" > "$ADIR/agent.md"
pwr_registry_put agents "$NAME" "{\"dir\":\"$ADIR\"}"
echo "Registered agent '$NAME' at $ADIR"
