#!/usr/bin/env bash
# Link (or unlink) a global knowledge module into a project — the knowledge analog of
# binding a machine. Edits the project's config.json `knowledge` list (one module can be
# linked to many projects).
#   link-knowledge.sh <project_dir> <knowledge_name> [--unlink]
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/common.sh"
PDIR="${1:?project_dir required}"; K="${2:?knowledge name required}"; MODE="${3:-link}"
CFG="$PDIR/config.json"
[ -f "$CFG" ] || { echo "no config.json at $PDIR (is this a registered project?)" >&2; exit 1; }

if [ "$MODE" != "--unlink" ] && [ ! -d "$PWR_ROOT/knowledge/$K" ]; then
  echo "warning: global knowledge '$K' not found in \$ROOT/knowledge — run /register-knowledge $K first." >&2
fi

python3 - "$CFG" "$K" "$MODE" <<'PY'
import json, sys
cfg, k, mode = sys.argv[1:4]
d = json.load(open(cfg)); lst = d.setdefault("knowledge", [])
if mode == "--unlink":
    d["knowledge"] = [x for x in lst if x != k]; action, prep = "Unlinked", "from"
else:
    if k not in lst: lst.append(k)
    action, prep = "Linked", "to"
json.dump(d, open(cfg, "w"), indent=2)
print(f"{action} knowledge '{k}' {prep} {d.get('name', cfg)} (config.json.knowledge = {d['knowledge']})")
PY
bash "$HERE/gen-dashboard.sh" "$PDIR"   # reflect linked/unlinked knowledge in <name>.md facts
