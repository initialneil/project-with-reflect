#!/usr/bin/env bash
# Generate a thin /<project>-<handle> alias command (user scope).
#   gen-command.sh <project> <handle> <kind:branch|eval|task> <project_dir>
set -euo pipefail
P="${1:?project}"; H="${2:?handle}"; KIND="${3:?kind}"; PDIR="${4:?project_dir}"
mkdir -p "$HOME/.claude/commands"
cat > "$HOME/.claude/commands/$P-$H.md" <<EOF
---
description: "$P — $KIND '$H' (project-with-reflect alias)"
---
Run the **$KIND** handle \`$H\` for project **$P** (project-with-reflect).

Project state dir: \`$PDIR\`. Follow \`$PDIR/SKILL.md\` for the \`$KIND\` workflow,
acting on handle \`$H\`. Honor the behavioral contract (load status + decisions +
relevant rules first; check before proposing).
EOF
echo "Generated /$P-$H"
