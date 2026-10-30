#!/usr/bin/env bash
# Fails when a pull request changes source in a critical path without a test (rules: docs/agents/critical-paths.md).
#   PR_BODY="..." scripts/check-critical-paths.sh [base]    base defaults to origin/main
#
# Passes when no source file under BreathnestKit/Sources or App/Breathnest matches a glob of the registry,
# when any test file under BreathnestKit/Tests or App/BreathnestTests changed, or when the PR body starts with
# the `> **Warning:**` line that docs/agents/pull-requests.md asks for. The Build, project and CI area is not
# source, a test cannot cover it, so it never fails here.
set -euo pipefail

base=${1:-origin/main}
root=$(git rev-parse --show-toplevel)
cd "$root"
git rev-parse --verify -q "$base^{commit}" >/dev/null || { echo "check-critical-paths: unknown base '$base'" >&2; exit 1; }
range="$base...HEAD"
registry=docs/agents/critical-paths.md

changed=$(git diff --name-only --no-renames "$range")
globs=$(awk '/^Paths:/ { s = $0; while (match(s, /`[^`]+`/)) { print substr(s, RSTART + 1, RLENGTH - 2); s = substr(s, RSTART + RLENGTH) } }' "$registry")

hits=()
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  case "$f" in BreathnestKit/Sources/*|App/Breathnest/*) ;; *) continue ;; esac
  while IFS= read -r glob; do
    # shellcheck disable=SC2254
    case "$f" in $glob) hits+=("$f"); break ;; esac
  done <<<"$globs"
done <<<"$changed"

[[ ${#hits[@]} -eq 0 ]] && { echo "No critical path source changed."; exit 0; }

if grep -qE '^(BreathnestKit/Tests/|App/BreathnestTests/)' <<<"$changed"; then
  echo "Critical path source changed together with a test file."
  exit 0
fi

first=$(printf '%s\n' "${PR_BODY:-}" | tr -d '\r' | awk 'NF { print; exit }')
if [[ "$first" == '> **Warning:**'* ]]; then
  echo "Critical path source changed without a test, the PR body warns about it."
  exit 0
fi

{
  echo "Critical path changed with no test change:"
  printf '  - %s\n' "${hits[@]}"
  echo
  echo "  Add a test, or start the PR body with '> **Warning:** ...' saying what is not covered."
  echo "  Rules: docs/agents/critical-paths.md, docs/agents/pull-requests.md (Merge Danger)"
} >&2
exit 1
