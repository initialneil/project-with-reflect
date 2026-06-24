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
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/common.sh"; pwr_first_run_guard; pwr_ensure_root
NAME="${1:?knowledge name required}"; KIND="${2:-note}"; SETUP="${3:-}"
KDIR="$PWR_ROOT/knowledge/$NAME"; mkdir -p "$KDIR"
# Note file is <name>.md (matches the folder name) so it attaches as the Obsidian folder
# note when the root is a vault — same convention as a project's <name>.md dashboard.
KFILE="$KDIR/$NAME.md"

# Scaffolds are clean headings + real structure only — no meta-notes about opting in, no
# comment cruft (that guidance lives in SKILL.md). The model fills the sections with real
# content; what's known now (the setup line) goes in verbatim.
if [ ! -f "$KFILE" ]; then
  case "$KIND" in
    mcp)
      cat > "$KFILE" <<EOF
---
tags:
  - knowledge
kind: mcp
---
# $NAME

## Setup — already wired (user scope)
\`${SETUP:-claude mcp add --scope user $NAME -- <command...>}\`
Verify: \`claude mcp get $NAME\` · re-add on a new machine with the line above.

## Tools exposed
\`mcp__${NAME}__*\`

## Usage rules

## Gotchas
EOF
      ;;
    api)
      cat > "$KFILE" <<EOF
---
tags:
  - knowledge
kind: api
---
# $NAME

## Setup
${SETUP:-_(install + auth steps — fill in)_}
Secrets live in env/keychain — **never on disk here.**

## Usage rules

## Gotchas
EOF
      ;;
    *)
      printf -- '---\ntags:\n  - knowledge\nkind: note\n---\n# %s\n' "$NAME" > "$KFILE"
      ;;
  esac
fi

pwr_registry_put knowledge "$NAME" "{\"dir\":\"$KDIR\",\"kind\":\"$KIND\"}"
echo "Registered global knowledge '$NAME' (kind=$KIND) at $KDIR/$NAME.md"
# If the knowledge dir lives in an Obsidian vault with folder-notes, attach <name>/<name>.md.
bash "$HERE/obsidian-folder-note.sh" "$KDIR" || true
[ "$KIND" = "mcp" ] && echo "Reminder: ensure the MCP is wired — 'claude mcp add --scope user $NAME ...' (then 'claude mcp get $NAME')."
exit 0
