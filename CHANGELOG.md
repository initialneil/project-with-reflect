# Changelog

## v0.9.18 — 2026-07-15

- teammate revival inherits the teammate's model: assemble without an explicit --model reads the previous lock's model (+ --effort) so a revived window keeps running what it ran before

## v0.9.17 — 2026-07-15

- register-knowledge refuses a slug that collides with an existing skill (user-scope or installed-plugin) via new pwr_check_skill_collision; renamed knowledge obsidian-markdown -> obsidian-md-gotchas (collided with the obsidian plugin's skill)

## v0.9.16 — 2026-07-15

- knowledge IS a personal skill: register-knowledge now creates knowledge/<slug>/ (<slug>.md content + SKILL.md loader) symlinked into ~/.claude/skills + ~/.codex/skills, so /<slug> autocompletes + auto-triggers everywhere; legacy flat notes migrate on re-run; use-knowledge linking unchanged (composes)

## v0.9.15 — 2026-07-12

- teammate e2e-verified from Desktop commander; pid-based lock liveness (sid fallback); --model/--effort passthrough + --teammate-mode in-process; sanctioned exit = kill -TERM $PPID (pattern pkill forbidden); README: commander can be CLI/Desktop/Codex

## v0.9.14 — 2026-07-12

- teammate context hygiene — recycle instead of degrade: near-full/post-compact → flush → full checkin --as-teammate-of → re-arm watch; unrecoverable → clean exit + auto-revive; commander can force via recycle baton

## v0.9.13 — 2026-07-11

- checkin is a BLOCKING gate — must complete (printed status recap) before any task starts, even same-message tasks; skipped-checkin failure mode documented

## v0.9.12 — 2026-07-11

- top-level /teammate-assemble + /teammate-dismiss commands (CLI autocomplete; cwd-resolved, log-and-reflect pattern)

## v0.9.11 — 2026-07-11

- teammate mode for cooperating workstreams (teammate-assemble/dismiss + standby watch, Claude Code + iTerm2) · README EN|ZH switcher + handoff/pickup + teammate docs

## v0.9.10 — 2026-07-09

- Add live experiment-record dashboard and timestamped update guidance

## v0.9.9 — 2026-07-08

- Add Codex command-skill autocomplete support for global project-with-reflect commands

## v0.9.8 — 2026-07-08

- Include WebDAV connections in checkin title sync regeneration

## v0.9.7 — 2026-07-08

- Make checkin re-sync Terminal, Codex, and Claude titles every time

## v0.9.6 — 2026-07-08

- Add quick /eval-* handles for registered evals

## v0.9.5 — 2026-07-07

- Harden Codex/Claude Desktop title-setting: if the native title tool needs a thread/session id and it is not already in context, first resolve the active local thread/session via the app listing/current-thread tool instead of silently skipping.

## v0.9.4 — 2026-07-07

- checkin also renames the Claude Code desktop/web session/sidebar title when a native session-title tool is available — mirrors the existing Codex Desktop thread-title behavior (Terminal/iTerm2 OSC unchanged)

## v0.9.3 — 2026-07-07

- Add Codex Desktop thread title checkin behavior

## v0.9.2 — 2026-07-07

- Keep planning-with-files mention to acknowledgements

## v0.9.1 — 2026-07-07

- Make planning discipline native with PWR hooks

## v0.9.0 — 2026-07-07

- Absorb planning-with-files working-memory discipline into checkin

## v0.8.14 — 2026-07-07

- Add /project-with-reflect doctor repair command

## v0.8.13 — 2026-07-07

- Add scripts/regen-skills.sh: re-render project-SKILL.md.tmpl into every registered project's SKILL.md (or one by name), preserving each project's ## Lessons index — one deterministic command to propagate a template change instead of a hand-written loop. No-op when current; skips a SKILL with no index; guards unrendered placeholders; backs up rewrites.

## v0.8.12 — 2026-07-06

- Add 'pickup', the receive side of handoff: grab the 📥 batons addressed to your lane + new shared decisions/results and act, mid-session, without a full checkin (checkin's Sibling-lanes surface is an auto-pickup). handoff sends, pickup receives — encodes the train (work→checkin) / paper (pickup→discuss→handoff) rhythm.

## v0.8.11 — 2026-07-06

- Cross-workstream cooperation: two lanes of one project (e.g. train + paper) coordinate through the shared vault — results via record→experiment-records, pivots via decisions.md, and a directed baton via new 'handoff <lane>' (writes a 📥-tagged plan/note into the sibling's goal/plan log). status gains a 'Sibling lanes' surface so each checkin picks up the sibling's handoffs + shared changes.

## v0.8.10 — 2026-07-03

- Security hardening: pwr_validate_name rejects path-traversal/unsafe entity names in every register script + gen-command (closes the rm -rf footgun); publish.sh refuses to release while untracked files exist (git add -A can no longer sweep a stray secret into a public commit).

## v0.8.9 — 2026-07-03

- Writing doctrine: every note is reader-first; experiment records open with a debuggable+reproducible ## Setup; component visuals show raw AND end-to-end (+ swap-parity metric).

## v0.8.8 — 2026-07-01

- Fix checkin skipping its steps after /compact: checkin now always runs the full ritual (load → cwd → freshness → title → status) every invocation; 'already inside' skips only the redundant cd, never the title/load/freshness/recap — so a post-compact re-checkin actually re-grounds.

## v0.8.7 — 2026-07-01

- checkin <workstream> now cd's straight to its code dir (worktree/repo) instead of asking — the destination is unambiguous when you name a workstream; bare/home checkin still offers the landing choice.

## v0.8.6 — 2026-06-30

- Checkin auto-applies a clean fast-forward (lane behind base, no local commits, clean tree) without asking — it's lossless; only a diverged lane (history-rewriting rebase) or dirty tree prompts. Applied to checkin, rebase/sync, and the pr lineage check.

## v0.8.5 — 2026-06-29

- Track plans like goals: the workstream folder note is now a goal/plan log — a settled plan (plan-mode/ExitPlanMode, task_plan.md, or prose) is recorded verbatim in a dated, newest-first ```plan``` block alongside ```goal``` entries.

## v0.8.4 — 2026-06-29

- Project emoji: config.json gains an 'emoji' a checkin prefixes to the terminal title (glanceable tabs); bootstrap/checkin improvise + persist one via new config-set.sh helper.

## v0.8.3 — 2026-06-29

- Workstream /<name>-<b> hints now show the working-dir path (worktree → repo); fix new workstreams getting a wrong alias label and missing checkin body. README: knowledge-base screenshots (VS Code + Obsidian).

## v0.8.2 — 2026-06-29

- Separate install docs and add elegant skills installer path

## v0.8.1 — 2026-06-29

- Update Chinese README for multi-agent support

## v0.8.0 — 2026-06-28

- Add Codex and multi-agent publishing surfaces

## v0.7.10 — 2026-06-26

- Two fixes. (1) One worktree per workstream — never improvise: a worktree-mode workstream has exactly one worktree, reused across all PR cycles; make PR branches with git checkout -b inside it, reset recycles the same dir, rebase/sync update it. Never git worktree add ad-hoc per task/PR (that littered .claude/worktrees/ with orphans); a separate worktree = a new registered workstream or an explicit user OK; checked into a tracked/logical workstream (no worktree) -> work in the base repo, don't conjure one. (2) Evals are folder notes: an eval is evals/<e>/<e>.md (case spec, named for the folder) + input files as siblings, not a generic case.md — same folder-note convention as lessons-with-artifacts.

## v0.7.9 — 2026-06-26

- Detached remote jobs are now tracked by their owner and reconciled so none leak on the box. Ownership: a job launched for a workstream is tracked in that workstream's folder note under ## Jobs (job/host/session/log/started/status); a job launched with only a machine active goes to the machine's <name>.md ## Running jobs ledger. Machine status + new /<machine> jobs action, and project status/checkin, reconcile the ledger against ground truth (ssh tmux ls — also catches untracked/leaked sessions), flag finished/dead, and offer reattach/tail/mark-done(record result)/kill+clean. Avoids forgotten GPU/compute runs.

## v0.7.8 — 2026-06-26

- Setting a goal is now auto-recorded: when the user sets a goal for the active workstream (built-in /goal, or stated in prose), the project records it verbatim to a per-workstream goal-log folder note (workstreams/<ws>/<ws>.md) as '### <date>' + a fenced goal block, newest-first (prepended; recent on top), append-only. It's behavioral, not an OS hook — the built-in /goal can't be reliably hooked (no slash-command hook event; it doesn't dependably reach UserPromptSubmit), so the active project records it like the other auto-log triggers. Distinct from log.md's granular events; reflect summarizes against the latest goal.

## v0.7.7 — 2026-06-26

- Renamed /register-branch -> /register-workstream (clean removal, no alias) and unified the casual synonym 'lane' -> 'workstream' everywhere (SKILL, template, scripts, commands, READMEs; gen-command handle kind branch -> workstream). 'workstream' is the structural noun (workstreams/ folder, workstream_mode config) so zero on-disk migration. Literal git 'branch' kept where it's real git (a worktree/in-repo workstream is realized as a git branch). Also fixed the register command doc to the current .claude/worktrees default path.

## v0.7.6 — 2026-06-26

- checkin: bare '/<project> checkin' is now project-level — it lands at the project HOME (the main repo / base checkout) and lists the lanes to resume or branch, instead of silently entering the active feature lane. The base/main repo is always an offered working-dir landing, so a session opened in ~ can get there to register-branch a new workstream. 'checkin <lane>' still enters that specific lane.

## v0.7.5 — 2026-06-26

- A lesson with embedded images/files is now a folder note — lessons/<name>/<name>.md with its artifacts as siblings in lessons/<name>/ (embedded ![[<file>]]), never images scattered flat in lessons/. A text-only lesson stays a flat lessons/<name>.md and is promoted to a folder the first time it gains an artifact. Applies to record, reflect, and bootstrap; added to the State-dir lessons description, the format block, and the Obsidian note-style section.

## v0.7.4 — 2026-06-26

- reflect/record now route durable knowledge by SCOPE, not just kind: a generalizable practice/recipe/pattern other projects would reuse (e.g. an in-repo /release skill, a CI setup, a review format) is proactively offered for promotion to global knowledge/ (/register-knowledge + use-knowledge) instead of being locked in one project's lessons. Directed reflect on a repo skill offers the same. Pick the widest scope that fits. Added to record, reflect, and 'Where a lesson lands' in the project template + meta SKILL routing.

## v0.7.3 — 2026-06-26

- register-branch: success message now ends with an explicit 'Next -> /<name>-<branch> checkin' for every lane kind (worktree/branch/tracked/logical), so the named checkin action is suggested rather than the bare alias.

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
