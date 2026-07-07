#!/usr/bin/env bash
# regen-skills.sh [<project-name>] — re-render templates/project-SKILL.md.tmpl into every
# registered project's SKILL.md (or just <project-name>), **preserving each project's
# `## Lessons index` block** (the only per-project content a project SKILL carries — reflect
# owns it). Run after editing the project template so all live skills pick up the change in one
# deterministic step instead of a hand-written loop.
#
# Safe by construction: skips a project whose SKILL has no `## Lessons index` (never clobbers a
# hand-authored one), aborts a render that still has `{{...}}` placeholders, is a no-op when a
# SKILL already matches, and backs up every file it rewrites (prints the backup dir). The vault
# SKILL.md is symlinked into ~/.claude/skills and ~/.codex/skills, so one write updates both.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/common.sh"; pwr_first_run_guard; pwr_ensure_root
TPL="$HERE/../templates/project-SKILL.md.tmpl"
[ -f "$TPL" ] || { echo "no template at $TPL" >&2; exit 1; }
ONLY="${1:-}"
BK="$(mktemp -d)/pwr-skill-backups"; mkdir -p "$BK"

python3 - "$TPL" "$PWR_ROOT/projects" "$BK" "$ONLY" <<'PY'
import json, os, re, sys, glob, shutil
tpl_path, projdir, bk, only = sys.argv[1:5]
tpl = open(tpl_path).read()
LESSON_RE = re.compile(r'(?ms)^## Lessons index\n.*?(?=^## )')
ok = changed = skipped = 0
for cfgp in sorted(glob.glob(os.path.join(projdir, "*", "config.json"))):
    pdir = os.path.dirname(cfgp)
    try:
        name = json.load(open(cfgp)).get("name") or os.path.basename(pdir)
    except Exception:
        print(f"  ! {os.path.basename(pdir)}: unreadable config.json — skip"); skipped += 1; continue
    if only and name != only:
        continue
    skp = os.path.join(pdir, "SKILL.md")
    if not os.path.exists(skp):
        print(f"  ! {name}: no SKILL.md — skip"); skipped += 1; continue
    live = open(skp).read()
    m = LESSON_RE.search(live)
    if not m:
        print(f"  ! {name}: no '## Lessons index' block — skip (hand-check)"); skipped += 1; continue
    rendered = tpl.replace("{{NAME}}", name).replace("{{PDIR}}", pdir)
    rendered, n = LESSON_RE.subn(lambda _m: m.group(0), rendered, count=1)
    if n != 1:
        print(f"  ! {name}: template has no Lessons-index slot — ABORT this one"); skipped += 1; continue
    leftover = sorted(set(re.findall(r'\{\{[A-Za-z_]+\}\}', rendered)))
    if leftover:
        print(f"  ! {name}: unrendered placeholders {leftover} — skip"); skipped += 1; continue
    if rendered == live:
        print(f"  = {name}: already current"); ok += 1; continue
    shutil.copy2(skp, os.path.join(bk, name + ".SKILL.md"))
    open(skp, "w").write(rendered)
    print(f"  ✓ {name}: regenerated (lessons index preserved)"); ok += 1; changed += 1
if only and ok == 0 and skipped == 0:
    print(f"  ! no registered project named '{only}'")
print(f"\n{ok} ok ({changed} rewritten), {skipped} skipped.")
PY
echo "backups (only for rewritten files): $BK"
