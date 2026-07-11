---
description: "Decouple a live teammate workstream — final flush, then stop reviving its window (project-with-reflect)"
argument-hint: "<workstream>   (the teammate lane to dismiss)"
---
Run the **teammate-dismiss** action of the current project's `project-with-reflect` skill with arguments: $ARGUMENTS

**Resolve the project from the current directory first:** match `$PWD` against `registry.json` projects'
`repo` / `dir` (the project whose repo contains `$PWD`). If none matches, **ask which project** — don't
guess. The commander lane = this session's active workstream.

Then follow `<project_dir>/SKILL.md`'s **teammate-dismiss** workflow:
1. Send the last baton — `handoff <workstream> "dismissed: flush + stand down"` — so the teammate's
   standby watch fires once more and it flushes pending log/record entries, stops its watch, and reports done.
2. Run `teammate.sh <project_dir> dismiss <workstream> --commander <this-lane>` (removes it from
   `stream.json.teammates` + clears the lock — checkin stops reviving it).
3. Remind the user: the window can be closed; the lane stays a normal workstream — to drive it
   independently later, open a fresh window and `checkin <workstream>`.
