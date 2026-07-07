#!/bin/sh
# Codex hook adapter for project-with-reflect. It delegates to the canonical
# hook-autolog.sh script and preserves stdin JSON from Codex.
CTX="$1"
[ -n "$CTX" ] || exit 0

SH=".codex/skills/project-with-reflect/scripts/hook-autolog.sh"
if [ ! -f "$SH" ]; then
  SH="$HOME/.codex/skills/project-with-reflect/scripts/hook-autolog.sh"
fi
[ -f "$SH" ] || exit 0

if [ "$CTX" = "pretool" ]; then
  sh "$SH" "--context=$CTX" >&2 || true
  printf '{"decision":"allow"}\n'
  exit 0
fi

exec sh "$SH" "--context=$CTX"
