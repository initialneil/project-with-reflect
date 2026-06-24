---
description: "Register a hardware flash target (USB/serial) with project-with-reflect"
argument-hint: "<name>"
---
Run the **register-device** action of the `project-with-reflect` skill with arguments: $ARGUMENTS

Autodetect board + serial port, pick a toolchain (arduino-cli|platformio|esptool), derive the
real flash/monitor commands, then run `scripts/register-device.sh`. Creates a **connection**
(transport serial) under `connections/<name>/`, installed as a skill `/<name>` (flash | monitor |
reconnect wifi | repl). Flashed over USB/serial, not ssh; a project can also `bind` it for
project-context `build | flash | monitor`.
