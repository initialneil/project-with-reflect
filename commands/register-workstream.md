---
description: "Register/refresh a project workstream (a reusable lane of work) — project-with-reflect"
argument-hint: "<workstream> based on <base>  — e.g. \"v081 based on v080, just track\""
---
Run the **register-workstream** action of the `project-with-reflect` skill with arguments: $ARGUMENTS

**Resolve the project from the current directory first.** Match `$PWD` against `registry.json`
projects' `repo` / `dir` (the project whose repo contains `$PWD`). If none matches, **ask which
project** — don't guess. (This is the same cwd→registry match the auto-log hook uses.)

Then parse the args — **natural language is fine**, you translate it to flags:
"v081 based on v080, just track" → `v081 --base v080 --track-only`; "v090 tracking v081" →
`v090 --base v081 --track-only`. Run:

```
register-workstream.sh <project_dir> <workstream> [--base <b>] [--pr-into <p>] [--track-only] [--path <dir>]
```

- `--track-only` (a.k.a. "just track" / "tracking X") → records lineage only, **no git** (a shared
  version / integration branch you rebase onto and PR into, never commit to directly).
- Otherwise the workstream is realized per the project's `workstream_mode`: **worktree** → `git worktree
  add` at **`<repo>/.claude/worktrees/<workstream>`** by default (auto-created, forked from `origin/<base>`,
  kept out of `git status` via a local `.git/info/exclude` entry — no prompt; pass `--path <dir>` to
  override). **in-repo** → `git checkout -b` (HEAD switches — ready to work). **logical** → no git.
- **Re-registering an existing workstream** updates its `base`/`pr_into` only — cycle / log / git untouched.

Generates the `/<project>-<workstream>` alias (whose bare form = `checkin` to that workstream). Follow the
skill's steps; honor the behavioral contract.
