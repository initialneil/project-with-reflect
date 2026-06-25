---
description: "Register/refresh a project workstream (lane) — project-with-reflect"
argument-hint: "<branch> [--base <b>] [--track-only] [--path <dir>]  (natural language ok)"
---
Run the **register-branch** action of the `project-with-reflect` skill with arguments: $ARGUMENTS

**Resolve the project from the current directory first.** Match `$PWD` against `registry.json`
projects' `repo` / `dir` (the project whose repo contains `$PWD`). If none matches, **ask which
project** — don't guess. (This is the same cwd→registry match the auto-log hook uses.)

Then parse the args — **natural language is fine**, you translate it to flags:
"v081 based on v080, just track" → `v081 --base v080 --track-only`; "v090 tracking v081" →
`v090 --base v081 --track-only`. Run:

```
register-branch.sh <project_dir> <branch> [--base <b>] [--pr-into <p>] [--track-only] [--path <dir>]
```

- `--track-only` (a.k.a. "just track" / "tracking X") → records lineage only, **no git** (a version /
  integration branch you rebase onto).
- Otherwise the lane is realized per the project's `workstream_mode`: **worktree** needs a clean
  `--path` — the script refuses with `PWR_NEED_WORKTREE_PATH` if it's missing; **ask the user** for a
  directory (not a sibling-clutter path, not under `.claude/`), then re-run with `--path`. **in-repo**
  does `git checkout -b` (HEAD switches — ready to work). **logical** does no git.
- **Re-registering an existing lane** updates its `base`/`pr_into` only — cycle / log / git untouched.

Generates the `/<project>-<branch>` alias. Follow the skill's steps; honor the behavioral contract.
