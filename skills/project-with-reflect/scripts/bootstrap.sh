#!/usr/bin/env bash
# Configure $PROJECT_WITH_REFLECT_ROOT: create it, save a pointer, persist the export.
#   bootstrap.sh [root-path]
# A CUSTOM path is recommended — a synced, human-readable location like an Obsidian
# vault / iCloud / Dropbox folder — so lessons + knowledge sync across machines and
# stay readable. With no arg it falls back to ~/.project-with-reflect.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="${1:-${PROJECT_WITH_REFLECT_ROOT:-$HOME/.project-with-reflect}}"
# expand a leading ~ if the path came in quoted
case "$ROOT" in "~"/*) ROOT="$HOME/${ROOT#\~/}" ;; "~") ROOT="$HOME" ;; esac
export PROJECT_WITH_REFLECT_ROOT="$ROOT"
source "$HERE/common.sh"
pwr_ensure_root

# 1. pointer (robust resolution even when the shell never sourced the rc export)
mkdir -p "$(dirname "$PWR_POINTER")"
printf '%s\n' "$ROOT" > "$PWR_POINTER"

# 2. persist the export for future interactive shells
case "${SHELL:-}" in
  *zsh)  RC="$HOME/.zshrc" ;;
  *bash) RC="$HOME/.bashrc" ;;
  *)     RC="$HOME/.profile" ;;
esac
if ! grep -qsF "PROJECT_WITH_REFLECT_ROOT=" "$RC"; then
  printf '\n# project-with-reflect\nexport PROJECT_WITH_REFLECT_ROOT="%s"\n' "$ROOT" >> "$RC"
  echo "Persisted PROJECT_WITH_REFLECT_ROOT to $RC (restart shell or 'source $RC')."
fi
echo "ROOT=$ROOT"
echo "(pointer: $PWR_POINTER)"
