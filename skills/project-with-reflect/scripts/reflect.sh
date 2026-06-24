#!/usr/bin/env bash
# Deterministic part of reflect: archive a stream log AFTER the model has distilled
# it into rules/decisions. (The distillation itself is the model's job per SKILL.md.)
#   reflect.sh archive <project_dir> [stream]   (stream default: main)
set -euo pipefail
ACTION="${1:-}"; PDIR="${2:-}"; STREAM="${3:-main}"
case "$ACTION" in
  archive)
    [ -n "$PDIR" ] || { echo "usage: reflect.sh archive <project_dir> [stream]" >&2; exit 1; }
    LOG="$PDIR/workstreams/$STREAM/log.md"
    AR="$PDIR/workstreams/$STREAM/archive"; mkdir -p "$AR"
    if [ -f "$LOG" ]; then
      TS="$(date +%Y%m%d-%H%M)"
      mv "$LOG" "$AR/log-$TS.md"
      echo "# $STREAM — stream log" > "$LOG"
      echo "Archived $STREAM log -> $AR/log-$TS.md (fresh log started)."
    else
      echo "No log at $LOG; nothing to archive."
    fi
    ;;
  *) echo "usage: reflect.sh archive <project_dir> [stream]" >&2; exit 1 ;;
esac
