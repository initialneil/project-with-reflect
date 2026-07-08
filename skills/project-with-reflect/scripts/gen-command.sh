#!/usr/bin/env bash
# Generate thin alias commands/skills (user scope).
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

write_command() {
  local CMD_NAME="$1" DESC="$2" BODY="$3" AH_LINE="${4:-}"
  {
    echo "---"
    echo "description: \"$DESC\""
    [ -n "$AH_LINE" ] && echo "$AH_LINE"
    echo "---"
    printf '%s\n' "$BODY"
  } > "$HOME/.claude/commands/$CMD_NAME.md"
}

command_points_here() {
  local PATH_TO_CHECK="$1"
  [ -f "$PATH_TO_CHECK" ] || return 1
  grep -Fq "Project state dir: \`$PDIR\`" "$PATH_TO_CHECK" || return 1
}

{
  cat <<EOF
Run the **$KIND** handle \`$H\` for project **$P** (project-with-reflect).

Project state dir: \`$PDIR\`. Follow \`$PDIR/SKILL.md\` for the \`$KIND\` workflow,
acting on handle \`$H\`. Honor the behavioral contract (load status + decisions +
relevant lessons first; check before proposing).
EOF
  [ "$KIND" = workstream ] && cat <<EOF

Bare \`/$P-$H\` = **checkin to workstream \`$H\`** (load its log + base + lessons, run the
working-dir cd-decision, then auto-run \`status\` to recap). \`status\` alone = the workstream's
brief; \`pr | rebase | reset\` = its git ops.
EOF
} > "$HOME/.claude/commands/$P-$H.body"
BODY="$(cat "$HOME/.claude/commands/$P-$H.body")"
rm -f "$HOME/.claude/commands/$P-$H.body"
write_command "$P-$H" "$P — $KIND '$H' $TAG" "$BODY" "$AH"

if [ "$KIND" = eval ]; then
  EDIR="$PDIR/evals/$H"
  ENAME="eval-$H"
  pwr_validate_name "eval alias" "$ENAME"
  mkdir -p "$EDIR"

  cat > "$EDIR/SKILL.md" <<EOF
---
name: $ENAME
description: "Quick eval handle for project $P eval '$H'. Use when the user types /$ENAME or asks to run, inspect, or reference eval '$H'."
---
# $ENAME

Eval shortcut for project **$P**, eval **$H**.

Project state dir: \`$PDIR\`
Eval folder: \`$EDIR\`
Eval spec: \`$EDIR/$H.md\`

When invoked, load \`$PDIR/SKILL.md\`, \`$PDIR/$P.md\`, \`$PDIR/decisions.md\`, and the eval spec above.
Then follow the project's \`register-eval\` / \`eval all\` workflow for this eval handle. Surface the
latest relevant lessons and recorded eval results before proposing changes.
EOF

  cat > "$HOME/.claude/commands/$ENAME.body" <<EOF
Run or reference eval **$H** for project **$P** (project-with-reflect).

Project state dir: \`$PDIR\`
Eval folder: \`$EDIR\`
Eval spec: \`$EDIR/$H.md\`

Load \`$PDIR/SKILL.md\` and the eval spec first, then follow the project eval workflow for handle \`$H\`.
EOF

  ALIAS_OK=1
  SHORT_CMD="$HOME/.claude/commands/$ENAME.md"
  if [ -e "$SHORT_CMD" ] && ! command_points_here "$SHORT_CMD"; then
    echo "  ! /$ENAME already exists for another project — kept /$P-$H only" >&2
    ALIAS_OK=0
  fi
  for SKROOT in "$HOME/.claude/skills" "${CODEX_HOME:-$HOME/.codex}/skills"; do
    mkdir -p "$SKROOT"
    LINK="$SKROOT/$ENAME"
    if [ -L "$LINK" ]; then
      ACTUAL="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$LINK")"
      EXPECT="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$EDIR")"
      if [ "$ACTUAL" != "$EXPECT" ]; then
        echo "  ! skill $LINK points elsewhere — kept existing alias" >&2
        ALIAS_OK=0
      fi
    elif [ -e "$LINK" ]; then
      echo "  ! skill $LINK exists and is not a symlink — kept existing alias" >&2
      ALIAS_OK=0
    fi
  done

  if [ "$ALIAS_OK" = 1 ]; then
    SHORT_BODY="$(cat "$HOME/.claude/commands/$ENAME.body")"
    write_command "$ENAME" "$P — eval '$H' quick handle" "$SHORT_BODY" "$AH"
    echo "Generated /$ENAME"

    for SKROOT in "$HOME/.claude/skills" "${CODEX_HOME:-$HOME/.codex}/skills"; do
      LINK="$SKROOT/$ENAME"
      if [ -L "$LINK" ] || [ -e "$LINK" ]; then
        :
      else
        ln -s "$EDIR" "$LINK"
      fi
    done
  fi
  rm -f "$HOME/.claude/commands/$ENAME.body"

fi

echo "Generated /$P-$H"
