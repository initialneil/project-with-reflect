#!/usr/bin/env bash
# Register a GLOBAL knowledge module any project can opt into (kind: note | mcp | api).
#   register-knowledge.sh <name> [kind] [setup_note]
#     note (default) — prose-only knowledge.
#     mcp            — an MCP server. The MODEL runs `claude mcp add --scope user <name> ...`
#                      FIRST (it knows the right command/transport for this server and
#                      confirms with the user), then calls this with kind=mcp and the
#                      exact add command as <setup_note> to record it.
#     api            — an external API/SDK setup (keys via env/keychain, never on disk).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/common.sh"; pwr_ensure_root
NAME="${1:?knowledge name required}"; KIND="${2:-note}"; SETUP="${3:-}"
KDIR="$PWR_ROOT/knowledge/$NAME"; mkdir -p "$KDIR"
KFILE="$KDIR/knowledge.md"

if [ ! -f "$KFILE" ]; then
  case "$KIND" in
    mcp)
      cat > "$KFILE" <<EOF
# $NAME (MCP)

> Global, agent-usable MCP. A project opts in via \`config.json.knowledge: ["$NAME"]\`.

## What it is
(one line)

## Setup — already wired (user scope)
\`${SETUP:-claude mcp add --scope user $NAME -- <command...>}\`
Verify: \`claude mcp get $NAME\` · re-add on a new machine with the line above.

## Tools exposed
\`mcp__${NAME}__*\`

## Usage rules
- (when to reach for it; what NOT to do)

## Gotchas
- (editor must be open / auth / port / etc.)
EOF
      ;;
    api)
      cat > "$KFILE" <<EOF
# $NAME (API)

> Global, agent-usable API/SDK setup. Opt in via \`config.json.knowledge: ["$NAME"]\`.

## Setup
${SETUP:-(install + auth steps)}
Secrets live in env/keychain — **never on disk here.**

## Usage rules
-

## Gotchas
-
EOF
      ;;
    *)
      printf '# %s\n\n> Global knowledge module. Opt in via `config.json.knowledge: ["%s"]`.\n\n-\n' "$NAME" "$NAME" > "$KFILE"
      ;;
  esac
fi

pwr_registry_put knowledge "$NAME" "{\"dir\":\"$KDIR\",\"kind\":\"$KIND\"}"
echo "Registered global knowledge '$NAME' (kind=$KIND) at $KDIR"
[ "$KIND" = "mcp" ] && echo "Reminder: ensure the MCP is wired — 'claude mcp add --scope user $NAME ...' (then 'claude mcp get $NAME')."
exit 0
