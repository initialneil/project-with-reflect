---
description: "Register a project with project-with-reflect → generates /<name>"
argument-hint: "<name> [path]"
---
Run the **register-project** action of the `project-with-reflect` skill with arguments: $ARGUMENTS

Read the skill's SKILL.md (`project-with-reflect`) and follow its register-project steps:
AskUserQuestion for mode (central|in-repo), workstream_mode (worktree|in-repo), whether the code is
**local or remote** (remote → which registered ssh connection hosts it; the code stays on the host and
mode is forced to central), any **additional roots** (a project can span repos, e.g. app + dataset),
optional machine/device binding, and whether to import existing docs; then run
`scripts/register-project.sh <name> <primary-path> <mode> <workstream_mode>` plus `--remote <connection>`
for a remote project and a repeatable `--root <path>[:role]` per extra root. Report the new `/<name>`
command.
