---
description: "Register a project with project-with-reflect → generates /<name>"
argument-hint: "<name> [path]"
---
Run the **register-project** action of the `project-with-reflect` skill with arguments: $ARGUMENTS

**The user describes the project in plain language — you translate it into the script's flags. They
should never have to type `--remote` / `--root` / `:role` themselves.** From `$ARGUMENTS` extract: the
project **name**, its **path(s)**, whether the code is **local or remote** (cues like "on the gpubox
server", "it's on `<host>`", a `user@host:/path`), and any **extra repos** it spans ("also uses the
dataset repo at …"). Only **AskUserQuestion** for what's genuinely missing or ambiguous —
workstream_mode (worktree|in-repo|logical), whether to import existing docs. (Project state always lives
centrally — project-with-reflect is personal memory; there is no in-repo state mode.)

Then read the skill's SKILL.md and run its register-project steps:
- If the project is **remote** and its host isn't a registered connection yet, **register it first**
  (`register-machine <host>` — point the user at a key-based `Host` block in `~/.ssh/config`).
- Run `scripts/register-project.sh <name> <primary-path> [workstream_mode]`, adding
  `--remote <connection>` for a remote project and a repeatable `--root <path>[:role]` per extra root.
  **These flags are the deterministic interface you fill in from the description — not user-facing.**

Report the new `/<name>` command, and offer `/<name> bootstrap` to seed it from existing docs.
