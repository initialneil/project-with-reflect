# Changelog

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
