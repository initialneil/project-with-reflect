#!/usr/bin/env bash
# Bind a project to registered connection(s), or set its build command.
#   bind.sh <project_dir> [--connection <name>]... [--device <n>] [--machine <n>]
#           [--build "<cmd>"] [--unbind <name>]...
# --device / --machine are friendly aliases for --connection (everything is a connection now).
# Writes config.json.connections (a list) + build_cmd. Register the connection first
# (register-device / register-machine / register-api / register-mcp).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/common.sh"; pwr_first_run_guard; pwr_ensure_root
PDIR="${1:?project dir required}"; shift || true
CFG="$PDIR/config.json"; [ -f "$CFG" ] || { echo "no config.json at $PDIR" >&2; exit 1; }

ADD=(); UNBIND=(); BUILD=""
while [ $# -gt 0 ]; do
  case "$1" in
    --connection|--device|--machine) ADD+=("${2:?needs a name}"); shift 2;;
    --unbind) UNBIND+=("${2:?needs a name}"); shift 2;;
    --build)  BUILD="${2:?needs a command}"; shift 2;;
    *) echo "unknown arg: $1" >&2; exit 1;;
  esac
done
for c in ${ADD[@]+"${ADD[@]}"}; do
  [ -e "$PWR_ROOT/connections/$c" ] || echo "  ! connection '$c' not registered yet (register-device/machine/api/mcp $c)." >&2
done

python3 - "$CFG" "$BUILD" "${ADD[*]:-}" "${UNBIND[*]:-}" <<'PY'
import json, sys
p, build, add, unbind = sys.argv[1:5]
cfg = json.load(open(p))
lst = cfg.setdefault("connections", [])
for c in add.split():
    if c and c not in lst: lst.append(c)
for c in unbind.split():
    if c in lst: lst.remove(c)
if build: cfg["build_cmd"] = build
cfg.pop("device", None); cfg.pop("machine", None)   # drop legacy scalar fields
json.dump(cfg, open(p, "w"), indent=2)
print("connections=%s build_cmd=%s" % (cfg["connections"], "set" if cfg.get("build_cmd") else "-"))
PY
bash "$HERE/gen-dashboard.sh" "$PDIR"   # reflect bindings in <name>.md facts
echo "Updated bindings in $CFG."
