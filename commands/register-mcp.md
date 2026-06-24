---
description: "Register an MCP server as a connection skill — project-with-reflect"
argument-hint: "<name> \"<claude mcp add command>\""
---
Run the **register-mcp** action of the `project-with-reflect` skill with arguments: $ARGUMENTS

**Wire it first:** `claude mcp add --scope user <name> -- <command…>` (or
`--transport http <name> <url>`), confirming the exact command with the user, so `mcp__<name>__*`
tools become available — THEN record it via `register-mcp.sh <name> "<the add command>"`. Creates a
connection skill under `$PROJECT_WITH_REFLECT_ROOT/connections/<name>/` holding the re-add line +
usage rules. Follow the skill's steps.
