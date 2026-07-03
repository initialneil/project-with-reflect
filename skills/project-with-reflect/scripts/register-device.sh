#!/usr/bin/env bash
# Register a SERIAL/USB connection (a flash target) as a skill under connections/.
#   register-device.sh <name> <board> <port> [toolchain] [baud] [flash_cmd] [monitor_cmd] [docs_url]
#     toolchain = arduino-cli | platformio | esptool | micropython  (default arduino-cli)
# flash_cmd / monitor_cmd: the MODEL derives them (from the user's practice / a referenced
# repo / the toolchain) and passes them; baked into runnable flash.sh / monitor.sh.
# docs_url = the board's docs/datasheet (recorded for grounding — fetch before low-level work).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/common.sh"; pwr_first_run_guard; pwr_ensure_root
TPL="$HERE/../templates"
NAME="${1:?device name required}"; pwr_validate_name "device name" "$NAME"; BOARD="${2:-}"; PORT="${3:-}"
TOOLCHAIN="${4:-arduino-cli}"; BAUD="${5:-115200}"; FLASH_CMD="${6:-}"; MONITOR_CMD="${7:-}"; DOCS="${8:-}"
CDIR="$PWR_ROOT/connections/$NAME"; mkdir -p "$CDIR"

python3 - "$CDIR/connection.json" "$NAME" "$BOARD" "$PORT" "$TOOLCHAIN" "$BAUD" "$FLASH_CMD" "$MONITOR_CMD" "$DOCS" <<'PY'
import json, sys
path, name, board, port, tc, baud, flash, monitor, docs = sys.argv[1:10]
m = {"name": name, "transport": "serial", "board": board, "port": port,
     "toolchain": tc, "baud": int(baud) if baud.isdigit() else baud,
     "flash_cmd": flash, "monitor_cmd": monitor}
if docs: m["docs_url"] = docs
json.dump(m, open(path, "w"), indent=2)
PY

python3 "$HERE/_note.py" "$CDIR/$NAME.md" "$NAME" connection \
  transport=serial board="$BOARD" port="$PORT" toolchain="$TOOLCHAIN" baud="$BAUD" \
  flash="$FLASH_CMD" monitor="$MONITOR_CMD" docs_url="$DOCS"

# Bake the real commands into runnable scripts (or a loud TODO stub if none given).
write_script () {  # <file> <title> <cmd>
  local f="$1" title="$2" cmd="$3"
  if [ -n "$cmd" ]; then
    printf '#!/usr/bin/env bash\n# %s — %s (%s on %s)\nset -euo pipefail\n%s\n' \
      "$NAME" "$title" "$BOARD" "$PORT" "$cmd" > "$f"
  else
    printf '#!/usr/bin/env bash\n# %s — %s (%s on %s)\n# TODO: no %s command recorded; fill it in or re-run register-device with it.\nset -euo pipefail\necho "no %s command for %s — edit %s" >&2; exit 1\n' \
      "$NAME" "$title" "$BOARD" "$PORT" "$title" "$title" "$NAME" "$f" > "$f"
  fi
  chmod +x "$f"
}
write_script "$CDIR/flash.sh"   "flash"   "$FLASH_CMD"
write_script "$CDIR/monitor.sh" "monitor" "$MONITOR_CMD"

pwr_install_skill "$CDIR" "$NAME" "$TPL/device-SKILL.md.tmpl"
pwr_registry_put connections "$NAME" "{\"transport\":\"serial\",\"board\":\"$BOARD\",\"port\":\"$PORT\",\"toolchain\":\"$TOOLCHAIN\"}"
echo "Registered serial connection '$NAME' ($BOARD on $PORT, $TOOLCHAIN) — installed as a Claude/Codex skill."
[ -n "$FLASH_CMD" ]   && echo "  flash:   $CDIR/flash.sh"   || echo "  ! no flash_cmd — flash.sh is a TODO stub."
[ -n "$MONITOR_CMD" ] && echo "  monitor: $CDIR/monitor.sh" || echo "  ! no monitor_cmd — monitor.sh is a TODO stub."
echo "Use /$NAME flash | monitor | reconnect wifi | repl. Restart/reload your agent if it does not see the new skill yet."
