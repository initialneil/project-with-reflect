#!/usr/bin/env bash
# Ensure $PROJECT_WITH_REFLECT_ROOT exists and is persisted to the shell rc.
#   bootstrap.sh [root-path]
# If no arg and the env var is unset, defaults to ~/.project-with-reflect.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="${1:-${PROJECT_WITH_REFLECT_ROOT:-$HOME/.project-with-reflect}}"
export PROJECT_WITH_REFLECT_ROOT="$ROOT"
source "$HERE/common.sh"
pwr_ensure_root

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
