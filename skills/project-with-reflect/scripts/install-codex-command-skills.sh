#!/usr/bin/env bash
# Install Claude-style commands as Codex user skills.
#
# Codex Desktop discovers entries from $CODEX_HOME/skills, not ~/.claude/commands.
# This bridges the repo's commands/*.md surfaces (log-and-reflect, record-a-lesson,
# register-*) and generated project aliases in ~/.claude/commands into small Codex
# skills so they appear in Codex skill autocomplete.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../../.." && pwd)"
COMMAND_DIR="$REPO/commands"
CLAUDE_COMMAND_DIR="$HOME/.claude/commands"
CODEX_SKILLS="${CODEX_HOME:-$HOME/.codex}/skills"

[ -d "$COMMAND_DIR" ] || { echo "missing command dir: $COMMAND_DIR" >&2; exit 1; }
mkdir -p "$CODEX_SKILLS"

python3 - "$COMMAND_DIR" "$CLAUDE_COMMAND_DIR" "$CODEX_SKILLS" "$@" <<'PY'
import json
import os
import re
import sys
from pathlib import Path

command_dir = Path(sys.argv[1])
claude_command_dir = Path(sys.argv[2])
codex_skills = Path(sys.argv[3])
explicit_paths = [Path(p) for p in sys.argv[4:]]

name_re = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")
marker = "Codex adapter for project-with-reflect"
legacy_marker = "Codex adapter for the project-with-reflect"


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
                    description = parse_scalar(line.split(":", 1)[1])
                elif line.startswith("argument-hint:"):
                    argument_hint = parse_scalar(line.split(":", 1)[1])
    if not description:
        description = f"Run /{path.stem} (project-with-reflect)"
    return description, argument_hint, body.rstrip() + "\n"


def parse_scalar(value: str) -> str:
    value = value.strip()
    if value.startswith('"') and value.endswith('"'):
        try:
            return json.loads(value)
        except json.JSONDecodeError:
            return value[1:-1]
    return value


def is_pwr_generated_command(path: Path) -> bool:
    try:
        text = path.read_text()
    except OSError:
        return False
    return "Project state dir:" in text and "project-with-reflect" in text


def sources():
    if explicit_paths:
        for path in explicit_paths:
            if path.is_file():
                yield path
            else:
                print(f"[warn] missing command file: {path}", file=sys.stderr)
        return

    yield from sorted(command_dir.glob("*.md"))
    if claude_command_dir.is_dir():
        for path in sorted(claude_command_dir.glob("*.md")):
            if is_pwr_generated_command(path):
                yield path


for path in sources():
    name = path.stem
    if not name_re.match(name) or ".." in name:
        raise SystemExit(f"invalid command name: {name}")

    description, argument_hint, body = parse_command(path)
    skill_dir = codex_skills / name
    skill_path = skill_dir / "SKILL.md"
    if skill_dir.is_symlink():
        print(f"[skip] Codex skill exists as symlink: {skill_dir}", file=sys.stderr)
        continue
    existing = skill_path.read_text(errors="ignore") if skill_path.exists() else ""
    if skill_path.exists() and marker not in existing and legacy_marker not in existing:
        print(f"[skip] Codex skill exists and is not a project-with-reflect adapter: {skill_dir}", file=sys.stderr)
        continue

    skill_dir.mkdir(parents=True, exist_ok=True)

    hint_line = f"argument-hint: {json.dumps(argument_hint, ensure_ascii=False)}\n" if argument_hint else ""
    skill = (
        "---\n"
        f"name: {name}\n"
        f"description: {json.dumps(description + f' Use when the user types /{name}, ${name}, or asks for this project-with-reflect command.', ensure_ascii=False)}\n"
        f"{hint_line}"
        "---\n"
        f"# {name}\n\n"
        f"{marker} command. Treat slash-command "
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
