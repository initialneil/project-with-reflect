# Changelog

## v0.7.2 — 2026-06-26

- register-branch: worktree lanes now default to <repo>/.claude/worktrees/<branch> (auto-created, forked from origin/<base>, kept out of git via local .git/info/exclude) — no more required --path / PWR_NEED_WORKTREE_PATH hard-stop; --path still overrides. pr now walks the base chain and always asks before any rebase: if origin/<base> moved since fork, ask to rebase before PR; if <base> is itself a tracked lane whose parent moved (stale), ask to rebase the integration branch onto its parent first, so you never PR onto a stale target.

## v0.7.1 — 2026-06-26

- Add checkin + status as first-class actions on the meta skill and every derived skill (project/workstream/machine/device/api/mcp): status = smart brief (Where/Recap/TODO/Workstreams) + meta discovery roll-up; checkin = pick-up + working-dir cd-decision + silent terminal tab-title (via term-title.sh, OSC to the controlling tty) + auto-status. Renamed top-level /record -> /record-a-lesson (action stays record). Clarified record/reflect: usually update/append an existing lesson (not always a new file), and reflect now triggers record for durable findings. Dropped the pwf abbreviation.

## v0.7.0 — 2026-06-26

- Renamed rules -> lessons: a flat, general per-project store of every kind (rules, conclusions, experiment/baseline records, reviews, references); accumulating records are append-only so numbers survive host pruning. New 'record' action (+ top-level /record): persist a durable thing now, flexible router by kind, proactive, follows the format of the lesson it continues. Removed project mode:in-repo — state is always central (pwf is personal memory; team-shared knowledge is native code); kept workstream_mode:in-repo. Builds on v0.6.x remote+multi-root projects, NL-first commands, and the work-on-lane cd decision

## v0.6.4 — 2026-06-25

- work on <lane> switch is a user choice: remote project asks workstream-folder (recommended) or stay; local project does nothing if already in the code dir, else asks code-dir (recommended) / workstream-folder / stay

## v0.6.3 — 2026-06-25

- work on <lane> offers to cd the session into the lane's workstream folder (asks first; on yes the Bash cwd persists so planning/scratch files land in the lane, not ~); remote code stays on the host over ssh. Local code-dir cd deferred

## v0.6.2 — 2026-06-25

- Natural-language-first commands: softened the intimidating argument-hints (register-api/mcp/branch, log-and-reflect, update) so users describe intent in plain language while Claude fills the flags; register-project is NL-first and auto-registers a remote host; README Actions notes that flags are Claude's interface, not user syntax

## v0.6.1 — 2026-06-25

- register-branch auto-degrades worktree/in-repo lanes to tracked on remote projects (no local checkout to run git in), with a host-branch hint; README quick-start uses generic placeholders

## v0.6.0 — 2026-06-25

- First-class remote projects (--remote <host>) and multi-root projects (--root <path>:role): config.json gains location/host_connection/roots[], dashboard surfaces them, project skill operates remote code via the host connection + remote-aware bootstrap

## v0.5.5 — 2026-06-25

- add top-level /log-and-reflect command — a cwd-resolved alias that runs the current project's capture-first reflect from anywhere in the repo (no /<project> prefix); note the alias in the project reflect handler; README quick-start now shows the workstream lane (register-branch) + /log-and-reflect

## v0.5.4 — 2026-06-25

- register-branch is now a deterministic script (register-branch.sh) instead of behavioral-only: track-only → lineage; per workstream_mode → git worktree add (needs --path, refuses cleanly otherwise) / git checkout -b / logical; idempotent re-register preserves cycle+log+git; new top-level /register-branch command resolves the project from cwd→registry (or asks), so natural language like 'v081 based on v080, just track' works without a /<project> prefix

## v0.5.3 — 2026-06-25

- reflect is now log-and-reflect (captures the session before folding, so plain 'reflect' replaces 'log and reflect'); richer auto-log triggers (commit / decision / long-task-done, logged as they happen); two non-blocking auto-log hooks — PostToolUse on git commit + PreCompact flush, gated to registered projects via registry.json; README/README_ZH restructured with a merged intro + Quick start

## v0.5.2 — 2026-06-24

- reflect now flags real codebase-improvement items (recurrence/churn from the log) but never edits source by default — development is a separate step (direct/workstream), and reflect changes code only on explicit ask with a clear routine; directed reflect (reflect <target>) scopes to any code area or repo skill; new 'todo' action records a flagged-but-deferred or manually-parked item as a ## TODO checklist in the project dashboard (loaded every session, preserved across gen-dashboard)

