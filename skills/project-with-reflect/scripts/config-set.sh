#!/usr/bin/env bash
# config-set.sh <project_dir|config.json> <key> <value> — set a top-level scalar key in a
# project's config.json, JSON-safe (no hand-editing that could drop other fields). Used for the
# project `emoji` a checkin shows in the terminal title, and any other simple scalar field.
# ensure_ascii=False keeps an emoji a literal glyph, not an \uXXXX escape.
set -euo pipefail
TGT="${1:?config.json path or project dir}"; KEY="${2:?key}"; VAL="${3?value}"
[ -d "$TGT" ] && TGT="$TGT/config.json"
[ -f "$TGT" ] || { echo "no config.json at $TGT" >&2; exit 1; }
python3 - "$TGT" "$KEY" "$VAL" <<'PY'
import json, sys
p, k, v = sys.argv[1:4]
d = json.load(open(p))
d[k] = v
json.dump(d, open(p, "w"), indent=2, ensure_ascii=False)
PY
echo "set $KEY=$VAL in $TGT"
