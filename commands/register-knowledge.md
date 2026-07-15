---
description: "Register a global knowledge module as a real skill (/<slug> handle) — project-with-reflect"
argument-hint: "<slug>"
---
Run the **register-knowledge** action of the `project-with-reflect` skill with arguments: $ARGUMENTS

Creates `$PROJECT_WITH_REFLECT_ROOT/knowledge/<slug>/` — a reusable practice / recipe /
reference that serves many projects, registered as a **real user-scope skill**: `<slug>.md`
holds the content (Obsidian folder note), `SKILL.md` is the loader that gives `/<slug>`
autocomplete + description auto-trigger everywhere. Re-running on a legacy flat note
migrates it to the folder form, content preserved.

After the script runs, **tailor the generated `SKILL.md` `description:`** into one targeted
"Use when …" sentence for THIS knowledge (so it triggers on the right tasks without
misfiring), then distill the actual content into `<slug>.md` — a recipe the reader can apply
cold, reader-first (conclusion → steps → reference). Don't leave the scaffold placeholder.

Link it to a project with `/<project> use-knowledge <slug>` (auto-loads when relevant there);
the `/<slug>` skill is the from-anywhere handle — one module serves many projects.

For anything you **operate** (an HTTP/WS API, an MCP server, an ssh host, a serial device),
register a **connection** instead — `register-api` / `register-mcp` / `register-machine` /
`register-device`.
