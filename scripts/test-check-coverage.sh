#!/usr/bin/env bash
# Tests scripts/check-coverage.sh (rules: docs/agents/testing.md, Coverage).
# Usage: test-check-coverage.sh   (exit 1 when a case fails)
#
# The check reads the table that scripts/coverage.sh prints, so the cases feed it a fixed table and never run `swift test`.
set -uo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
check="$root/scripts/check-coverage.sh"
failed=0

# run <expected exit> <description> <table> [floor]: the floor is left out to test the default one.
run() {
  local want=$1 desc=$2 table=$3 floor=${4:-} got
  if [[ -n "$floor" ]]; then
    printf '%s' "$table" | "$check" "$floor" >/dev/null 2>&1
  else
    printf '%s' "$table" | "$check" >/dev/null 2>&1
  fi
  got=$?
  if [[ "$got" -ne "$want" ]]; then
    printf 'FAIL (want %s, got %s): %s\n' "$want" "$got" "$desc"
    failed=1
  fi
}

# row <name> <lines> <missed> <percent>: one line of the table, as coverage.sh prints it.
row() { printf '%-60s %6d lines %6d missed %8s\n' "$1" "$2" "$3" "$4"; }

above=$(row Sources/BreathnestKit/A.swift 10 0 100.00%; row Sources/BreathnestKit/B.swift 10 2 80.00%; row TOTAL 20 2 90.00%)
under=$(row Sources/BreathnestKit/A.swift 10 0 100.00%; row Sources/BreathnestKit/B.swift 10 3 70.00%; row TOTAL 20 3 85.00%)
justunder=$(row Sources/BreathnestKit/A.swift 10000 2001 79.99%; row TOTAL 10000 2001 79.99%)
totalunder=$(row Sources/BreathnestKit/A.swift 10 0 100.00%; row TOTAL 10 0 79.00%)
nolines=$(row Sources/BreathnestKit/Empty.swift 0 0 -; row Sources/BreathnestKit/A.swift 10 0 100.00%; row TOTAL 10 0 100.00%)

run 0 "every file and the total at or above the floor, a file exactly at 80.00% included" "$above"
run 1 "one file below the floor fails" "$under"
run 1 "79.99% is below an 80% floor" "$justunder"
run 1 "the total below the floor fails even when each file is above" "$totalunder"
run 0 "a file with no lines has no percent and is skipped" "$nolines"
run 1 "empty input is an error, not a pass" ""
run 1 "a table with only blank lines is an error" $'\n\n'
run 0 "a lower floor lets the weaker file pass" "$under" 70
run 1 "a higher floor fails files that passed" "$above" 95
run 1 "a floor that is not a number is an error" "$above" abc

# The message names the file under the floor and its percent, and not the files that pass.
message=$(printf '%s' "$under" | "$check" 2>&1 >/dev/null)
case "$message" in
  *B.swift*70.00%*) ;;
  *) printf 'FAIL: the message does not name the file under the floor and its percent: %s\n' "$message"; failed=1 ;;
esac
case "$message" in
  *A.swift*) printf 'FAIL: the message names a file that passes: %s\n' "$message"; failed=1 ;;
esac

[[ "$failed" -eq 0 ]] && echo "test-check-coverage: all cases passed"
exit "$failed"
