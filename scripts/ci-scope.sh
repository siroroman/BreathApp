#!/usr/bin/env bash
# Says whether a pull request needs the macOS job of ci.yml (rules: docs/agents/commands.md, CI).
#   scripts/ci-scope.sh [base]    prints swift=true or swift=false
#
# True when a changed file (git diff base...HEAD) is under App/ or BreathnestKit/, or is project.yml (it defines the
# app target). Scripts, workflows, the Makefile, tool pins and lint configs do not count: the ubuntu jobs check them.
# Without a base (workflow_dispatch) or with an all-zero one (the `before` of a push that creates a branch) there is
# no diff to narrow with, so it is true. A push to main passes the previous main tip as the base. A workflow-level
# `paths:` filter is not used: it leaves a required check pending, a skipped job counts as passed.
set -euo pipefail

base=${1:-}
if [[ -z "$base" || "$base" =~ ^0+$ ]]; then
  echo "swift=true"
  exit 0
fi

root=$(git rev-parse --show-toplevel)
cd "$root"
git rev-parse --verify -q "$base^{commit}" >/dev/null || { echo "ci-scope: unknown base '$base'" >&2; exit 1; }

# Shell `case` patterns on the repo-relative path, `*` also matches `/`.
paths=('App/*' 'BreathnestKit/*' 'project.yml')

while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  for glob in "${paths[@]}"; do
    # shellcheck disable=SC2254
    case "$f" in $glob) echo "swift=true"; exit 0 ;; esac
  done
done < <(git diff --name-only --no-renames "$base...HEAD")

echo "swift=false"
