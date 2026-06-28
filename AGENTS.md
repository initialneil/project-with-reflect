# project-with-reflect Agent Instructions

This repository publishes the `project-with-reflect` skill for multiple coding agents.

Use the canonical skill at `skills/project-with-reflect/SKILL.md` for behavior. It registers projects and
connections as persistent, self-improving skills backed by a local
`$PROJECT_WITH_REFLECT_ROOT`, usually an Obsidian vault folder such as
`Project-with-Reflect`.

Before acting on a project or connection managed by this skill:

1. Load the relevant generated `SKILL.md`, dashboard note, `decisions.md`, and matching lessons.
2. Check prior decisions before proposing new direction.
3. Record durable findings with `record` and close sessions with `reflect`.
4. Keep secrets out of disk state; store only env-var names or ssh aliases.
5. If running in Codex or Claude Code, use the user-scope skill install in
   `~/.codex/skills/project-with-reflect` or `~/.claude/skills/project-with-reflect`.

Agent-specific entrypoints in this repo are lightweight adapters:

- `.codex/skills/project-with-reflect/` for Codex.
- `.claude/skills/project-with-reflect` and `.claude-plugin/` for Claude Code.
- `.cursor/rules/project-with-reflect.mdc` for Cursor.
- `.gemini/GEMINI.md` for Gemini CLI.
- `.opencode/AGENTS.md` for OpenCode.
- `.continue/prompts/project-with-reflect.md` for Continue.
- `.github/copilot-instructions.md` for GitHub Copilot coding agent.
