#!/usr/bin/env bash
# Bind a project to a registered device / machine, or set its build command.
#   bind.sh <project_dir> [--device <d>] [--machine <m>] [--build "<cmd>"]
#           [--unbind-device] [--unbind-machine]
# Writes config.json.{device,machine,build_cmd}. Register the device/machine first
# (/register-device, /register-machine) — this only records the pointer.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/common.sh"; pwr_first_run_guard; pwr_ensure_root
PDIR="${1:?project dir required}"; shift || true
CFG="$PDIR/config.json"
[ -f "$CFG" ] || { echo "no config.json at $PDIR" >&2; exit 1; }

DEVICE=""; MACHINE=""; BUILD=""; UNBIND_D=""; UNBIND_M=""
while [ $# -gt 0 ]; do
  case "$1" in
    --device)         DEVICE="${2:?--device needs a name}"; shift 2;;
    --machine)        MACHINE="${2:?--machine needs a name}"; shift 2;;
    --build)          BUILD="${2:?--build needs a command}"; shift 2;;
    --unbind-device)  UNBIND_D=1; shift;;
    --unbind-machine) UNBIND_M=1; shift;;
    *) echo "unknown arg: $1" >&2; exit 1;;
  esac
done

# Soft existence check — warn, don't block (the entity may be registered later).
[ -n "$DEVICE" ]  && [ ! -e "$PWR_ROOT/devices/$DEVICE" ]   && echo "  ! device '$DEVICE' not registered yet (/register-device $DEVICE)." >&2
[ -n "$MACHINE" ] && [ ! -e "$PWR_ROOT/machines/$MACHINE" ] && echo "  ! machine '$MACHINE' not registered yet (/register-machine $MACHINE)." >&2

python3 - "$CFG" "$DEVICE" "$MACHINE" "$BUILD" "$UNBIND_D" "$UNBIND_M" <<'PY'
import json, sys
p, device, machine, build, ud, um = sys.argv[1:7]
cfg = json.load(open(p))
if device:  cfg["device"] = device
if machine: cfg["machine"] = machine
if build:   cfg["build_cmd"] = build
if ud: cfg.pop("device", None)
if um: cfg.pop("machine", None)
json.dump(cfg, open(p, "w"), indent=2)
print("device=%s machine=%s build_cmd=%s" % (
    cfg.get("device","-"), cfg.get("machine","-"),
    "set" if cfg.get("build_cmd") else "-"))
PY
echo "Updated bindings in $CFG."
