#!/usr/bin/env bash
# Register a hardware flash target (USB/serial, not ssh).
#   register-device.sh <name> <board> <port> [toolchain] [baud] [flash_cmd] [monitor_cmd]
#     toolchain   = arduino-cli | platformio | esptool | micropython  (default arduino-cli)
#     flash_cmd   = the REAL command that builds+flashes this board. The MODEL derives it
#                   (from the user's practice / a referenced repo / the toolchain) and passes
#                   it here. Empty -> a TODO stub that fails loudly until you fill it.
#     monitor_cmd = the REAL serial-monitor command. Empty -> a TODO stub.
# The commands are baked into runnable flash.sh / monitor.sh; a project runs them via
# `/<project> flash` / `/<project> monitor` once it has `bind --device <name>`.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/common.sh"; pwr_first_run_guard; pwr_ensure_root
NAME="${1:?device name required}"; BOARD="${2:-}"; PORT="${3:-}"
TOOLCHAIN="${4:-arduino-cli}"; BAUD="${5:-115200}"
FLASH_CMD="${6:-}"; MONITOR_CMD="${7:-}"
DDIR="$PWR_ROOT/devices/$NAME"; mkdir -p "$DDIR"

python3 - "$DDIR/device.json" "$NAME" "$BOARD" "$PORT" "$TOOLCHAIN" "$BAUD" "$FLASH_CMD" "$MONITOR_CMD" <<'PY'
import json, sys
path, name, board, port, tc, baud, flash, monitor = sys.argv[1:9]
json.dump({"name": name, "board": board, "port": port, "toolchain": tc,
           "baud": int(baud) if baud.isdigit() else baud,
           "flash_cmd": flash, "monitor_cmd": monitor}, open(path, "w"), indent=2)
PY

# Bake the real command into a runnable script (or a loud TODO stub if none was given).
write_script () {  # <file> <title> <cmd>
  local f="$1" title="$2" cmd="$3"
  if [ -n "$cmd" ]; then
    printf '#!/usr/bin/env bash\n# %s — %s (%s on %s)\nset -euo pipefail\n%s\n' \
      "$NAME" "$title" "$BOARD" "$PORT" "$cmd" > "$f"
  else
    printf '#!/usr/bin/env bash\n# %s — %s (%s on %s)\n# TODO: no %s command recorded. Fill in the %s command, or re-run register-device with it.\nset -euo pipefail\necho "no %s command for %s — edit %s" >&2; exit 1\n' \
      "$NAME" "$title" "$BOARD" "$PORT" "$title" "$TOOLCHAIN" "$title" "$NAME" "$f" > "$f"
  fi
  chmod +x "$f"
}
write_script "$DDIR/flash.sh"   "flash"   "$FLASH_CMD"
write_script "$DDIR/monitor.sh" "monitor" "$MONITOR_CMD"

pwr_registry_put devices "$NAME" "{\"board\":\"$BOARD\",\"port\":\"$PORT\",\"toolchain\":\"$TOOLCHAIN\"}"
echo "Registered device '$NAME' ($BOARD on $PORT, $TOOLCHAIN) at $DDIR."
[ -n "$FLASH_CMD" ]   && echo "  flash:   $DDIR/flash.sh"   || echo "  ! no flash_cmd — $DDIR/flash.sh is a TODO stub."
[ -n "$MONITOR_CMD" ] && echo "  monitor: $DDIR/monitor.sh" || echo "  ! no monitor_cmd — $DDIR/monitor.sh is a TODO stub."
echo "Bind it to a project: /<project> bind --device $NAME"
