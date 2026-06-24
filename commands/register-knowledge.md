---
description: "Register a plain-markdown knowledge note (reference) — project-with-reflect"
argument-hint: "<slug>"
---
Run the **register-knowledge** action of the `project-with-reflect` skill with arguments: $ARGUMENTS

Creates a flat plain-md note at `$PROJECT_WITH_REFLECT_ROOT/knowledge/<slug>.md` — **reference
only**, the lightweight kind that piles up over time (reflect / meta-reflect promote learnings
into these). Link it to a project with `/<project> use-knowledge <slug>` (one note serves many).

For anything you **operate** (an HTTP/WS API, an MCP server, an ssh host, a serial device),
register a **connection** instead — `register-api` / `register-mcp` / `register-machine` /
`register-device` — those become skills under `connections/`. Follow the skill's steps.
