---
description: "Register a hardware flash target (USB/serial) with project-with-reflect"
---
Run the **register-device** action of the `project-with-reflect` skill with arguments: $ARGUMENTS

Autodetect board + serial port, pick a toolchain (arduino-cli|platformio|esptool), then run
`scripts/register-device.sh`. A device is flashed over USB/serial, not ssh; binding it into a
project enables `build | flash | monitor`.
