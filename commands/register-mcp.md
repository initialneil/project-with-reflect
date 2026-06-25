---
description: "Register an MCP server as a connection skill — project-with-reflect"
argument-hint: "<name>  (+ how to connect it — natural language ok)"
---
Run the **register-mcp** action of the `project-with-reflect` skill with arguments: $ARGUMENTS

The user just names the server and roughly how to reach it (a package/command, or an http url) — you
work out the exact `claude mcp add` line and confirm it. **Wire it first:**
`claude mcp add --scope user <name> -- <command…>` (or
`--transport http <name> <url>`), confirming the exact command with the user, so `mcp__<name>__*`
tools become available — THEN record it via `register-mcp.sh <name> "<the add command>"`. Creates a
connection skill under `$PROJECT_WITH_REFLECT_ROOT/connections/<name>/` holding the re-add line +
usage rules. Follow the skill's steps.
