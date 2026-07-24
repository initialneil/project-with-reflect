#!/usr/bin/env bash
# Install Claude-style commands as Kimi Code user skills.
#
# Kimi Code discovers user skills from ~/.agents/skills (and $KIMI_CODE_HOME/skills),
# not ~/.claude/commands. This bridges the repo's commands/*.md surfaces
# (log-and-reflect, record-a-lesson, register-*) and generated project aliases in
# ~/.claude/commands into small Kimi skills so they appear via /skill:<name>.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../../.." && pwd)"
COMMAND_DIR="$REPO/commands"
CLAUDE_COMMAND_DIR="$HOME/.claude/commands"
AGENTS_SKILLS="$HOME/.agents/skills"
KIMI_SKILLS="${KIMI_CODE_HOME:-$HOME/.kimi-code}/skills"

[ -d "$COMMAND_DIR" ] || { echo "missing command dir: $COMMAND_DIR" >&2; exit 1; }
mkdir -p "$AGENTS_SKILLS"
mkdir -p "$KIMI_SKILLS"

python3 - "$COMMAND_DIR" "$CLAUDE_COMMAND_DIR" "$AGENTS_SKILLS" "$KIMI_SKILLS" "$@" <<'PY'
import json
import os
import re
import sys
from pathlib import Path

command_dir = Path(sys.argv[1])
claude_command_dir = Path(sys.argv[2])
agents_skills = Path(sys.argv[3])
kimi_skills = Path(sys.argv[4])
explicit_paths = [Path(p) for p in sys.argv[5:]]

name_re = re.compile(r"^[A-Za-z0-9][A-Za-z0-9._-]*$")
marker = "Kimi adapter for project-with-reflect"
legacy_marker = "Kimi adapter for the project-with-reflect"


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
        description = f"Run /skill:{path.stem} (project-with-reflect)"
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


def write_skill(skill_dir: Path, name: str, description: str, argument_hint: str, body: str):
    skill_dir.mkdir(parents=True, exist_ok=True)
    skill_path = skill_dir / "SKILL.md"

    args_line = ""
    if argument_hint:
        # Keep it simple: declare a single positional argument; the body uses $ARGUMENTS.
        args_line = "arguments:\n  - args\n"

    skill = (
        "---\n"
        f"name: {name}\n"
        f"description: {json.dumps(description + f' Use when the user types /skill:{name} or asks for this project-with-reflect command.', ensure_ascii=False)}\n"
        f"{args_line}"
        "---\n"
        f"# {name}\n\n"
        f"{marker} command. In Kimi Code invoke with `/skill:{name}`; the body below was written for "
        "Claude Code's `/<name>` syntax — interpret `/name` references as user intent for this same command.\n\n"
        "## Command Body\n\n"
        f"{body}"
    )

    old = skill_path.read_text() if skill_path.exists() else None
    if old != skill:
        skill_path.write_text(skill)
        print(f"[fix] Kimi command skill: {skill_path}")
    else:
        print(f"[ok] Kimi command skill: {skill_path}")


for path in sources():
    name = path.stem
    if not name_re.match(name) or ".." in name:
        raise SystemExit(f"invalid command name: {name}")

    description, argument_hint, body = parse_command(path)

    def can_write(skill_dir: Path) -> bool:
        if skill_dir.is_symlink():
            print(f"[skip] Kimi skill exists as symlink: {skill_dir}", file=sys.stderr)
            return False
        if skill_dir.is_dir():
            skill_md = skill_dir / "SKILL.md"
            existing = skill_md.read_text(errors="ignore") if skill_md.exists() else ""
            if existing and marker not in existing and legacy_marker not in existing:
                print(f"[skip] Kimi skill exists and is not a project-with-reflect adapter: {skill_dir}", file=sys.stderr)
                return False
            return True
        if skill_dir.exists():
            existing = skill_dir.read_text(errors="ignore")
            if marker not in existing and legacy_marker not in existing:
                print(f"[skip] Kimi skill exists and is not a project-with-reflect adapter: {skill_dir}", file=sys.stderr)
                return False
        return True

    # ~/.agents/skills is the primary shared user skill dir.
    if can_write(agents_skills / name):
        write_skill(agents_skills / name, name, description, argument_hint, body)

    # Also mirror into the Kimi-specific dir so isolated KIMI_CODE_HOME roots work.
    if can_write(kimi_skills / name):
        write_skill(kimi_skills / name, name, description, argument_hint, body)
PY
