---
description: "Record a durable thing into the current project's permanent memory — a result, a rule, a reference/resource, an eval report, … (project-with-reflect)"
argument-hint: "<what to record>   (e.g. \"the GUAVA baseline …\" / \"this paper as a reference\")"
---
Run the **record** action of the current project's `project-with-reflect` skill with arguments: $ARGUMENTS

**Resolve the project from the current directory first:** match `$PWD` against `registry.json` projects'
`repo` / `dir` (the project whose repo or state dir contains `$PWD`). If none matches, **ask which
project** — don't guess. (Same cwd→registry match `/log-and-reflect` and the auto-log hook use.) Then
follow `<project_dir>/SKILL.md`'s **record** action.

`record` persists a **durable** thing to permanent memory **now** — distinct from `note` (an ephemeral
log line) and `reflect` (the end-of-session sweep). It's **flexible** (not experiment-specific): infer or
take the **kind** and land it in the right **flat `lessons/<descriptive>.md`** — most often by
**updating / editing / appending an existing lesson**, a new file only when nothing fits —
- **result / benchmark / eval report** → a record lesson (`lessons/experiment-GUAVA.md`) — accumulates,
  append-only;
- **rule / must-follow practice / settled conclusion** → a distilled lesson (`lessons/<topic>.md`,
  bounded) + `decisions.md` if it's a decision;
- **reference / resource / link** → a notes lesson (`lessons/resources.md`), or the global
  `knowledge/<k>` (`/register-knowledge` + `use-knowledge`) if broadly reusable;
- **research report / review / etc.** → its own lesson; anything else durable → the closest fit.

**If it continues an existing lesson, follow that lesson's established format** (its sections / columns /
artifact embedding) so entries stay uniform and comparable — for any kind, not just experiments. One
thing → its home; archives nothing. Use it the moment a durable result lands, or when the user says
"record `<X>`" (optionally "as a `<kind>`").
