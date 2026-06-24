#!/usr/bin/env bash
# Register a GLOBAL knowledge module (e.g. an MCP/API setup) any project can opt into.
#   register-knowledge.sh <name>
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/common.sh"; pwr_ensure_root
NAME="${1:?knowledge name required}"
KDIR="$PWR_ROOT/knowledge/$NAME"; mkdir -p "$KDIR"
[ -f "$KDIR/knowledge.md" ] || printf '# %s\n\n> Global, agent-usable knowledge module. Setup + usage rules.\n> A project opts in via `config.json.knowledge: ["%s"]`.\n' "$NAME" "$NAME" > "$KDIR/knowledge.md"
pwr_registry_put knowledge "$NAME" "{\"dir\":\"$KDIR\"}"
echo "Registered global knowledge '$NAME' at $KDIR"
