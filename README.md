# project-with-reflect

> A **self-distilling** meta-skill for Codex, Claude Code, and other AI coding agents. — Neil Z. Shao
>
> Best used with [Obsidian](https://obsidian.md) + plugins:
>
> - [Neat File Tree](https://github.com/initialneil/obsidian-neat-file-tree) — a cleaner, calmer file tree.
> - [Folder Notes](https://github.com/lostpaul/obsidian-folder-notes) — the `<folder>/<folder>.md` folder-note convention this skill optionally leans on (experiment records, evals, the per-workstream goal log).


Juggling **several projects at once**? Need to **remember** how to connect to **a handful of machines** and
**services**? Tired of **rewriting the same long prompts** and **re-explaining** the same project to your agent?

It manages each **project** for you — worktrees, logs, reflect, a growing **long-term knowledge
base** — and everything you **operate** (a *connection*), each becoming a callable `/<name>` skill:

- **Servers** — ssh in to deploy / tail logs / run commands.
- **Training boxes** — GPU machines: run training / `nvidia-smi`, with their quirks remembered (e.g. `nvidia-smi -pl 300` after a reboot).
- **Devices** — USB/serial flash targets (dev boards…): flash / monitor / REPL.
- **APIs** — HTTP/WebSocket services (only the key's env-var *name* on disk, never the key).
- **MCP servers** — used directly via their `mcp__<name>__*` tools.

All of it **Obsidian-friendly** (lessons / knowledge / dashboard are clean, readable Markdown).

<p align="center"><em>Your personal knowledge base — readable in your editor and your notes app:</em></p>

<table>
  <tr>
    <td width="50%" align="center"><img src="assets/show-in-vscode.jpg" alt="Knowledge base in VS Code"></td>
    <td width="50%" align="center"><img src="assets/show-in-obsidian.jpg" alt="Knowledge base in Obsidian"></td>
  </tr>
  <tr>
    <td align="center"><sub>Show your knowledge base in VS Code</sub></td>
    <td align="center"><sub>Show your knowledge base in Obsidian</sub></td>
  </tr>
</table>

## At a glance

- **Everything is a skill** — a project, and each connection above, gets its own `/<name>` once registered.
- **Auto-logs as you work** — commits, decisions, key findings, an experiment's result, an error + its fix, jotted to the active stream.
- **`reflect` distills itself** — captures the session, then folds the log into **lean, readable lessons** it loads next time (and appends run results to a permanent **experiment record**).
- **Loads before acting** — the agent reads existing lessons / decisions / knowledge first, so it stops re-explaining and repeating mistakes.
- **Runs across agents** — Claude Code has the plugin flow; Codex and other agents use the skill surfaces in this repo.

> **Core loop:** `work (auto-log) → /<project> reflect (capture + distill) → lean readable lessons → better next session`

## Install

**Elegant published install:**

Claude Code has the nicest first-class marketplace flow:

```
/plugin marketplace add initialneil/project-with-reflect
/plugin install project-with-reflect@project-with-reflect
```

For Codex and other agents that support the Agent Skills installer, use the open skills CLI:

```
npx skills add initialneil/project-with-reflect
```

**Codex local/dev install:**

Use this when working from a checkout, or if your agent does not yet wire the skills CLI into Codex's
user skill directory:

```
mkdir -p ~/.codex/skills
ln -sfn /path/to/project-with-reflect/.codex/skills/project-with-reflect ~/.codex/skills/project-with-reflect
```

## Quick start

The daily loop is: **register → check status / check in → work → log and reflect**.

**1. Register once**

```
# register a project → generates the /myapp skill
/register-project myapp ~/code/myapp

# optional: register a reusable workstream — just say what it's based on
/register-workstream my-feature based on main   # → generates /myapp-my-feature
```

**2. Check status and check in**

```
# from anywhere, even ~
/project-with-reflect status        # lists projects/connections and flags what needs attention
/myapp checkin                      # loads context, asks about cwd, then recaps with status
/myapp checkin train-v2             # or check straight into a specific workstream
```

**3. Work, record, reflect**

```
/myapp-my-feature ...                        # (or just /myapp for the main workstream)
/record-a-lesson the v2 baseline: 0.83 F1   # persist a result/conclusion NOW (≡ /myapp record "…")
/log-and-reflect          # from anywhere in the repo — resolves the project from your cwd
# (≡ /myapp reflect — "reflect" already captures the session first)
```

`status` is a **smart brief** (Where · Recap · TODO · Workstreams · flags), not a dump. `checkin` is the
**front door to a working session** — it loads, handles the cwd, **silently sets your terminal tab title**
to the project + workstream (iTerm2 / Terminal / any OSC terminal; no-ops elsewhere), and **ends by running
`status`** so you land with a recap. (Connections have them too: `/gpubox checkin` ssh-pings the box,
applies its quirks, and briefs it.)

> **After `/compact` or `/clear`, run `/<project> checkin` again.** Both wipe the loaded lessons / recap
> from context (your cwd and tab title survive), so re-checking-in re-grounds you. Neither runs `reflect` —
> `/log-and-reflect` first if you want the session distilled into lessons before clearing.

## Command reference

> You describe what you want in **plain language** — the names and flags below are what the agent fills in
> for you, not syntax to memorize (e.g. "a workstream v081 based on v080, just track it"; "the Soniox API, key
> in `SONIOX_API_KEY`").

**Overall** (`/project-with-reflect`):

```
/project-with-reflect           # bare → help; also: status [<name>] · checkin [<name>] · list · meta-reflect
/register-project   <name>
/register-machine   <name>      # ssh server / cloud VM
/register-device    <name>      # USB / serial flash target
/register-api       <name>      # http endpoint + key-env
/register-mcp       <name>      # mcp server + its tools
/register-knowledge <name>      # cross-project reusable recipe
/register-agent     <name>
```

**From inside a repo** — top-level shortcuts that resolve the project from your cwd, no `/<name>` prefix:

```
/log-and-reflect [<target>] [--reground]   # = /<name> reflect, from anywhere in the repo
/record-a-lesson "…"                        # = /<name> record (a durable result / rule / reference)
/register-workstream <b> --base <x>         # = /<name> register-workstream
/update <name> "…"                          # fold content into a knowledge / connection note
```

**Per project** (`/<name>`):

```
/<name>                           # bare → checkin (load + cwd-decision + auto-status)
/<name> status                    # smart brief: where · recap · todo · workstreams (not a dump)
/<name> checkin [<workstream>]    # front door; bare → project home
/<name> record "…"                # persist a durable lesson NOW
/<name> note "…"                  # ephemeral log line
/<name> reflect [<target>] [--reground]
/<name> todo                      # backlog
/<name> bind --connection <c> [--build "…"]
/<name> build | flash | monitor   # via a bound device / server
/<name> register-workstream <b> --base <x>
/<name>-<b> [pr | rebase | reset] # the workstream's own command
/<name> register-eval <e>  ·  eval all
/<name> register-task <t>
/<name> use-knowledge <k>
/<name> bootstrap | streams | list | help
```

**Per connection** (`/<name>`, by transport):

```
/<name> checkin                   # verify reachable + apply quirks + auto-status
/<name> status                    # smart brief
/<name> <cmd>                      # ssh: run a command on the host
/<name> flash | monitor | reconnect wifi | repl   # serial
/<name> <call>                     # http / mcp
/<name> note "…" · update "…" · reflect           # reflect folds its log → ## Quirks
```

One ergonomic for everything: **register a handle → get `/<name>-<handle>`**
(a workstream, an eval test case, or a task runbook).

## Common workflows

**Remote / multi-repo project** — code on a server (no local checkout), maybe spanning repos? Just
**describe it in plain language** — the agent registers the host and records the roots for you; there's no
flag syntax to remember:

```
/register-project myapp — it's on the gpubox server at /srv/myapp, and also uses the dataset repo at /srv/dataset
```
The agent registers `gpubox` as an ssh connection if it isn't one yet (key-based, no passwords on disk),
records both repos as roots, and binds the host. Then `/myapp bootstrap` seeds lessons + decisions from
them over ssh. Open a session anywhere and say **`/myapp work on <workstream>`** — it asks before switching
into that workstream's folder, so your planning + working files stay in the vault (never littering the server
or your `~`), while `/myapp` builds/tests on the host through `/gpubox`.

You can also turn devices and services into skills — `/register-device`, `/register-api`,
`/register-mcp`, `/register-machine` — and `bind` them to a project to `build` / `flash` / call
directly.

**Bug-fix stream on a version branch that itself sits on an older one:**

```
/app register-workstream v090 --base v080 --track-only   # lineage only: v090 tracks v080 (shared branch / PR-target, no worktree)
/app register-workstream v090-bug-fix --base v090        # worktree at app/.claude/worktrees/v090-bug-fix, forked from origin/v090
/app-v090-bug-fix                                     # checkin: cd into the worktree + recap; develop (auto-logs)
/app-v090-bug-fix pr                                  # asks to rebase if origin/v090 moved; if v090 is stale vs v080, asks to rebase v090 first; then gh pr create --base v090
# …PR merges…
/app-v090-bug-fix reset                               # recycle the workstream onto latest v090 for the next PR
```
The version lineage is the chain of `base` pointers `v080 ← v090 ← v090-bug-fix`; `pr` walks
it and **asks before any rebase** so you never PR onto a stale target. Worktree workstreams default to
`<repo>/.claude/worktrees/<workstream>` (auto-created, kept out of git); a workstream is a **reusable
workstream**, not one-shot.

**Firmware project across a device and a cloud server:**

```
/register-device cardputer-adv   # autodetect board + /dev/cu.usb*; writes connection.json + flash/monitor
/register-machine gcs-server     # ssh connection; new? describe it — the agent guides provider setup + billing, confirms cost first
/register-project splattingavatar ~/code/splattingavatar
/splattingavatar bind --connection cardputer-adv --connection gcs-server
/splattingavatar build && /splattingavatar flash && /splattingavatar monitor   # compile with the server endpoint baked in, flash over USB, watch it connect
```
Each is also its own skill — `/cardputer-adv flash`, `/gcs-server <cmd>` — and project-context
`flash`/`monitor` delegate to it, so its learned quirks apply.

## First run: choosing the root

On first run it asks where to keep `$PROJECT_WITH_REFLECT_ROOT`. A **custom, synced,
readable path is recommended** — your Obsidian vault or a cloud file-sync folder
(Dropbox / Google Drive / OneDrive / iCloud / Nutstore), using a `Project-with-Reflect`
folder there, so your lessons and knowledge sync across machines and stay easy to read.
`~/.project-with-reflect` is the no-sync default. (Notion / Google Docs can't be the
root — the root must be a real local folder.) The choice is saved (pointer + shell rc).

## Mental model

```
$PROJECT_WITH_REFLECT_ROOT/
  projects/<name>/      per-project skill + state
  connections/<name>/   everything you operate — ssh | serial | http | mcp — each its own /<name> skill
  knowledge/            global, agent-usable reference notes any project opts into
  memories/             durable global facts (kept tight)
  agents/  templates/  scripts/  registry.json
```

Connections keep **no secrets on disk** — only the *name* of the env var holding a key
(e.g. `SONIOX_API_KEY`), never the key itself or an ssh password.

Per project:

```
projects/<name>/
  SKILL.md             self-contained dispatcher + behavioral contract
  <name>.md            human dashboard (+ ## TODO backlog) — regenerated by reflect
  lessons/<name>.md    readable lessons of every kind, flat (rules · references · reviews · research);
                       most bounded-updated, some append-only — e.g. experiment-GUAVA.md = run records
  workstreams/<workstream>/ stream.json + log.md  (the log lives per-workstream)
  decisions.md         ideas tried / chosen / rejected — checked before proposing
  evals/<eval>/  tasks/<task>.md  config.json
```

Per connection (a skill, by transport):
```
connections/<name>/
  connection.json      transport + facts (port/board · ssh alias · base_url/key_env · mcp tools · docs_url)
  <name>.md            facts (frontmatter) + learned ## Quirks
  SKILL.md   log.md    /<name> flash|monitor|call|… → reflect folds the log into quirks
```

## Supported agents

The canonical skill lives at `skills/project-with-reflect/`. Agent-specific surfaces mirror or point to
that source so one repo can be installed across common coding agents:

| Agent | Support | Entry point |
| --- | --- | --- |
| Codex | First-class skill install | `.codex/skills/project-with-reflect/` |
| Claude Code | Plugin + skill + slash commands/hooks | `.claude-plugin/`, `skills/project-with-reflect/`, `commands/` |
| Generic agent CLIs | Repository instructions | `AGENTS.md`, `llms.txt` |
| Cursor | Rule adapter | `.cursor/rules/project-with-reflect.mdc` |
| Gemini CLI | Context adapter | `.gemini/GEMINI.md` |
| OpenCode | Agent instructions | `.opencode/AGENTS.md` |
| Continue | Prompt adapter | `.continue/prompts/project-with-reflect.md` |
| GitHub Copilot coding agent | Repository instructions | `.github/copilot-instructions.md` |

Codex and Claude Code get the most complete behavior because project-with-reflect can install generated
project/connection skills into both user skill directories:

```
~/.codex/skills/<name>
~/.claude/skills/<name>
```

Other agents can still use the same generated `SKILL.md` files by loading the repository instructions or
symlinking/copying `$PROJECT_WITH_REFLECT_ROOT/projects/<name>` and
`$PROJECT_WITH_REFLECT_ROOT/connections/<name>` into their own skill/rule location.

## Bootstrap

Two `bootstrap` actions get you from zero to a working setup:

- **`/project-with-reflect bootstrap [path]`** — (re)configure the root: it asks where to
  keep `$PROJECT_WITH_REFLECT_ROOT` (recommending a synced, readable path) and sets it up.
  Use it to set up before registering, move the root, or repair a missing pointer.
- **`/<name> bootstrap`** — *seed a freshly-registered project from what already exists.*
  The agent reads the repo's docs (README, specs, CHANGELOG), skims the code, and uses the
  current session, then does an initial reflect pass: writes the `lessons/<topic>.md`
  modules, populates `decisions.md` with choices already made, and writes the `<name>.md`
  dashboard. So a project you register today starts full, not empty — distilled, not invented.

## The behavioral contract (what makes it work)

Every generated `/<name>` makes the agent, **before acting**:
1. **Load first, propose second** — read `<name>.md` + `decisions.md` + matching lesson modules.
2. **Check the ledger before proposing** — if it's in `decisions.md`, cite it; never re-propose blind.
3. **Never improvise guarded state** — datasets, settings, branch/release conventions are invariants.
4. **Surface** relevant lessons and registered evals.
5. **Know your connections** (servers / training boxes / devices / APIs / MCP) — operate a bound
   connection through its own `/<name>` skill (which applies its learned quirks); load
   `connection.json` for the hard facts, never guess a port / host / endpoint.

That contract is what turns logging into *less* repeated work, not just more files.

## Reflect = bounded update

`reflect` is **log-and-reflect**: it first **captures the session** (appends this conversation's
key events that aren't logged yet — to the active stream's log, or a connection's log if the finding
is about a device/API), **then** routes by kind: an **accumulating result** (a run's config + metric +
verdict) is **appended to a permanent record lesson** (a flat `lessons/experiment-<name>.md` — never
rewritten or archived, so numbers survive even after the host's output dirs are pruned, and matching that
lesson's established format); **everything else** folds into the right `lessons/<topic>.md` +
`decisions.md` (fixes wrong lessons, **splits a lesson if it gets too long to read**). When the sweep
turns up a durable thing you didn't already `record` in the moment — a baseline, an "X beats Y", a
reference worth keeping — reflect **triggers `record` for it naturally** (`record` is the primitive;
reflect is its end-of-session backstop). Then it regenerates
`<name>.md`, archives the consumed **log** (lessons are never archived), and reports what changed. So one
`/<project> reflect` is the whole end-of-session habit — no separate "log" step. Run it as
`/<project> reflect`, or **`/log-and-reflect`** from anywhere in the repo (it resolves the project from
your cwd). `--reground` forces a full rewrite of one distilled module. Readability is the judge.

`reflect` also **flags codebase-improvement items** it spots in the log (a recurring failure, a
churned module) — you fix them as real dev, or park them with `todo`; it never edits source on its
own. And logging stays current without you babysitting it: two non-blocking **hooks** (a nudge on
each `git commit`, a flush before context compaction) plus reflect's capture-first backstop.

## Acknowledgements

Inspired by my dear friend Zhaolong WANG from Tsinghua.

Built on ideas from:
- [hermes-agent](https://github.com/nousresearch/hermes-agent) — the closed learning loop.
- [grounding-rules](https://github.com/initialneil/grounding-rules) — lean, readable rules.
- [planning-with-files](https://github.com/othmanadi/planning-with-files) — hook-driven, on-disk working memory.

## License

MIT © initialneil
