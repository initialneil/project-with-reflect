#!/usr/bin/env bash
# Register an HTTP/WebSocket API connection as a skill under connections/.
#   register-api.sh <name> [base_url] [key_env_var] [docs_url]
# key_env_var is the NAME of the env var that holds the key (e.g. SONIOX_API_KEY) — a pointer,
# never the key itself. Keys live in env/keychain, NEVER on disk. docs_url is the API's docs
# home (e.g. https://soniox.com/docs) — recorded for grounding (fetch it before coding against
# the API). The model fills the note body (endpoints / usage / gotchas) after this scaffolds.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/common.sh"; pwr_first_run_guard; pwr_ensure_root
TPL="$HERE/../templates"
NAME="${1:?api name required}"; pwr_validate_name "api name" "$NAME"; BASE="${2:-}"; KEYENV="${3:-}"; DOCS="${4:-}"
CDIR="$PWR_ROOT/connections/$NAME"; mkdir -p "$CDIR"

python3 - "$CDIR/connection.json" "$NAME" "$BASE" "$KEYENV" "$DOCS" <<'PY'
import json, sys
path, name, base, keyenv, docs = sys.argv[1:6]
m = {"name": name, "transport": "http"}
if base: m["base_url"] = base
if keyenv: m["key_env"] = keyenv
if docs: m["docs_url"] = docs
json.dump(m, open(path, "w"), indent=2)
PY

python3 "$HERE/_note.py" "$CDIR/$NAME.md" "$NAME" connection \
  transport=http base_url="$BASE" key_env="$KEYENV" docs_url="$DOCS"

pwr_install_skill "$CDIR" "$NAME" "$TPL/api-SKILL.md.tmpl"
pwr_registry_put connections "$NAME" "{\"transport\":\"http\",\"key_env\":\"$KEYENV\"}"
echo "Registered http connection '$NAME' — installed as a Claude/Codex skill.${KEYENV:+ Key: \$$KEYENV in env (never on disk).}"
[ -n "$DOCS" ] && echo "  docs: $DOCS (recorded for grounding — fetch before coding against the API)."
echo "Fill its endpoints/usage in $CDIR/$NAME.md. Use /$NAME <action>. Restart/reload your agent if it does not see the new skill yet."
