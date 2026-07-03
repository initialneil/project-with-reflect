#!/usr/bin/env bash
# Generate a thin /<project>-<handle> alias command (user scope).
#   gen-command.sh <project> <handle> <kind:workstream|eval|task> <project_dir>
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/common.sh"   # for pwr_validate_name
P="${1:?project}"; H="${2:?handle}"; KIND="${3:?kind}"; PDIR="${4:?project_dir}"
pwr_validate_name "project" "$P"; pwr_validate_name "handle" "$H"   # both land in ~/.claude/commands/<P>-<H>.md
mkdir -p "$HOME/.claude/commands"

# per-kind argument-hint (shows on tab-complete, like /goal's "[<condition> | clear]")
case "$KIND" in
  workstream) AH='argument-hint: "[checkin | status | pr | rebase | reset]"' ;;
  eval)   AH='argument-hint: "[run | all]"' ;;
  *)      AH='' ;;
esac

# Description tag. For a workstream, show its actual working dir (worktree path → repo →
# the vault workstream folder, $HOME abbreviated to ~) instead of the generic alias note —
# that's the one fact you want when scanning the command menu ("which checkout is this?").
TAG="(project-with-reflect alias)"
if [ "$KIND" = workstream ]; then
  TAG="$(python3 - "$PDIR" "$H" <<'PY'
import json, os, sys
pdir, h = sys.argv[1], sys.argv[2]
def jget(p, k):
    try: return json.load(open(p)).get(k) or ""
    except Exception: return ""
wt   = jget(os.path.join(pdir, "workstreams", h, "stream.json"), "worktree_path")
repo = jget(os.path.join(pdir, "config.json"), "repo")
path = wt or repo or os.path.join(pdir, "workstreams", h)
home = os.path.expanduser("~")
if path == home or path.startswith(home + os.sep):
    path = "~" + path[len(home):]
print("(%s)" % path)
PY
)"
fi

{
  echo "---"
  echo "description: \"$P — $KIND '$H' $TAG\""
  [ -n "$AH" ] && echo "$AH"
  echo "---"
} > "$HOME/.claude/commands/$P-$H.md"
cat >> "$HOME/.claude/commands/$P-$H.md" <<EOF
Run the **$KIND** handle \`$H\` for project **$P** (project-with-reflect).

Project state dir: \`$PDIR\`. Follow \`$PDIR/SKILL.md\` for the \`$KIND\` workflow,
acting on handle \`$H\`. Honor the behavioral contract (load status + decisions +
relevant lessons first; check before proposing).
EOF
[ "$KIND" = workstream ] && cat >> "$HOME/.claude/commands/$P-$H.md" <<EOF

Bare \`/$P-$H\` = **checkin to workstream \`$H\`** (load its log + base + lessons, run the
working-dir cd-decision, then auto-run \`status\` to recap). \`status\` alone = the workstream's
brief; \`pr | rebase | reset\` = its git ops.
EOF
echo "Generated /$P-$H"
