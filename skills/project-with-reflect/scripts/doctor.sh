#!/usr/bin/env bash
# doctor.sh [<name>]
# Check and repair the local project-with-reflect install:
# - root pointer + root directory shape
# - registry readability
# - user-scope Claude/Codex/Kimi skill links for registered projects/connections
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/common.sh"

ONLY="${1:-}"
if [ "${2:-}" != "" ]; then
  echo "usage: doctor.sh [<project-or-connection-name>]" >&2
  exit 2
fi

pwr_first_run_guard
pwr_ensure_root

OK=0
FIXED=0
WARN=0

realpath_py() {
  python3 -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$1"
}

fix_pointer() {
  local current=""
  mkdir -p "$(dirname "$PWR_POINTER")"
  if [ -f "$PWR_POINTER" ]; then
    current="$(cat "$PWR_POINTER")"
  fi

  if [ "$current" = "$PWR_ROOT" ]; then
    echo "[ok] root pointer: $PWR_POINTER"
    OK=$((OK + 1))
    return
  fi

  printf '%s\n' "$PWR_ROOT" > "$PWR_POINTER"
  if [ -n "$current" ]; then
    echo "[fix] root pointer updated: $current -> $PWR_ROOT"
  else
    echo "[fix] root pointer written: $PWR_POINTER -> $PWR_ROOT"
  fi
  FIXED=$((FIXED + 1))
}

fix_link() {
  local dir="$1" target="$2" label="$3" expected actual
  mkdir -p "$(dirname "$target")"
  expected="$(realpath_py "$dir")"

  if [ -L "$target" ]; then
    actual="$(realpath_py "$target")"
    if [ "$actual" = "$expected" ]; then
      echo "[ok] $label link: $target"
      OK=$((OK + 1))
      return
    fi
    ln -sfn "$dir" "$target"
    echo "[fix] $label link: $target -> $dir"
    FIXED=$((FIXED + 1))
    return
  fi

  if [ ! -e "$target" ]; then
    ln -sfn "$dir" "$target"
    echo "[fix] $label link created: $target -> $dir"
    FIXED=$((FIXED + 1))
    return
  fi

  echo "[warn] $label target exists but is not a symlink: $target" >&2
  echo "       Leave it in place; move it aside if you want doctor to replace it." >&2
  WARN=$((WARN + 1))
}

fix_skill_links() {
  local kind="$1" name="$2" dir="$3"

  pwr_validate_name "$kind name" "$name"

  if [ ! -d "$dir" ]; then
    echo "[warn] $kind $name: missing directory $dir" >&2
    WARN=$((WARN + 1))
    return
  fi

  if [ ! -f "$dir/SKILL.md" ]; then
    echo "[warn] $kind $name: missing SKILL.md in $dir" >&2
    WARN=$((WARN + 1))
    return
  fi

  fix_link "$dir" "$HOME/.claude/skills/$name" "Claude $kind $name"
  fix_link "$dir" "${CODEX_HOME:-$HOME/.codex}/skills/$name" "Codex $kind $name"
  fix_link "$dir" "$AGENTS_SKILLS_DIR/$name" "Kimi $kind $name"
  fix_link "$dir" "$KIMI_SKILLS_DIR/$name" "Kimi-local $kind $name"
}

ROWS="$(mktemp)"
trap 'rm -f "$ROWS"' EXIT

python3 - "$PWR_ROOT/registry.json" "$PWR_ROOT" "$ONLY" > "$ROWS" <<'PY'
import json
import os
import sys

reg_path, root, only = sys.argv[1:4]
with open(reg_path) as f:
    reg = json.load(f)

rows = []
for name, meta in sorted(reg.get("projects", {}).items()):
    if only and name != only:
        continue
    rows.append(("project", name, meta.get("dir") or os.path.join(root, "projects", name)))

for name, meta in sorted(reg.get("connections", {}).items()):
    if only and name != only:
        continue
    rows.append(("connection", name, meta.get("dir") or os.path.join(root, "connections", name)))

for name, meta in sorted(reg.get("knowledge", {}).items()):
    if only and name != only:
        continue
    # knowledge entries store a relative path; resolve against root
    kpath = meta.get("path") or os.path.join(root, "knowledge", name)
    if not os.path.isabs(kpath):
        kpath = os.path.join(root, kpath)
    rows.append(("knowledge", name, os.path.dirname(kpath)))

for row in rows:
    print("\t".join(row))
PY

echo "project-with-reflect doctor"
echo "root: $PWR_ROOT"
echo "registry: $PWR_ROOT/registry.json"

fix_pointer

if bash "$HERE/install-codex-command-skills.sh"; then
  OK=$((OK + 1))
else
  echo "[warn] failed to install Codex command skills" >&2
  WARN=$((WARN + 1))
fi

if bash "$HERE/install-kimi-command-skills.sh"; then
  OK=$((OK + 1))
else
  echo "[warn] failed to install Kimi command skills" >&2
  WARN=$((WARN + 1))
fi

if [ ! -s "$ROWS" ]; then
  if [ -n "$ONLY" ]; then
    echo "[warn] no registered project or connection named '$ONLY'" >&2
    WARN=$((WARN + 1))
  else
    echo "[ok] registry has no registered projects/connections yet"
    OK=$((OK + 1))
  fi
else
  while IFS=$'\t' read -r KIND NAME DIR; do
    fix_skill_links "$KIND" "$NAME" "$DIR"
  done < "$ROWS"
fi

echo
echo "doctor summary: $OK ok, $FIXED fixed, $WARN warnings"
if [ "$WARN" -gt 0 ]; then
  exit 1
fi
