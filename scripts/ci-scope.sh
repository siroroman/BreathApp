#!/usr/bin/env bash
# Says whether a pull request needs the macOS job of ci.yml (rules: docs/agents/commands.md, CI).
#   scripts/ci-scope.sh [base]    prints swift=true or swift=false
#
# True when a changed file (git diff base...HEAD) is one the app, the build or `make lint` reads. Without a base
# (push to main, workflow_dispatch) there is no diff to narrow with, so it is true. A workflow-level `paths:` filter
# is not used: it leaves a required check pending, a skipped job counts as passed.
set -euo pipefail

base=${1:-}
if [[ -z "$base" ]]; then
  echo "swift=true"
  exit 0
fi

root=$(git rev-parse --show-toplevel)
cd "$root"
git rev-parse --verify -q "$base^{commit}" >/dev/null || { echo "ci-scope: unknown base '$base'" >&2; exit 1; }

# Shell `case` patterns on the repo-relative path, `*` also matches `/`.
paths=(
  'App/*' 'BreathnestKit/*' 'project.yml' 'Makefile'
  '.swiftformat' '.swiftlint.yml' 'tools.env' 'Brewfile' 'scripts/*' '.github/workflows/ci.yml'
)

while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  for glob in "${paths[@]}"; do
    # shellcheck disable=SC2254
    case "$f" in $glob) echo "swift=true"; exit 0 ;; esac
  done
done < <(git diff --name-only --no-renames "$base...HEAD")

echo "swift=false"
