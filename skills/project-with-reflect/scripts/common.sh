#!/usr/bin/env bash
# Shared helpers for project-with-reflect. Source me: `source common.sh`.
# Deterministic file/registry ops only — judgment (reflect, lessons) is the model's job.
set -euo pipefail

# Root resolution order: explicit env > saved pointer > legacy default.
# The pointer makes resolution robust even when the (non-interactive) shell never
# sourced the rc export — bootstrap.sh writes it.
PWR_POINTER="${XDG_CONFIG_HOME:-$HOME/.config}/project-with-reflect/root"
if [ -n "${PROJECT_WITH_REFLECT_ROOT:-}" ]; then
  PWR_ROOT="$PROJECT_WITH_REFLECT_ROOT"
elif [ -f "$PWR_POINTER" ]; then
  PWR_ROOT="$(cat "$PWR_POINTER")"
else
  PWR_ROOT="$HOME/.project-with-reflect"
fi

# A bash script can't AskUserQuestion, so on a genuine first run we REFUSE and
# signal the model to prompt for a root path. Call this at the top of every entry
# script BEFORE pwr_ensure_root. Exit 3 = "ask the user, then bootstrap + retry".
pwr_first_run_guard() {
  [ -n "${PROJECT_WITH_REFLECT_ROOT:-}" ] && return 0
  [ -f "$PWR_POINTER" ] && return 0
  [ -d "$HOME/.project-with-reflect" ] && return 0   # legacy install, no pointer
  {
    echo "PWR_FIRST_RUN: no project-with-reflect root configured."
    echo "Ask the user where to keep it. A CUSTOM synced + readable path is RECOMMENDED."
    echo "DETECT what they have and offer those: their Obsidian vault, or a cloud file-sync"
    echo "folder (Dropbox / Google Drive / OneDrive / iCloud / Nutstore / ...). On macOS these"
    echo "are often under ~/Library/CloudStorage/* (+ iCloud at ~/Library/Mobile Documents/"
    echo "com~apple~CloudDocs); Linux/Windows use each provider's own sync dir."
    echo "In a visible location use a Title-Case folder: '<provider>/Project-with-Reflect'."
    echo "Notion / Google Docs are NOT local folders, so they can't be the root."
    echo "System default (hidden, no sync): ~/.project-with-reflect."
    echo "Then: bootstrap.sh \"<chosen-path>\"  and retry with"
    echo "PROJECT_WITH_REFLECT_ROOT=\"<chosen-path>\" prefixed (rc export affects future shells only)."
  } >&2
  exit 3
}

# pwr_validate_name <label> <value> — entity names / workstreams / handles become paths,
# symlinks in ~/.claude/skills, slash-commands, and shell-built JSON. Reject anything that
# could traverse (`..`, `/`) or corrupt those (quotes, spaces, control chars) BEFORE any
# mkdir/ln/rm touches disk. Allowed: alnum start, then letters digits . _ -
pwr_validate_name() {
  case "$2" in
    ""|*..*|*/*)      echo "invalid $1 '$2' — empty, '..' or '/' not allowed" >&2; exit 2 ;;
  esac
  case "$2" in
    [!A-Za-z0-9]*)    echo "invalid $1 '$2' — must start with a letter/digit" >&2; exit 2 ;;
  esac
  case "$2" in
    *[!A-Za-z0-9._-]*) echo "invalid $1 '$2' — allowed: letters digits . _ -" >&2; exit 2 ;;
  esac
}

pwr_ensure_root() {
  # connections/ = everything you operate (ssh | serial | http | mcp); knowledge/ = reusable practices/recipes/references, skills too.
  mkdir -p "$PWR_ROOT"/projects "$PWR_ROOT"/connections \
           "$PWR_ROOT"/knowledge "$PWR_ROOT"/memories "$PWR_ROOT"/agents \
           "$PWR_ROOT"/templates "$PWR_ROOT"/scripts
  [ -f "$PWR_ROOT/registry.json" ] || \
    echo '{"projects":{},"connections":{},"knowledge":{},"agents":{}}' > "$PWR_ROOT/registry.json"
}

# pwr_install_skill <entity_dir> <name> <template_path>
# Make an entity a real skill: SKILL.md (from template, if absent) + log.md, symlinked into
# each supported user-scope skill directory, and attach <name>.md as the Obsidian folder note.
# Shared by every connection transport (ssh/serial/http/mcp) and any other skill-entity.
pwr_link_skill_dirs() {
  local DIR="$1" NAME="$2"
  mkdir -p "$HOME/.claude/skills"
  ln -sfn "$DIR" "$HOME/.claude/skills/$NAME"

  # Codex discovers user skills from $CODEX_HOME/skills, with ~/.codex as the normal default.
  # Other agents can still use the generated SKILL.md by copying or symlinking the same DIR.
  local CODEX_DIR="${CODEX_HOME:-$HOME/.codex}/skills"
  mkdir -p "$CODEX_DIR"
  ln -sfn "$DIR" "$CODEX_DIR/$NAME"
}

pwr_install_skill() {
  local DIR="$1" NAME="$2" TPL="$3" HERE
  HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  [ -f "$DIR/SKILL.md" ] || sed "s/{{NAME}}/$NAME/g; s|{{DIR}}|$DIR|g" "$TPL" > "$DIR/SKILL.md"
  [ -f "$DIR/log.md" ]   || echo "# log" > "$DIR/log.md"
  pwr_link_skill_dirs "$DIR" "$NAME"
  bash "$HERE/obsidian-folder-note.sh" "$DIR" || true
}

# pwr_registry_put <category> <name> <json-object-string>
pwr_registry_put() {
  python3 - "$PWR_ROOT/registry.json" "$1" "$2" "$3" <<'PY'
import json, sys
path, cat, name, obj = sys.argv[1:5]
d = json.load(open(path))
d.setdefault(cat, {})[name] = json.loads(obj)
json.dump(d, open(path, "w"), indent=2)
PY
}

# pwr_log <logfile> <message>  — append a timestamped line
pwr_log() {
  printf '%s — %s\n' "$(date '+%Y-%m-%d %H:%M')" "$2" >> "$1"
}
