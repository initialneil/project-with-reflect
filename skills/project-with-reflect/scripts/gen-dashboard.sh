#!/usr/bin/env bash
# (Re)generate the FACTS of a project's <name>.md dashboard as YAML frontmatter (Obsidian
# renders it as the Properties panel) from config.json + the registered device/machine
# records. The note BODY (narrative) is the model's (bootstrap/reflect) and is preserved;
# only the managed frontmatter keys are rewritten. Non-managed keys (tags, aliases, …) are
# kept. Creates the file with a starter body if absent. stdlib-only (no pyyaml) so it runs
# on any python3. Call after anything that changes bindings: register-project, bind,
# use-knowledge, reflect.
#   gen-dashboard.sh <project_dir>
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/common.sh"; pwr_first_run_guard; pwr_ensure_root
PDIR="${1:?project dir required}"
CFG="$PDIR/config.json"; [ -f "$CFG" ] || { echo "no config.json at $PDIR" >&2; exit 1; }

python3 - "$CFG" "$PDIR" "$PWR_ROOT" <<'PY'
import json, os, re, sys
cfg_path, pdir, root = sys.argv[1:4]
cfg = json.load(open(cfg_path))
name = cfg["name"]
dash = os.path.join(pdir, name + ".md")

def load(p):
    try: return json.load(open(p))
    except Exception: return {}

def q(s):  # safe double-quoted YAML scalar (valid YAML, handles spaces/punct/unicode)
    return json.dumps(str(s), ensure_ascii=False)

# --- build the managed (PWR-owned) frontmatter keys ------------------------------------
MANAGED = {"repo", "mode", "workstream_mode", "device", "machine", "build",
           "knowledge", "workstreams"}
m = [f"repo: {q(cfg.get('repo') or '—')}",
     f"mode: {cfg.get('mode','?')}",
     f"workstream_mode: {cfg.get('workstream_mode','?')}"]
dev = cfg.get("device")
if dev:
    dj = load(os.path.join(root, "devices", dev, "device.json"))
    desc = (f"{dev} — {dj.get('board','?')} @ {dj.get('port','?')} ({dj.get('toolchain','?')})"
            if dj else f"{dev} (not registered yet)")
    m.append(f"device: {q(desc)}")
if cfg.get("machine"):   m.append(f"machine: {q(cfg['machine'])}")
if cfg.get("build_cmd"): m.append(f"build: {q(cfg['build_cmd'])}")
know = cfg.get("knowledge", [])
if know:
    m.append("knowledge:"); m += [f"  - {k}" for k in know]
wsdir = os.path.join(pdir, "workstreams")
streams = sorted(d for d in os.listdir(wsdir)
                 if os.path.isdir(os.path.join(wsdir, d))) if os.path.isdir(wsdir) else []
m.append("workstreams:"); m += [f"  - {s}" for s in (streams or [])]

# --- read existing file; drop any legacy <!-- PWR:FACTS --> block from the body ---------
txt = open(dash).read() if os.path.exists(dash) else None
if txt is not None:
    txt = re.sub(r'\n?<!-- PWR:FACTS.*?<!-- /PWR:FACTS -->\n?', '', txt, flags=re.S)

def split_fm(t):
    if not t or not t.startswith("---\n"): return None, (t or "")
    rest = t[4:]; i = rest.find("\n---\n")
    if i == -1: return None, t
    return rest[:i+1], rest[i+5:]

fm, body = split_fm(txt)

# keep non-managed frontmatter lines (key + its indented children), drop managed ones
kept, skip = [], False
for line in (fm.splitlines() if fm else []):
    k = re.match(r'^([A-Za-z0-9_\-]+):', line)
    if k: skip = k.group(1) in MANAGED
    if not skip and line.strip(): kept.append(line)

if not any(re.match(r'^tags:', l) for l in kept):   # seed tags once; preserved thereafter
    kept = ["tags:", f"  - {name}"] + kept

if not body.strip():   # brand-new dashboard: starter body, no boilerplate callout
    body = (f"# {name}\n\n## System\n"
            f"_Run `/{name} bootstrap` to seed rules + decisions and write this narrative "
            f"from the repo docs + session._\n")

out = "---\n" + "\n".join(kept + m) + "\n---\n\n" + body.lstrip("\n")
open(dash, "w").write(out)
print("dashboard facts refreshed -> " + dash)
PY
