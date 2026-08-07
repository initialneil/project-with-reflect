#!/bin/sh
# Repo-local compatibility wrapper. The implementation lives in the canonical
# skill so hooks work from any registered project's cwd.
SH=".codex/skills/project-with-reflect/scripts/codex-hook-adapter.sh"
[ -f "$SH" ] || SH="$HOME/.codex/skills/project-with-reflect/scripts/codex-hook-adapter.sh"
[ -f "$SH" ] || exit 0
exec sh "$SH" "$@"
