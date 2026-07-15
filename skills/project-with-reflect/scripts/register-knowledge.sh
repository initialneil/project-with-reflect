#!/usr/bin/env bash
# Register a KNOWLEDGE module — a reusable practice / recipe / reference that serves many
# projects — as a real user-scope skill (knowledge IS a personal skill): a folder
# knowledge/<slug>/ with <slug>.md (the content, Obsidian folder note) + SKILL.md (the
# loader, giving /<slug> autocomplete + description auto-trigger), symlinked into
# ~/.claude/skills and ~/.codex/skills like every other entity.
#   register-knowledge.sh <slug>
# Re-running on an existing FLAT note (knowledge/<slug>.md) migrates it to the folder form,
# preserving content. For things you OPERATE, register a CONNECTION instead:
#   register-api / register-mcp / register-machine / register-device.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/common.sh"; pwr_first_run_guard; pwr_ensure_root
NAME="${1:?knowledge slug required}"
pwr_validate_name "knowledge slug" "$NAME"
KDIR="$PWR_ROOT/knowledge/$NAME"
pwr_check_skill_collision "$NAME" "$KDIR" || exit 1
mkdir -p "$KDIR"

# migrate a legacy flat note into the folder as its folder note
if [ -f "$PWR_ROOT/knowledge/$NAME.md" ]; then
  mv "$PWR_ROOT/knowledge/$NAME.md" "$KDIR/$NAME.md"
  echo "Migrated flat note knowledge/$NAME.md -> knowledge/$NAME/$NAME.md"
fi
[ -f "$KDIR/$NAME.md" ] || printf -- '---\ntags:\n  - knowledge\n---\n# %s\n' "$NAME" > "$KDIR/$NAME.md"

pwr_install_skill "$KDIR" "$NAME" "$HERE/../templates/knowledge-SKILL.md.tmpl"
pwr_registry_put knowledge "$NAME" "{\"path\":\"knowledge/$NAME/$NAME.md\"}"
echo "Registered knowledge skill '$NAME' at $KDIR (content: $NAME.md, loader: SKILL.md)."
echo "Tailor SKILL.md's description to a targeted 'Use when ...' so /$NAME auto-triggers well."
echo "Link to a project: /<project> use-knowledge $NAME"
