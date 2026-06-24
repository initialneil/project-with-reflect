#!/usr/bin/env bash
# Ensure a project's <name>.md is attached as its Obsidian folder note.
#   obsidian-folder-note.sh <project_dir>
#
# folder-notes attaches by CONVENTION: a file at <Folder>/<Folder>.md (per the plugin's
# storageLocation + folderNoteName) IS the folder note — nothing records the attachment.
# The only thing that severs it is a `detached: true` record in
# .obsidian/plugins/folder-notes/data.json (excludeFolders). So "re-attach" = delete that
# record, keep the file name matching the folder name, and reload the plugin to re-scan.
# The .md file is never altered here — only the plugin's exclude list.
# No-ops silently when the project isn't inside an Obsidian vault with folder-notes.
set -euo pipefail
PDIR="${1:?project_dir required}"
PDIR="$(cd "$PDIR" && pwd)"

# find the vault root (nearest ancestor containing .obsidian)
VAULT="$PDIR"
while [ "$VAULT" != "/" ] && [ ! -d "$VAULT/.obsidian" ]; do VAULT="$(dirname "$VAULT")"; done
[ -d "$VAULT/.obsidian" ] || exit 0
DJ="$VAULT/.obsidian/plugins/folder-notes/data.json"
[ -f "$DJ" ] || exit 0   # folder-notes not installed

python3 - "$DJ" "$VAULT" "$PDIR" <<'PY'
import json, os, sys
dj, vault, pdir = sys.argv[1:4]
rel = os.path.relpath(pdir, vault)
name = os.path.basename(pdir)
d = json.load(open(dj))

# 1) re-attach: drop any "detached" exclude record for THIS folder
before = d.get("excludeFolders", [])
kept = [e for e in before if not (e.get("path") == rel and e.get("detached"))]
removed = len(before) - len(kept)
if removed:
    d["excludeFolders"] = kept
    json.dump(d, open(dj, "w"), indent=2)
    print(f"folder-notes: removed {removed} detached record(s) for '{rel}' (re-attached).")

# 2) does our <name>.md match the plugin's folder-note convention?
storage = d.get("storageLocation", "insideFolder")
tmpl = d.get("folderNoteName", "{{folder_name}}")
expected = tmpl.replace("{{folder_name}}", name) + ".md"
if storage == "insideFolder" and expected == f"{name}.md":
    print(f"folder-notes: '{name}/{name}.md' matches the folder-note convention. "
          "Reload the folder-notes plugin (or restart Obsidian) so it re-scans and attaches.")
else:
    print(f"folder-notes: WARNING — your config (storageLocation={storage}, "
          f"folderNoteName={tmpl}) expects '{expected}'"
          + ("" if storage == "insideFolder" else " outside the folder")
          + f", but the dashboard is '{name}.md'. Rename it to match if you want it as the folder note.")
PY
