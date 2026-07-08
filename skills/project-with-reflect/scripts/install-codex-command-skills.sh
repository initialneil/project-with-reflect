#!/usr/bin/env bash
# Install Claude-style global commands as Codex user skills.
#
# Codex Desktop discovers entries from $CODEX_HOME/skills, not ~/.claude/commands.
# This bridges the repo's command/*.md surfaces (log-and-reflect, record-a-lesson,
# register-*) into small Codex skills so they appear in Codex skill autocomplete.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../../.." && pwd)"
COMMAND_DIR="$REPO/commands"
CODEX_SKILLS="${CODEX_HOME:-$HOME/.codex}/skills"

[ -d "$COMMAND_DIR" ] || { echo "missing command dir: $COMMAND_DIR" >&2; exit 1; }
mkdir -p "$CODEX_SKILLS"

python3 - "$COMMAND_DIR" "$CODEX_SKILLS" <<'PY'
import os
import re
import sys
from pathlib import Path

command_dir = Path(sys.argv[1])
codex_skills = Path(sys.argv[2])

name_re = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")


def parse_command(path: Path):
    text = path.read_text()
    description = ""
    argument_hint = ""
    body = text
    if text.startswith("---\n"):
        end = text.find("\n---\n", 4)
        if end != -1:
            frontmatter = text[4:end].splitlines()
            body = text[end + len("\n---\n") :]
            for line in frontmatter:
                if line.startswith("description:"):
                    description = line.split(":", 1)[1].strip().strip('"')
                elif line.startswith("argument-hint:"):
                    argument_hint = line.split(":", 1)[1].strip().strip('"')
    if not description:
        description = f"Run /{path.stem} (project-with-reflect)"
    return description, argument_hint, body.rstrip() + "\n"


for path in sorted(command_dir.glob("*.md")):
    name = path.stem
    if not name_re.match(name) or ".." in name:
        raise SystemExit(f"invalid command name: {name}")

    description, argument_hint, body = parse_command(path)
    skill_dir = codex_skills / name
    skill_dir.mkdir(parents=True, exist_ok=True)
    skill_path = skill_dir / "SKILL.md"

    hint_line = f"argument-hint: \"{argument_hint}\"\n" if argument_hint else ""
    skill = (
        "---\n"
        f"name: {name}\n"
        f"description: \"{description} Use when the user types /{name}, ${name}, or asks for this project-with-reflect command.\"\n"
        f"{hint_line}"
        "---\n"
        f"# {name}\n\n"
        "Codex adapter for the project-with-reflect global command. Treat slash-command "
        "syntax as user intent; when invoked, follow the command body below.\n\n"
        "## Command Body\n\n"
        f"{body}"
    )

    old = skill_path.read_text() if skill_path.exists() else None
    if old != skill:
        skill_path.write_text(skill)
        print(f"[fix] Codex command skill: {skill_path}")
    else:
        print(f"[ok] Codex command skill: {skill_path}")
PY
