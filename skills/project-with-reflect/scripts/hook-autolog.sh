#!/usr/bin/env bash
# project-with-reflect - non-blocking auto-log/working-memory nudges. ALWAYS exits 0; never blocks a
# tool call or a compaction. Registered as META-skill hooks (one central hook, gated on
# registry.json so it only speaks inside a registered project's repo — silent everywhere
# else, no noise in unrelated sessions). See SKILL.md frontmatter.
#   hook-autolog.sh --context=userprompt  # UserPromptSubmit -> start substantial work with checkin
#   hook-autolog.sh --context=pretool     # PreToolUse(Bash) -> re-read disk memory before action
#   hook-autolog.sh --context=postwrite   # PostToolUse(Write/Edit) -> record progress/findings
#   hook-autolog.sh --context=posttool    # PostToolUse(Bash) -> nudge to log a git commit
#   hook-autolog.sh --context=precompact  # PreCompact -> flush un-logged events first
# POSIX sh (invoked via `sh`); no `set -e` so a hiccup can never break the tool.
[ "${PROJECT_WITH_REFLECT_HOOKS_DISABLED:-}" = "1" ] && exit 0
CTX="${1#--context=}"
INPUT="$(cat)"   # consume the hook's stdin JSON once

# Fast path: a PostToolUse fires on every Bash call — only commits matter, so bail
# cheaply (no python) unless the payload mentions a commit.
case "$CTX" in
  posttool) printf '%s' "$INPUT" | grep -q 'git commit' || exit 0 ;;
esac

# Root resolution: env > saved pointer > legacy default (mirrors common.sh, inlined).
POINTER="${XDG_CONFIG_HOME:-$HOME/.config}/project-with-reflect/root"
if [ -n "${PROJECT_WITH_REFLECT_ROOT:-}" ]; then ROOT="$PROJECT_WITH_REFLECT_ROOT"
elif [ -f "$POINTER" ]; then ROOT="$(cat "$POINTER" 2>/dev/null)"
else ROOT="$HOME/.project-with-reflect"; fi

command -v python3 >/dev/null 2>&1 || exit 0
# Pass the payload as an argv, NOT via stdin: `python3 -` already reads its program
# from the heredoc on stdin, so a piped payload would be discarded.
python3 - "$CTX" "$ROOT" "$INPUT" <<'PY' 2>/dev/null || true
import sys, json, os
ctx  = sys.argv[1] if len(sys.argv) > 1 else ""
root = sys.argv[2] if len(sys.argv) > 2 else ""
raw  = sys.argv[3] if len(sys.argv) > 3 else ""
try:
    data = json.loads(raw)
except Exception:
    sys.exit(0)
cwd = (data.get("cwd") or os.getcwd() or "").rstrip("/")
try:
    reg = json.load(open(os.path.join(root, "registry.json")))
except Exception:
    sys.exit(0)

# Which registered project's repo (or state dir) contains cwd?
match = None
for name, meta in (reg.get("projects") or {}).items():
    for base in (meta.get("repo"), meta.get("dir")):
        if not base:
            continue
        base = base.rstrip("/")
        if cwd == base or cwd.startswith(base + "/"):
            match = name
            break
    if match:
        break
if not match:
    sys.exit(0)   # not in a registered project → stay silent

if ctx == "userprompt":
    prompt = data.get("prompt") or data.get("message") or data.get("text") or ""
    if any(w in prompt.lower() for w in ("work", "continue", "resume", "plan", "goal", "fix", "implement", "release", "debug")):
        print(f"[project-with-reflect] '{match}' is registered. For substantial work, start with "
              f"`/{match} checkin` so goal/plan, progress, findings, and failed attempts reboot from disk.")
elif ctx == "pretool":
    cmd = ((data.get("tool_input") or {}).get("command")) or ""
    risky = ("git rebase", "git reset", "git merge", "git push", "rm ", "mv ", "python", "npm ", "pnpm ",
             "yarn ", "pytest", "make", "cargo", "gh pr", "scripts/publish.sh")
    if any(token in cmd for token in risky):
        print(f"[project-with-reflect] Before this action in '{match}', make sure the current plan/decisions "
              f"are fresh in context. If it fails, log the attempt and change the next approach.")
elif ctx == "postwrite":
    print(f"[project-with-reflect] File changed in '{match}'. If this completed a step or surfaced a finding, "
          f"update disk memory now: `/{match} note \"<progress/error/finding>\"` or `/{match} record \"<durable result>\"`.")
elif ctx == "posttool":
    cmd = ((data.get("tool_input") or {}).get("command")) or ""
    if "git commit" in cmd:
        print(f"[project-with-reflect] Committed in '{match}'. Log one line now — "
              f"`/{match} note \"<what this commit accomplished + why>\"` — so history is captured "
              f"in-flight; reflect's end-of-session capture is only a backstop.")
elif ctx == "precompact":
    print(f"[project-with-reflect] Context is about to compact. Flush any un-logged key events from "
          f"this session to '{match}'s active stream now (commits, decisions, fixes, findings) — "
          f"detail dropped from context can't be recovered by reflect afterward.")
PY
exit 0
