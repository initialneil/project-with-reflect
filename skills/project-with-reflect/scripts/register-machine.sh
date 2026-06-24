#!/usr/bin/env bash
# Register a machine (ssh target or provisioned cloud server). NO secrets on disk.
#   register-machine.sh <name> [ssh_alias] [repo_path] [endpoint] [kind]
#     kind = ssh | cloud-vm | cloud-storage  (default ssh)
# For a cloud server you don't have yet, the model runs the guided provision+pay
# flow first (gcloud/etc., confirm cost + billing), then calls this to record it.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/common.sh"; pwr_first_run_guard; pwr_ensure_root
NAME="${1:?machine name required}"
ALIAS="${2:-$1}"; REPO="${3:-}"; ENDPOINT="${4:-}"; KIND="${5:-ssh}"
mkdir -p "$PWR_ROOT/machines/$NAME"
python3 - "$PWR_ROOT/machines/$NAME/machine.json" "$NAME" "$ALIAS" "$REPO" "$ENDPOINT" "$KIND" <<'PY'
import json, sys
path, name, alias, repo, endpoint, kind = sys.argv[1:7]
m = {"name": name, "ssh_alias": alias, "kind": kind}
if repo: m["repo"] = repo
if endpoint: m["endpoint"] = endpoint
json.dump(m, open(path, "w"), indent=2)
PY
pwr_registry_put machines "$NAME" "{\"ssh_alias\":\"$ALIAS\",\"kind\":\"$KIND\"}"
echo "Registered machine '$NAME' (kind=$KIND, ssh $ALIAS). No passwords stored."
