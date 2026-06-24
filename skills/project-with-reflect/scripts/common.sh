#!/usr/bin/env bash
# Shared helpers for project-with-reflect. Source me: `source common.sh`.
# Deterministic file/registry ops only — judgment (reflect, rules) is the model's job.
set -euo pipefail

PWR_ROOT="${PROJECT_WITH_REFLECT_ROOT:-$HOME/.project-with-reflect}"

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
