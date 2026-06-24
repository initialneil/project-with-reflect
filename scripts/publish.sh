#!/usr/bin/env bash
# Publish a new version of the project-with-reflect plugin.
#
#   scripts/publish.sh <patch|minor|major|x.y.z> ["one-line changelog note"]
#
# Bump map (user's convention):
#   major = user-facing big / breaking change   (FIRST number)
#   minor = major fix                            (MIDDLE number)
#   patch = minor fix                            (LAST number)   [default]
#
# Bumps the version in .claude-plugin/{plugin,marketplace}.json, prepends a
# CHANGELOG entry, commits, tags v<x.y.z>, pushes, and (if gh is present) cuts a
# GitHub release. Consumers then run `/plugin update project-with-reflect`.
set -euo pipefail
cd "$(dirname "$0")/.."

BUMP="${1:-patch}"

CUR="$(perl -ne 'print $1 and exit if /"version":\s*"([0-9]+\.[0-9]+\.[0-9]+)"/' .claude-plugin/plugin.json)"
[[ -n "$CUR" ]] || { echo "error: could not read current version from plugin.json" >&2; exit 1; }

case "$BUMP" in
  major|minor|patch)
    IFS=. read -r MA MI PA <<<"$CUR"
    case "$BUMP" in
      major) MA=$((MA + 1)); MI=0; PA=0 ;;
      minor) MI=$((MI + 1)); PA=0 ;;
      patch) PA=$((PA + 1)) ;;
    esac
    VER="$MA.$MI.$PA"
    ;;
  [0-9]*.[0-9]*.[0-9]*)
    [[ "$BUMP" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "error: bad version '$BUMP'" >&2; exit 1; }
    VER="$BUMP"
    ;;
  *)
    echo "error: expected patch|minor|major|x.y.z (got '$BUMP')" >&2; exit 1 ;;
esac

NOTE="${2:-Release v$VER}"
DATE="$(date +%Y-%m-%d)"
echo "Releasing v$CUR -> v$VER  ($NOTE)"

# 1. bump "version" in both manifests (perl: portable on macOS + Linux)
for f in .claude-plugin/plugin.json .claude-plugin/marketplace.json; do
  perl -0pi -e "s/\"version\":\s*\"[0-9]+\.[0-9]+\.[0-9]+\"/\"version\": \"$VER\"/" "$f"
done

# 2. prepend a CHANGELOG entry under the "# Changelog" header (line 1)
{
  echo "# Changelog"
  echo
  echo "## v$VER — $DATE"
  echo
  echo "- $NOTE"
  echo
  tail -n +3 CHANGELOG.md 2>/dev/null || true
} > CHANGELOG.md.tmp
mv CHANGELOG.md.tmp CHANGELOG.md

# 3. commit, tag, push
git add -A
git commit -m "release: v$VER" -m "$NOTE"
git tag "v$VER"
git push origin HEAD --tags

# 4. GitHub release (best-effort)
if command -v gh >/dev/null 2>&1; then
  gh release create "v$VER" --title "v$VER" --notes "$NOTE" 2>/dev/null \
    && echo "GitHub release v$VER created." \
    || echo "(skipped gh release — create it manually if needed)"
fi

echo
echo "Published v$VER. Consumers update with:  /plugin update project-with-reflect"
