---
description: "Couple a sibling workstream live — auto-launch its teammate window (Claude Code + iTerm2 only, project-with-reflect)"
argument-hint: "<workstream>   (the sibling lane to assemble as a live teammate)"
---
Run the **teammate-assemble** action of the current project's `project-with-reflect` skill with arguments: $ARGUMENTS

**Resolve the project from the current directory first:** match `$PWD` against `registry.json` projects'
`repo` / `dir` (the project whose repo contains `$PWD`). If none matches, **ask which project** — don't
guess. **Resolve the commander lane** = this session's active workstream (from the last checkin); if this
session isn't checked into a workstream, ask which lane commands.

Then follow `<project_dir>/SKILL.md`'s **teammate-assemble** workflow: run
`teammate.sh <project_dir> assemble <workstream> --commander <this-lane>` — it opens an iTerm2 window
running `claude "/<project> checkin <workstream> --as-teammate-of <this-lane>"`, writes the teammate
lock, and adds the lane to this lane's `stream.json.teammates` so every later checkin revives a dead
teammate window until `/teammate-dismiss`. Commanding then goes through the normal vault channel
(`handoff <workstream> "…"` → the teammate's standby watch picks it up).

**Claude Code + iTerm2 (macOS) only** — if the script fails (no iTerm2 / not macOS), relay its fallback:
the exact `claude` command to run manually in any window; the handoff/pickup protocol works the same.
