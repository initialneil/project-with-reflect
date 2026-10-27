---
description: "Log + reflect the current project — capture this session, distill to lean lessons (project-with-reflect)"
argument-hint: "[what to reflect on]   (optional — natural language ok)"
---
Run the **reflect** action of the current project's `project-with-reflect` skill with arguments: $ARGUMENTS

**Resolve the project from the current directory first:** match `$PWD` against `registry.json` projects'
`repo` (`~` = $HOME) / state dir (`$PROJECT_WITH_REFLECT_ROOT/projects/<name>`; legacy `dir`) (the project whose repo contains `$PWD`). If none matches, **ask which project** — don't
guess. (Same cwd→registry match the auto-log hook and `/register-workstream` use.) Then follow
`<project_dir>/SKILL.md`'s **reflect** workflow.

`reflect` is already *log-and-reflect*: it **captures this session first** (appends key events not yet in
the log — to the active stream, or a connection's log if the finding is about a device/API), **then**
distills into lean `lessons` + `decisions` (run results → append-only `lessons/experiment-*.md`), refreshes
the dashboard, surfaces code-improvement flags, and
archives consumed logs. This command is just the muscle-memory name for it, callable from anywhere in the
repo without a `/<project>` prefix. Any `$ARGUMENTS` pass through: a `<target>` → directed reflect on a
code area / repo skill; `--reground` → full rewrite of one module.