## v0.5.1 — 2026-06-24

- connections record a docs_url grounding pointer; per-skill reflect routing — log + reflect each finding at the skill it's about (project vs connection), with triage + a no-cascade nudge on /<project> reflect

## v0.5.0 — 2026-06-24

- Connections model (pre-1.0): unify machines + devices + APIs + MCPs into one connections/ folder, each a skill with a transport (ssh|serial|http|mcp) + the log->reflect->quirks loop. New register-api/register-mcp; register-machine/device create connections; register-knowledge is plain-md notes only; projects bind connections (config.json.connections); /update + a native per-connection update action; shared helpers pwr_install_skill + _note.py. Supersedes the retracted v1.0.0/v1.0.1 tags (not ready for v1). BREAKING vs 0.4.x: machines//devices/ -> connections/; register-knowledge no longer takes api/mcp kinds.

## v0.4.1 — 2026-06-24

- Vault files read as clean notes: knowledge note is now knowledge/<k>/<k>.md (attaches as an Obsidian folder note); dashboard facts (repo/mode/device/machine/build/knowledge/workstreams) are written as YAML frontmatter (Obsidian Properties) by new gen-dashboard.sh — stdlib-only YAML merge preserves tags + narrative, idempotent, migrates legacy comment blocks, wired into register-project/bind/use-knowledge; scaffolds are now minimal clean headings (no meta-instructions or comment cruft in user files — guidance lives in SKILL.md).

## v0.4.0 — 2026-06-24

- Device orchestration: register-device bakes real flash/monitor commands into runnable scripts (was a TODO stub); projects gain bind/build/flash/monitor handlers + a 'load the bound device/machine before build/flash/deploy' contract rule (binding was inert); meta-skill gains a Compound-requests sequencing guide (knowledge->device->project+bind->use-knowledge->build). New bind.sh; template_version 0.2.0.

## v0.3.1 — 2026-06-24

- Projects register as real skills: register-project symlinks the state dir into ~/.claude/skills/<name>, so its SKILL.md is the loaded skill — /<name> works AND Claude reaches for it by a targeted description. Aliases stay commands; retired the project-command template.

## v0.3.0 — 2026-06-24

- Discoverability + knowledge linking: argument-hint on every command/skill (tab-complete menus like /goal); new use-knowledge action (link a global knowledge module into a project — the knowledge analog of binding a machine, one module serves many projects).

## v0.2.1 — 2026-06-24

- Obsidian folder-notes integration: register-project re-attaches a project's <name>.md as its folder note when the root is in an Obsidian vault (clears stale detached records; never alters the .md). Mentioned only in the post-register summary for Obsidian users.

## v0.2.0 — 2026-06-24

- Add bootstrap — meta: configure/repair the root; project: seed a freshly-registered project from repo docs + the current session. Rename per-project dashboard status.md -> <name>.md (folder note). Documented in README.

## v0.1.3 — 2026-06-24

- First-run root prompt polished: detect the user's actual sync folders (Obsidian / Dropbox / Drive / OneDrive / iCloud / Nutstore), Title-Case 'Project-with-Reflect' folder for custom paths, note Notion/Docs can't be the root; cross-OS guidance

## v0.1.2 — 2026-06-24

- First-run root prompt now enforced by the scripts (exit 3 / PWR_FIRST_RUN) + pointer-based resolution; recommend a synced custom root (Obsidian/iCloud/Dropbox)

## v0.1.1 — 2026-06-24

- MCP-aware register-knowledge (note|mcp|api) — wires the server via 'claude mcp add'; README polish (grounding-rules link, splattingavatar example)

## v0.1.0 — 2026-06-24

- Initial release of the `project-with-reflect` meta-skill.
- Core loop: `work -> auto-log key events -> reflect (bounded update) -> lean, readable rules`.
- Actions: `register-project` (central / in-repo, generates `/<name>`), `register-machine` (ssh + guided provision-and-pay), `register-device` (flash target), `register-knowledge` (global modules), `register-agent`, `meta-reflect`, plus `help` / `list` / `status`.
- Per-project: workstreams as reusable lanes (`register-branch` / `pr` / `rebase` / `reset`), modular readable rules, `decisions.md` ledger, `status.md` human dashboard, evals + tasks/runbooks.
- In-repo `/release` skill: semver bump + changelog + tag + push.
