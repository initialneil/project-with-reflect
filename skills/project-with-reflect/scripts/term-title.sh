#!/usr/bin/env bash
# term-title.sh "<title>" — silently set the terminal tab/window title.
#
# Why a script: Claude's Bash-tool shell has its stdout piped back to Claude, NOT
# connected to the terminal — so an OSC title escape written to stdout is captured as
# text, never reaching the terminal (you'd see `]0;…` in the output). Instead we write
# the escape straight to Claude's controlling tty, found by walking up the process
# tree (the tool shell itself has no tty, but its claude ancestor owns the real pty).
#
# Works on any OSC-capable terminal (iTerm2, Terminal.app, kitty, gnome-terminal, …)
# on macOS/Linux, with an AppleScript fallback for iTerm2 / Terminal.app. No-ops
# silently anywhere it can't reach a terminal. NEVER errors, NEVER prints — callers
# (checkin) invoke it for the side effect only.
set -u
title="${1:-}"
[ -z "$title" ] && exit 0
# strip control chars / quotes / backslashes so the escape + AppleScript stay well-formed
title=$(printf '%s' "$title" | tr -d '\000-\037"\\')
[ -z "$title" ] && exit 0
# inside a multiplexer the outer program owns the title — don't fight it
[ -n "${TMUX:-}" ] && exit 0
[ -n "${STY:-}" ] && exit 0

# 1) write an OSC-0 title sequence to the controlling tty of the nearest ancestor
anc="$PPID"
i=0
while [ -n "$anc" ] && [ "$anc" != 0 ] && [ "$i" -lt 8 ]; do
  t=$(ps -o tty= -p "$anc" 2>/dev/null | tr -d ' ')
  case "$t" in
    ttys*|pts/*)
      dev="/dev/$t"
      if [ -w "$dev" ] && printf '\033]0;%s\007' "$title" > "$dev" 2>/dev/null; then
        exit 0
      fi
      ;;
  esac
  anc=$(ps -o ppid= -p "$anc" 2>/dev/null | tr -d ' ')
  i=$((i + 1))
done

# 2) macOS fallback: drive the terminal app over AppleScript (no tty needed)
if command -v osascript >/dev/null 2>&1; then
  case "${TERM_PROGRAM:-}" in
    iTerm.app)
      osascript -e "tell application \"iTerm2\" to tell current session of current tab of current window to set name to \"$title\"" >/dev/null 2>&1 ;;
    Apple_Terminal)
      osascript -e "tell application \"Terminal\" to set custom title of front window to \"$title\"" >/dev/null 2>&1 ;;
  esac
fi
exit 0
