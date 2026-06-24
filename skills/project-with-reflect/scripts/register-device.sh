#!/usr/bin/env bash
# Register a hardware flash target (USB/serial, not ssh).
#   register-device.sh <name> <board> <port> [toolchain] [baud]
#     toolchain = arduino-cli | platformio | esptool  (default arduino-cli)
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/common.sh"; pwr_ensure_root
NAME="${1:?device name required}"; BOARD="${2:-}"; PORT="${3:-}"
TOOLCHAIN="${4:-arduino-cli}"; BAUD="${5:-115200}"
DDIR="$PWR_ROOT/devices/$NAME"; mkdir -p "$DDIR"
python3 - "$DDIR/device.json" "$NAME" "$BOARD" "$PORT" "$TOOLCHAIN" "$BAUD" <<'PY'
import json, sys
path, name, board, port, tc, baud = sys.argv[1:7]
json.dump({"name": name, "board": board, "port": port, "toolchain": tc,
           "baud": int(baud) if baud.isdigit() else baud,
           "flash_cmd": "", "monitor_cmd": ""}, open(path, "w"), indent=2)
PY
cat > "$DDIR/flash.sh" <<EOF
#!/usr/bin/env bash
# Flash $NAME ($BOARD on $PORT) — fill in your $TOOLCHAIN command.
set -euo pipefail
echo "TODO: flash $NAME with $TOOLCHAIN on $PORT"
EOF
chmod +x "$DDIR/flash.sh"
pwr_registry_put devices "$NAME" "{\"board\":\"$BOARD\",\"port\":\"$PORT\",\"toolchain\":\"$TOOLCHAIN\"}"
echo "Registered device '$NAME' ($BOARD on $PORT, $TOOLCHAIN)."
