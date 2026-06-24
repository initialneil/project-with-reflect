# Changelog

## v0.1.0 — 2026-06-24

- Initial release of the `project-with-reflect` meta-skill.
- Core loop: `work -> auto-log key events -> reflect (bounded update) -> lean, readable rules`.
- Actions: `register-project` (central / in-repo, generates `/<name>`), `register-machine` (ssh + guided provision-and-pay), `register-device` (flash target), `register-knowledge` (global modules), `register-agent`, `meta-reflect`, plus `help` / `list` / `status`.
- Per-project: workstreams as reusable lanes (`register-branch` / `pr` / `rebase` / `reset`), modular readable rules, `decisions.md` ledger, `status.md` human dashboard, evals + tasks/runbooks.
- In-repo `/release` skill: semver bump + changelog + tag + push.
