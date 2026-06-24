# Changelog

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
