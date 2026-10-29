#!/usr/bin/env bash
# Stop hook: runs `make lint test` when the working tree has Swift or project changes.
# On failure it exits 2 so the agent sees the output and keeps working. Rules: docs/agents/definition-of-done.md
set -uo pipefail

command -v jq >/dev/null || exit 0
INPUT=$(cat)
# The agent already got one failure report; do not loop forever.
[ "$(printf '%s' "$INPUT" | jq -r '.stop_hook_active // false')" = true ] && exit 0

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
[ -f Makefile ] || exit 0
CHANGED=$(git status --porcelain -- App BreathnestKit project.yml Makefile .swiftformat 2>/dev/null)
[ -n "$CHANGED" ] || exit 0

if ! OUT=$(make lint test 2>&1); then
  printf 'make lint test failed:\n%s\n' "$(printf '%s' "$OUT" | tail -60)" >&2
  exit 2
fi
exit 0
