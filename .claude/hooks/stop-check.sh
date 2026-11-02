#!/usr/bin/env bash
# Stop hook: runs `make lint test` when Swift or project files differ from main, committed or not.
# On failure it exits 2 so the agent sees the output and keeps working. Rules: docs/agents/definition-of-done.md
# Tested by scripts/test-stop-check.sh.
set -uo pipefail

command -v jq >/dev/null || exit 0
INPUT=$(cat)
# The agent already got one failure report; do not loop forever.
[ "$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false')" = true ] && exit 0

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
[ -f Makefile ] || exit 0

WATCHED=(App BreathnestKit project.yml Makefile .swiftformat)

# Commits since the merge-base with origin/main, else main. With neither (or no merge-base) only the working tree counts.
BASE=
for ref in origin/main main; do
  if git rev-parse --verify -q "$ref^{commit}" >/dev/null 2>&1; then
    BASE=$(git merge-base HEAD "$ref" 2>/dev/null) && break
    BASE=
  fi
done

# Tracked changes (committed since BASE and uncommitted) plus untracked files.
if [ -n "$BASE" ]; then
  CHANGED=$(git diff --name-only "$BASE" -- "${WATCHED[@]}" 2>/dev/null)
else
  CHANGED=$(git status --porcelain --untracked-files=all -- "${WATCHED[@]}" 2>/dev/null)
fi
CHANGED+=$(git ls-files --others --exclude-standard -- "${WATCHED[@]}" 2>/dev/null)
[ -n "$CHANGED" ] || exit 0

if ! OUT=$(make lint test 2>&1); then
  printf 'make lint test failed:\n%s\n' "$(printf '%s' "$OUT" | tail -60)" >&2
  exit 2
fi
exit 0
