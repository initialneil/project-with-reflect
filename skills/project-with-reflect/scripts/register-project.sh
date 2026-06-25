#!/usr/bin/env bash
# Scaffold a project as a skill (user scope). Bind connections afterwards with bind.sh.
#   register-project.sh <name> <repo_path> [mode] [workstream_mode] \
#                       [--remote <connection>] [--root <path>[:role]]...
#     mode            = central | in-repo   (default central)
#     workstream_mode = worktree | in-repo  (default in-repo)
#
# <repo_path> is the PRIMARY root. A project can span several repos — add more with
# repeatable --root <path>[:role] (e.g. an app repo + a sibling dataset repo).
# For a REMOTE project (the code lives on a host, no local checkout) pass
# --remote <connection> — an ssh connection registered with register-machine. The roots
# are then paths ON that host, mode is forced to central, and the host is auto-bound.
# Positionals and flags may be given in any order.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/common.sh"
pwr_first_run_guard
pwr_ensure_root
TPL="$HERE/../templates"

REMOTE=""; ROOTS=(); POS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --remote) REMOTE="${2:?--remote needs a connection name}"; shift 2;;
    --root)   ROOTS+=("${2:?--root needs a path}"); shift 2;;
    --*) echo "unknown flag: $1" >&2; exit 1;;
    *) POS+=("$1"); shift;;
  esac
done
NAME="${POS[0]:?project name required}"
REPO="${POS[1]:-}"
MODE="${POS[2]:-central}"
WSM="${POS[3]:-in-repo}"

LOCATION="local"
if [ -n "$REMOTE" ]; then
  LOCATION="remote"
  [ -e "$PWR_ROOT/connections/$REMOTE" ] || \
    echo "  ! host connection '$REMOTE' not registered yet (register-machine $REMOTE first)." >&2
  if [ "$MODE" = "in-repo" ]; then
    echo "  remote project → forcing central mode (no local checkout to live inside)." >&2
    MODE="central"
  fi
fi

if [ "$MODE" = "in-repo" ]; then
  [ -n "$REPO" ] || { echo "in-repo mode needs a repo path (arg 2)" >&2; exit 1; }
  PDIR="$REPO/.project-with-reflect"
  mkdir -p "$PDIR"
  ln -sfn "$PDIR" "$PWR_ROOT/projects/$NAME"
else
  PDIR="$PWR_ROOT/projects/$NAME"
  mkdir -p "$PDIR"
fi

# NB: no per-project knowledge/ dir — knowledge is GLOBAL ($ROOT/knowledge/<k>); a project
# only LINKS modules (config.json.knowledge) and surfaces them as wikilinks in the dashboard.
mkdir -p "$PDIR"/rules "$PDIR"/workstreams/main "$PDIR"/evals "$PDIR"/tasks

python3 - "$PDIR/config.json" "$NAME" "$REPO" "$MODE" "$WSM" "$LOCATION" "$REMOTE" \
         ${ROOTS[@]+"${ROOTS[@]}"} <<'PY'
import json, re, sys
args = sys.argv[1:]
path, name, repo, mode, wsm, location, remote = args[:7]
extra = args[7:]

def split_role(s, default="secondary"):
    # a trailing ":word" (no slash) is a role label; otherwise the whole string is a path
    m = re.match(r'^(.*):([a-z][a-z0-9_-]*)$', s)
    if m:
        return m.group(1), m.group(2)
    return s, default

roots = []
if repo:
    roots.append({"path": repo, "role": "primary"})
for r in extra:
    p, role = split_role(r)
    roots.append({"path": p, "role": role})

cfg = {"name": name, "location": location}
if remote:
    cfg["host_connection"] = remote
cfg.update({"repo": repo, "roots": roots, "mode": mode, "workstream_mode": wsm,
            "knowledge": [], "connections": ([remote] if remote else []),
            "template_version": "0.6.0"})
json.dump(cfg, open(path, "w"), indent=2)
PY

python3 - "$PDIR/workstreams/main/stream.json" <<'PY'
import json, sys
json.dump({"branch": None, "base": None, "pr_into": None, "kind": "logical",
           "worktree_path": None, "status": "active", "cycle": 1},
          open(sys.argv[1], "w"), indent=2)
PY

[ -f "$PDIR/workstreams/main/log.md" ] || echo "# main — stream log" > "$PDIR/workstreams/main/log.md"
# Scaffolds are a clean heading only — no meta-notes, no comment cruft (guidance lives in
# SKILL.md). bootstrap fills them with real content; nothing to leave behind.
[ -f "$PDIR/decisions.md" ] || printf '# Decisions — %s\n' "$NAME" > "$PDIR/decisions.md"
[ -f "$PDIR/SKILL.md" ]     || sed "s/{{NAME}}/$NAME/g; s|{{PDIR}}|$PDIR|g" "$TPL/project-SKILL.md.tmpl" > "$PDIR/SKILL.md"
# Dashboard <name>.md = auto facts block (+ starter narrative if new); refreshes on re-register.
bash "$HERE/gen-dashboard.sh" "$PDIR"

# Expose the project as a REAL skill: its state dir IS the skill dir (SKILL.md + data),
# so /<name> works AND Claude can reach for it by description. Retire any old command form.
rm -f "$HOME/.claude/commands/$NAME.md"
mkdir -p "$HOME/.claude/skills"
ln -sfn "$PDIR" "$HOME/.claude/skills/$NAME"

pwr_registry_put projects "$NAME" "{\"dir\":\"$PDIR\",\"repo\":\"$REPO\",\"location\":\"$LOCATION\",\"host_connection\":\"$REMOTE\",\"mode\":\"$MODE\",\"workstream_mode\":\"$WSM\"}"

# If the project lives inside an Obsidian vault with the folder-notes plugin, make sure
# <name>/<name>.md attaches as the folder note (no-ops otherwise).
bash "$HERE/obsidian-folder-note.sh" "$PDIR" || true

if [ "$LOCATION" = "remote" ]; then
  echo "Registered REMOTE project '$NAME' on host '$REMOTE' (central / $WSM) at $PDIR — installed as a skill."
  echo "Code lives on the host; operate it via /$REMOTE. ${#ROOTS[@]} extra root(s) recorded."
else
  echo "Registered project '$NAME' ($MODE / $WSM) at $PDIR — installed as a skill (~/.claude/skills/$NAME)."
fi
echo "Use /$NAME (or just mention $NAME) to work on it. Run /reload-plugins to load it this session."
