#!/usr/bin/env bash
# regen-skills.sh [<name>] — re-render generated project + connection SKILL.md files
# (or just the matching <name>) from their templates. Project skills preserve each
# project's `## Lessons index` block (the only per-project content a project SKILL
# carries — reflect owns it). Connection skills are fully generated from their transport
# template. Run after editing templates so all live skills pick up the change in one
# deterministic step instead of a hand-written loop.
#
# Safe by construction: skips a project whose SKILL has no `## Lessons index` (never clobbers a
# hand-authored one), skips unknown connection transports, aborts a render that still has
# `{{...}}` placeholders, is a no-op when a SKILL already matches, and backs up every file it
# rewrites (prints the backup dir). The vault SKILL.md is symlinked into ~/.claude/skills,
# ~/.codex/skills, and ~/.agents/skills, so one write updates all agents.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/common.sh"; pwr_first_run_guard; pwr_ensure_root
TDIR="$HERE/../templates"
PTPL="$TDIR/project-SKILL.md.tmpl"
[ -f "$PTPL" ] || { echo "no template at $PTPL" >&2; exit 1; }
ONLY="${1:-}"
BK="$(mktemp -d)/pwr-skill-backups"; mkdir -p "$BK"

python3 - "$PTPL" "$TDIR" "$PWR_ROOT/projects" "$PWR_ROOT/connections" "$BK" "$ONLY" <<'PY'
import json, os, re, sys, glob, shutil
ptpl_path, tdir, projdir, conndir, bk, only = sys.argv[1:7]
ptpl = open(ptpl_path).read()
LESSON_RE = re.compile(r'(?ms)^## Lessons index\n.*?(?=^## )')
PLACEHOLDER_RE = re.compile(r'\{\{[A-Za-z_]+\}\}')

def render(text, mapping):
    for key, value in mapping.items():
        text = text.replace("{{" + key + "}}", value)
    return text

project_ok = project_changed = conn_ok = conn_changed = skipped = 0
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
    rendered = render(ptpl, {"NAME": name, "PDIR": pdir})
    rendered, n = LESSON_RE.subn(lambda _m: m.group(0), rendered, count=1)
    if n != 1:
        print(f"  ! {name}: template has no Lessons-index slot — ABORT this one"); skipped += 1; continue
    leftover = sorted(set(PLACEHOLDER_RE.findall(rendered)))
    if leftover:
        print(f"  ! {name}: unrendered placeholders {leftover} — skip"); skipped += 1; continue
    if rendered == live:
        print(f"  = project {name}: already current"); project_ok += 1; continue
    shutil.copy2(skp, os.path.join(bk, "project." + name + ".SKILL.md"))
    open(skp, "w").write(rendered)
    print(f"  ✓ project {name}: regenerated (lessons index preserved)"); project_ok += 1; project_changed += 1

templates = {
    "ssh": "machine-SKILL.md.tmpl",
    "serial": "device-SKILL.md.tmpl",
    "http": "api-SKILL.md.tmpl",
    "mcp": "mcp-SKILL.md.tmpl",
    "webdav": "webdav-SKILL.md.tmpl",
}
for cfgp in sorted(glob.glob(os.path.join(conndir, "*", "connection.json"))):
    cdir = os.path.dirname(cfgp)
    try:
        cfg = json.load(open(cfgp))
        name = cfg.get("name") or os.path.basename(cdir)
        transport = cfg.get("transport")
    except Exception:
        print(f"  ! connection {os.path.basename(cdir)}: unreadable connection.json — skip"); skipped += 1; continue
    if only and name != only:
        continue
    tname = templates.get(transport)
    if not tname:
        print(f"  ! connection {name}: unknown transport {transport!r} — skip"); skipped += 1; continue
    tpl_path = os.path.join(tdir, tname)
    if not os.path.exists(tpl_path):
        print(f"  ! connection {name}: no template {tname} — skip"); skipped += 1; continue
    skp = os.path.join(cdir, "SKILL.md")
    live = open(skp).read() if os.path.exists(skp) else ""
    rendered = render(open(tpl_path).read(), {"NAME": name, "DIR": cdir})
    leftover = sorted(set(PLACEHOLDER_RE.findall(rendered)))
    if leftover:
        print(f"  ! connection {name}: unrendered placeholders {leftover} — skip"); skipped += 1; continue
    if rendered == live:
        print(f"  = connection {name}: already current"); conn_ok += 1; continue
    if os.path.exists(skp):
        shutil.copy2(skp, os.path.join(bk, "connection." + name + ".SKILL.md"))
    open(skp, "w").write(rendered)
    print(f"  ✓ connection {name}: regenerated ({transport})"); conn_ok += 1; conn_changed += 1

if only and project_ok == 0 and conn_ok == 0 and skipped == 0:
    print(f"  ! no registered project or connection named '{only}'")
print(f"\nprojects: {project_ok} ok ({project_changed} rewritten)")
print(f"connections: {conn_ok} ok ({conn_changed} rewritten)")
print(f"skipped: {skipped}")
PY
echo "backups (only for rewritten files): $BK"
