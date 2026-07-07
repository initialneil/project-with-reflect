#!/usr/bin/env bash
# Compatibility wrapper. The public repair command is now doctor.sh.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
exec "$HERE/doctor.sh" "$@"
