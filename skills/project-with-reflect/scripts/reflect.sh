#!/usr/bin/env bash
# Deterministic part of reflect: archive a log AFTER the model has distilled it into
# rules/quirks. (The distillation itself is the model's job per SKILL.md.)
#   reflect.sh archive <project_dir> [stream]   — project workstream log (stream default: main)
#   reflect.sh archive-entity <entity_dir>      — flat log.md (devices/machines)
set -euo pipefail
ACTION="${1:-}"; PDIR="${2:-}"; STREAM="${3:-main}"
archive_log () {  # <log_path> <archive_dir> <fresh_header>
  local LOG="$1" AR="$2" HDR="$3"; mkdir -p "$AR"
  if [ -f "$LOG" ]; then
    TS="$(date +%Y%m%d-%H%M)"; mv "$LOG" "$AR/log-$TS.md"
    printf '%s\n' "$HDR" > "$LOG"
    echo "Archived log -> $AR/log-$TS.md (fresh log started)."
  else
    echo "No log at $LOG; nothing to archive."
  fi
}
case "$ACTION" in
  archive)
    [ -n "$PDIR" ] || { echo "usage: reflect.sh archive <project_dir> [stream]" >&2; exit 1; }
    archive_log "$PDIR/workstreams/$STREAM/log.md" "$PDIR/workstreams/$STREAM/archive" "# $STREAM — stream log"
    ;;
  archive-entity)
    [ -n "$PDIR" ] || { echo "usage: reflect.sh archive-entity <entity_dir>" >&2; exit 1; }
    archive_log "$PDIR/log.md" "$PDIR/archive" "# log"
    ;;
  *) echo "usage: reflect.sh archive <project_dir> [stream] | archive-entity <entity_dir>" >&2; exit 1 ;;
esac
