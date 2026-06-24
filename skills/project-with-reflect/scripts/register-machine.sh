#!/usr/bin/env bash
# Register an SSH connection (host / cloud server) as a skill under connections/. NO secrets on disk.
#   register-machine.sh <name> [ssh_alias] [repo_path] [endpoint] [kind]
#     kind = ssh | cloud-vm | cloud-storage  (default ssh)
# For a cloud server you don't have yet, the model runs the guided provision+pay flow first
# (gcloud/etc., confirm cost + billing), then calls this to record it.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/common.sh"; pwr_first_run_guard; pwr_ensure_root
TPL="$HERE/../templates"
NAME="${1:?machine name required}"; ALIAS="${2:-$1}"; REPO="${3:-}"; ENDPOINT="${4:-}"; KIND="${5:-ssh}"
CDIR="$PWR_ROOT/connections/$NAME"; mkdir -p "$CDIR"

python3 - "$CDIR/connection.json" "$NAME" "$ALIAS" "$REPO" "$ENDPOINT" "$KIND" <<'PY'
import json, sys
path, name, alias, repo, endpoint, kind = sys.argv[1:7]
m = {"name": name, "transport": "ssh", "ssh_alias": alias, "kind": kind}
if repo: m["repo"] = repo
if endpoint: m["endpoint"] = endpoint
json.dump(m, open(path, "w"), indent=2)
PY

python3 "$HERE/_note.py" "$CDIR/$NAME.md" "$NAME" connection \
  transport=ssh ssh_alias="$ALIAS" kind="$KIND" repo="$REPO" endpoint="$ENDPOINT"

pwr_install_skill "$CDIR" "$NAME" "$TPL/machine-SKILL.md.tmpl"
pwr_registry_put connections "$NAME" "{\"transport\":\"ssh\",\"ssh_alias\":\"$ALIAS\",\"kind\":\"$KIND\"}"
echo "Registered ssh connection '$NAME' (kind=$KIND, ssh $ALIAS) — skill at ~/.claude/skills/$NAME. No passwords stored."
echo "Use /$NAME <command> (e.g. /$NAME nvidia-smi → ssh $ALIAS nvidia-smi). Run /reload-plugins to load it now."
