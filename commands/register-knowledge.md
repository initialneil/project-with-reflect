---
description: "Register a global, agent-usable knowledge module (note / MCP / API) — project-with-reflect"
argument-hint: "<name> [note | mcp | api]"
---
Run the **register-knowledge** action of the `project-with-reflect` skill with arguments: $ARGUMENTS

Creates a global module under `$PROJECT_WITH_REFLECT_ROOT/knowledge/<name>/` (a folder, like
`machines/`) that any project opts into via `config.json.knowledge`.

If it's an **MCP** (e.g. `unity`): first actually wire it with
`claude mcp add --scope user <name> -- <command…>` (or `--transport http <name> <url>`),
confirming the command with the user, so `mcp__<name>__*` tools become available — THEN record it
with `scripts/register-knowledge.sh <name> mcp "<the add command>"`. For a plain note or API setup,
use kind `note` / `api`. Follow the skill's steps.
