---
name: release
description: >-
  Ship a new version of THIS repo's project-with-reflect plugin in one step:
  publish (bump + changelog + commit + tag + push + GitHub release via
  scripts/publish.sh) then refresh the local install. Use when the user types
  /release in the project-with-reflect repo, or asks to release / publish / cut a
  new version. Maintainer-only — this project skill is NOT shipped to plugin consumers.
argument-hint: "[patch | minor | major | X.Y.Z] [\"note\"]"
---

# /release — ship a new project-with-reflect version

One command for the whole pipeline: **publish → refresh the local install**, so the
loop is `edit the skill → /release`.

## Usage
```
/release [patch|minor|major | X.Y.Z] ["one-line changelog note"]
```

Version-bump map (this project's convention):
- **major** — a user-facing big / breaking change → bumps the **first** number.
- **minor** — a **major fix** → bumps the **middle** number.
- **patch** — a **minor fix** → bumps the **last** number. **(default)**
- An explicit `X.Y.Z` is also accepted.

The **note** becomes the CHANGELOG entry. If omitted, summarize what changed in the
plugin since the last tag in one line — don't invent a generic message.

## Steps
1. **Locate the repo.** Work from the repo root (the dir with
   `.claude-plugin/plugin.json` and `scripts/publish.sh`). If the CWD isn't it, `cd`
   to `~/Playground/vibe_coding/project-with-reflect`.
2. **Preflight (report, don't nag).** `git status` to show what's being released;
   confirm you're on `main`. Echo one line: `releasing vCUR → vNEXT — <note>`.
   The user typing `/release` IS the go-ahead — don't prompt again.
3. **Publish.** Run `scripts/publish.sh <bump-or-version> "<note>"`. It bumps the
   version in both manifests, prepends the CHANGELOG, commits, tags `v<version>`,
   pushes, and (if `gh` is present) cuts a GitHub release.
4. **Refresh this machine's install.** If installed via the marketplace, run
   `claude plugin marketplace update project-with-reflect`. If installed via the
   user-scope symlink (`~/.claude/skills/project-with-reflect` → this repo), it's
   already live — nothing to do.
5. **Report.** Print the new version + tag, and remind that other users update with
   `/plugin update project-with-reflect`.

## Guardrails
- `/release` **pushes a public tag.** Run it only when the user invoked `/release` —
  never speculatively, never as a side effect of another task.
- If `scripts/publish.sh` fails (push rejected, tag exists, bad version), **STOP and
  report the exact failure.** Don't force-push or re-tag without asking.
- A release is for **plugin/skill changes only** — README / tooling / CI edits are a
  plain `git commit` + `git push`, not `/release`.
- Don't edit skill *content* here — `/release` ships what's already committed.
