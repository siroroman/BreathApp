#!/usr/bin/env bash
# Fails when a file of BreathnestKit/Sources, or the total, has a line coverage under the floor
# (rules: docs/agents/testing.md, Coverage). Reads the table that scripts/coverage.sh prints on stdin:
#   name  <lines> lines  <missed> missed  <percent>%        one line per file and a TOTAL line
#   scripts/coverage.sh | scripts/check-coverage.sh [floor]
# The floor is the number below, in percent. Lower it only with the reason written in docs/agents/testing.md.
# A file with no lines has no percent and is skipped. An empty table is an error: no data must not pass.
# Tested by scripts/test-check-coverage.sh.
set -euo pipefail

floor=${1:-80}

[[ "$floor" =~ ^[0-9]+(\.[0-9]+)?$ ]] || { echo "coverage: the floor '$floor' is not a number" >&2; exit 1; }

table=$(cat)
[[ -n "${table//[[:space:]]/}" ]] || { echo "coverage: no table on stdin, nothing to check" >&2; exit 1; }

# A TOTAL line with a percent must be there, otherwise the input is not the table and a pass would mean nothing.
printf '%s\n' "$table" | grep -Eq '^TOTAL .*[0-9.]+%$' || { echo "coverage: no TOTAL line with a percent in the table" >&2; exit 1; }

low=$(printf '%s\n' "$table" | awk -v floor="$floor" '
  NF >= 6 && $NF ~ /^[0-9.]+%$/ {
    percent = $NF
    sub("%", "", percent)
    if (percent + 0 < floor + 0) printf "coverage: %s is at %s, under the floor of %s%%\n", $1, $NF, floor
  }')

if [[ -n "$low" ]]; then
  echo "$low" >&2
  echo "coverage: write the missing tests (docs/agents/testing.md, Coverage), do not lower the floor to pass." >&2
  exit 1
fi
