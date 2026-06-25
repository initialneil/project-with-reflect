---
description: "Update an entity's note — fold new content into a knowledge or connection note (project-with-reflect)"
argument-hint: "<name>  — \"<what to add>\"  (a knowledge note or connection)"
---
Run the **update** action of the `project-with-reflect` skill with arguments: $ARGUMENTS

Folds the given content into that entity's note — knowledge `$PROJECT_WITH_REFLECT_ROOT/knowledge/<name>.md`;
connection `$PROJECT_WITH_REFLECT_ROOT/connections/<name>/<name>.md` — **distilled** into clean
sections (merge + dedupe, lean; don't blind-append).

- **Secrets stay in env/keychain** — an API key or "let me edit" → an env pointer, never the key.
- This edits the **note**, not the frontmatter facts. To change structured facts (ssh alias, port,
  flash cmd, base-url), re-run the matching `register-*` (idempotent, preserves the body).
- **knowledge** is the main case (the only entity that isn't a skill). A **connection** can also be
  updated via its own `/<name>` (`note` / `reflect`); **projects** use `/<project> reflect | note`.

Follow the skill's `update` steps.
