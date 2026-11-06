#!/usr/bin/env bash
# Tests scripts/check-workflows.sh against throwaway workflow files (rules: docs/agents/git.md, Enforcement).
# Usage: test-check-workflows.sh   (exit 1 when a case fails)
set -uo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
failed=0

# case_ <expected exit> <description> <workflow yaml>: each case gets an empty directory with one workflow.
case_() {
  local want=$1 desc=$2 yaml=$3 got
  rm -rf "$tmp/wf" && mkdir "$tmp/wf"
  printf '%s\n' "$yaml" >"$tmp/wf/w.yml"
  "$root/scripts/check-workflows.sh" "$tmp/wf" >/dev/null 2>&1
  got=$?
  if [[ "$got" -ne "$want" ]]; then
    printf 'FAIL (want %s, got %s): %s\n' "$want" "$got" "$desc"
    failed=1
  fi
}

good=$'name: W\non: push\npermissions:\n  contents: read\njobs:\n  a:\n    runs-on: ubuntu-latest\n    timeout-minutes: 5\n    steps:\n      - run: true\n  b:\n    runs-on: ubuntu-latest\n    timeout-minutes: 10\n    steps:\n      - run: true'

case_ 0 "read-only permissions and a timeout on every job" "$good"
case_ 1 "no top-level permissions" $'name: W\non: push\njobs:\n  a:\n    runs-on: ubuntu-latest\n    timeout-minutes: 5\n    steps:\n      - run: true'
case_ 1 "wider permissions" "${good/contents: read/contents: write}"
case_ 1 "extra permission next to contents: read" "${good/  contents: read/  contents: read
  pull-requests: write}"
case_ 1 "second job has no timeout" "${good/    timeout-minutes: 10
/}"
case_ 1 "timeout is not a number" "${good/timeout-minutes: 5/timeout-minutes: soon}"
case_ 1 "no jobs at all" $'name: W\non: push\npermissions:\n  contents: read'
case_ 1 "not valid yaml" $'jobs: [unclosed'

rm -rf "$tmp/wf" && mkdir "$tmp/wf"
if "$root/scripts/check-workflows.sh" "$tmp/wf" >/dev/null 2>&1; then
  echo "FAIL: a directory with no workflows should exit 1"
  failed=1
fi

if [[ $failed -eq 0 ]]; then echo "all check-workflows cases passed"; fi
exit $failed
