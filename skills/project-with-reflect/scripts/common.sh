#!/usr/bin/env bash
# Shared helpers for project-with-reflect. Source me: `source common.sh`.
# Deterministic file/registry ops only — judgment (reflect, rules) is the model's job.
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

pwr_ensure_root() {
  mkdir -p "$PWR_ROOT"/projects "$PWR_ROOT"/machines "$PWR_ROOT"/devices \
           "$PWR_ROOT"/knowledge "$PWR_ROOT"/memories "$PWR_ROOT"/agents \
           "$PWR_ROOT"/templates "$PWR_ROOT"/scripts
  [ -f "$PWR_ROOT/registry.json" ] || \
    echo '{"projects":{},"machines":{},"devices":{},"knowledge":{},"agents":{}}' > "$PWR_ROOT/registry.json"
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
