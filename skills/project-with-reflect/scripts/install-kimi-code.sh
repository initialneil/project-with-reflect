#!/usr/bin/env bash
# One-time user-scope setup for Kimi Code.
#   install-kimi-code.sh
# Symlinks the Kimi adapter skill into ~/.agents/skills (and ~/.kimi-code/skills),
# then reminds you to add the auto-log hooks to ~/.kimi-code/config.toml.
# Run doctor afterward to repair links for all already-registered projects/connections.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../../.." && pwd)"
KIMI_ADAPTER="$REPO/.kimi-code/skills/project-with-reflect"
KIMI_HOOK="$REPO/.kimi-code/hooks/project-with-reflect.sh"

mkdir -p "$HOME/.agents/skills" "$HOME/.kimi-code/skills"
ln -sfn "$KIMI_ADAPTER" "$HOME/.agents/skills/project-with-reflect"
ln -sfn "$KIMI_ADAPTER" "$HOME/.kimi-code/skills/project-with-reflect"

echo "Linked Kimi adapter:"
echo "  $HOME/.agents/skills/project-with-reflect -> $KIMI_ADAPTER"
echo "  $HOME/.kimi-code/skills/project-with-reflect -> $KIMI_ADAPTER"

CONFIG="$HOME/.kimi-code/config.toml"
if grep -qF "project-with-reflect auto-log nudges" "$CONFIG" 2>/dev/null; then
  echo "Hooks already present in $CONFIG"
else
  echo ""
  echo "Add the following hooks to $CONFIG (or rerun with a tool that can edit TOML):"
  cat <<EOF

# project-with-reflect auto-log nudges (Kimi Code adapter)
# These are non-blocking: they only emit reminders; PreToolUse explicitly allows the tool.
[[hooks]]
event = "UserPromptSubmit"
command = "sh $KIMI_HOOK userprompt"
timeout = 5

[[hooks]]
event = "PreToolUse"
matcher = "Bash"
command = "sh $KIMI_HOOK pretool"
timeout = 5

[[hooks]]
event = "PostToolUse"
matcher = "Bash"
command = "sh $KIMI_HOOK posttool"
timeout = 5

[[hooks]]
event = "PostToolUse"
matcher = "Write|Edit"
command = "sh $KIMI_HOOK postwrite"
timeout = 5

[[hooks]]
event = "PreCompact"
command = "sh $KIMI_HOOK precompact"
timeout = 5
EOF
fi

echo ""
echo "Next: run 'SK/scripts/doctor.sh' to link existing projects/connections for Kimi Code."
