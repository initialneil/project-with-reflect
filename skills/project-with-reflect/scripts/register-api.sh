#!/usr/bin/env bash
# Register an HTTP/WebSocket API connection as a skill under connections/.
#   register-api.sh <name> [base_url] [key_env_var] ["setup note"]
# key_env_var is the NAME of the env var that holds the key (e.g. SONIOX_API_KEY) — a pointer,
# never the key itself. Keys live in env/keychain, NEVER on disk. The model fills the note body
# (endpoints / usage / gotchas) after this scaffolds the frontmatter + skill.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/common.sh"; pwr_first_run_guard; pwr_ensure_root
TPL="$HERE/../templates"
NAME="${1:?api name required}"; BASE="${2:-}"; KEYENV="${3:-}"; SETUP="${4:-}"
CDIR="$PWR_ROOT/connections/$NAME"; mkdir -p "$CDIR"

python3 - "$CDIR/connection.json" "$NAME" "$BASE" "$KEYENV" <<'PY'
import json, sys
path, name, base, keyenv = sys.argv[1:5]
m = {"name": name, "transport": "http"}
if base: m["base_url"] = base
if keyenv: m["key_env"] = keyenv
json.dump(m, open(path, "w"), indent=2)
PY

python3 "$HERE/_note.py" "$CDIR/$NAME.md" "$NAME" connection \
  transport=http base_url="$BASE" key_env="$KEYENV"

pwr_install_skill "$CDIR" "$NAME" "$TPL/api-SKILL.md.tmpl"
pwr_registry_put connections "$NAME" "{\"transport\":\"http\",\"key_env\":\"$KEYENV\"}"
echo "Registered http connection '$NAME' — skill at ~/.claude/skills/$NAME.${KEYENV:+ Key: \$$KEYENV in env (never on disk).}"
echo "Fill its endpoints/usage in $CDIR/$NAME.md. Use /$NAME <action>. Run /reload-plugins to load it now."
