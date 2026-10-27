#!/usr/bin/env bash
# check-portable-paths.sh — the synced root must not depend on the machine's $HOME.
# Registers + regenerates the same project/api/agent under two different $HOMEs (root at
# $HOME/Obsidian Vault/PWR on each) and asserts SKILL.md + registry.json are byte-identical
# and free of the expanded $HOME. Exit 0 = portable.
set -euo pipefail
S="$(cd "$(dirname "$0")/../skills/project-with-reflect/scripts" && pwd)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT

run() {  # run <home> — fresh sandbox, nothing leaks from the real $HOME
  local H="$1" R="$1/Obsidian Vault/PWR"
  mkdir -p "$H/code/demo"
  env -i PATH="$PATH" HOME="$H" SHELL=/bin/sh PROJECT_WITH_REFLECT_ROOT="$R" bash -c '
    S="$1"; H="$2"; R="$3"
    bash "$S/register-project.sh" demo "$H/code/demo"
    bash "$S/register-api.sh" demo-api https://example.com DEMO_KEY
    bash "$S/register-agent.sh" demo-agent
    echo "drift" >> "$R/projects/demo/SKILL.md"; echo "drift" >> "$R/connections/demo-api/SKILL.md"
    bash "$S/regen-skills.sh"' _ "$S" "$H" "$R" >/dev/null
}
run "$T/alice"; run "$T/bob"

for f in projects/demo/SKILL.md connections/demo-api/SKILL.md registry.json; do
  a="$T/alice/Obsidian Vault/PWR/$f"; b="$T/bob/Obsidian Vault/PWR/$f"
  cmp -s "$a" "$b" || { echo "FAIL: $f differs across \$HOME"; diff "$a" "$b" | head; exit 1; }
  ! grep -q "$T" "$a" || { echo "FAIL: $f contains an expanded \$HOME"; grep -n "$T" "$a" | head; exit 1; }
done
grep -q '~/Obsidian Vault/PWR/projects/demo' "$T/alice/Obsidian Vault/PWR/projects/demo/SKILL.md" \
  || { echo "FAIL: project SKILL.md lacks the ~/ state dir"; exit 1; }
echo "OK: SKILL.md + registry.json identical across \$HOME, rendered as ~/…"
