#!/usr/bin/env bash
# Generate a thin /<project>-<handle> alias command (user scope).
#   gen-command.sh <project> <handle> <kind:branch|eval|task> <project_dir>
set -euo pipefail
P="${1:?project}"; H="${2:?handle}"; KIND="${3:?kind}"; PDIR="${4:?project_dir}"
mkdir -p "$HOME/.claude/commands"

# per-kind argument-hint (shows on tab-complete, like /goal's "[<condition> | clear]")
case "$KIND" in
  branch) AH='argument-hint: "[checkin | status | pr | rebase | reset]"' ;;
  eval)   AH='argument-hint: "[run | all]"' ;;
  *)      AH='' ;;
esac

{
  echo "---"
  echo "description: \"$P — $KIND '$H' (project-with-reflect alias)\""
  [ -n "$AH" ] && echo "$AH"
  echo "---"
} > "$HOME/.claude/commands/$P-$H.md"
cat >> "$HOME/.claude/commands/$P-$H.md" <<EOF
Run the **$KIND** handle \`$H\` for project **$P** (project-with-reflect).

Project state dir: \`$PDIR\`. Follow \`$PDIR/SKILL.md\` for the \`$KIND\` workflow,
acting on handle \`$H\`. Honor the behavioral contract (load status + decisions +
relevant lessons first; check before proposing).
EOF
[ "$KIND" = branch ] && cat >> "$HOME/.claude/commands/$P-$H.md" <<EOF

Bare \`/$P-$H\` = **checkin to lane \`$H\`** (load its log + base + lessons, run the
working-dir cd-decision, then auto-run \`status\` to recap). \`status\` alone = the lane's
brief; \`pr | rebase | reset\` = the lane git ops.
EOF
echo "Generated /$P-$H"
