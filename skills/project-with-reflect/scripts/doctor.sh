#!/usr/bin/env bash
# doctor.sh [<name>]
# Check and repair the local project-with-reflect install:
# - root pointer + root directory shape
# - registry readability
# - user-scope Claude/Codex/Kimi Code/Kimi Work skill links for registered projects/connections
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

# fix_daimon_sync <dir> <name> <kind> — Kimi Work holds real copies (symlinks get
# materialized at scan and silently go stale). Re-sync when the copy drifts from
# the source; warn + leave when the target is an unrelated dir (no marker, name
# mismatch) — never clobber someone else's skill.
fix_daimon_sync() {
  local dir="$1" name="$2" kind="$3" target="$DAIMON_SKILLS_DIR/$name" drift dcname

  if [ -L "$target" ]; then
    rm -f "$target"   # our old symlink layout — replace with a synced copy
  fi

  if [ -e "$target" ] && [ ! -d "$target" ]; then
    echo "[warn] Kimi Work $kind $name target is not a directory: $target" >&2
    WARN=$((WARN + 1))
    return
  fi

  if [ -d "$target" ] && [ ! -f "$target/.pwr-synced" ]; then
    dcname="$(perl -ne 'print $1 and exit if /^name:\s*(\S+)/' "$target/SKILL.md" 2>/dev/null)"
    if [ "$dcname" != "$name" ]; then
      echo "[warn] Kimi Work $kind $name target is an unrelated skill (no .pwr-synced, name '$dcname'): $target" >&2
      echo "       Leave it in place; move it aside if you want doctor to replace it." >&2
      WARN=$((WARN + 1))
      return
    fi
  fi

  drift="$(diff -qr "$dir" "$target" 2>/dev/null | grep -v -e '\.DS_Store' -e '\.pwr-synced' || true)"
  if [ ! -d "$target" ] || [ -n "$drift" ]; then
    pwr_sync_daimon_skill "$dir" "$name"
    echo "[fix] Kimi Work $kind $name synced: $target"
    FIXED=$((FIXED + 1))
  else
    echo "[ok] Kimi Work $kind $name in sync: $target"
    OK=$((OK + 1))
  fi
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
  if [ -d "$(dirname "$DAIMON_SKILLS_DIR")" ]; then
    fix_daimon_sync "$dir" "$name" "$kind"
  fi
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

# planning-with-files (pwf) is the long-task ENGINE PWR composes with (per-turn plan injection + gated Stop
# hook; see a project's *Long-task execution*). It is optional — everything else works without it — so a
# missing install is a hint, not a warning. With it absent, `plan-init.sh` returns NO_PWF and `done-check.sh`
# falls back to counting the plan-log's top checklist instead of pwf phases.
if PWF_DIR="$(pwr_pwf_scripts 2>/dev/null)"; then
  echo "[ok] planning-with-files: $PWF_DIR"
  OK=$((OK + 1))
else
  echo "[hint] planning-with-files not installed — long-task plan injection + gated Stop hook unavailable"
  echo "       (checkin/doctor/lessons/reflect unaffected; done-check falls back to the plan-log checklist)."
  echo "       Install: /plugin marketplace add OthmanAdi/planning-with-files  →  /plugin install planning-with-files"
fi

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
