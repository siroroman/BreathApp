#!/usr/bin/env bash
# Tests scripts/check-pr-body.sh (rules: docs/agents/pull-requests.md).
# Usage: test-check-pr-body.sh   (exit 1 when a case fails)
set -uo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
check="$root/scripts/check-pr-body.sh"
failed=0

# body <skipped section> <empty section> <closing line>: a complete body with one section left out or blanked.
body() {
  local name
  for name in Summary Tests Snapshots Evidence "Merge Danger" "Reviewer notes"; do
    [[ "$name" == "$1" ]] && continue
    printf '## %s\n' "$name"
    [[ "$name" == "$2" ]] || printf 'Some text.\n'
    printf '\n'
  done
  printf '%s\n' "$3"
}

# run <expected exit> <description> <body>
run() {
  printf '%s' "$3" | "$check" - >/dev/null 2>&1
  local got=$?
  if [[ "$got" -ne "$1" ]]; then
    printf 'FAIL (want %s, got %s): %s\n' "$1" "$got" "$2"
    failed=1
  fi
}

good=$(body "" "" "Closes #12")

run 0 "complete body" "$good"
run 0 "attribution after Closes" "$good"$'\n\n🤖 Generated with [Claude Code](https://claude.com/claude-code)'
run 0 "warning line above the Summary" $'> **Warning:** no test.\n\n'"$good"
run 0 "CRLF line endings" "$(printf '%s\n' "$good" | sed 's/$/\r/')"
run 1 "empty body" ""
run 1 "missing Evidence" "$(body Evidence "" "Closes #12")"
run 1 "empty last section" "$(body "" "Reviewer notes" "Closes #12")"
run 1 "empty first section" "$(body "" Summary "Closes #12")"
run 1 "section with only an HTML comment" "${good/Some text./<!-- fill in -->}"
run 1 "sections out of order" $'## Tests\nx\n\n## Summary\nx\n\n## Snapshots\nx\n\n## Evidence\nx\n\n## Merge Danger\nx\n\n## Reviewer notes\nx\n\nCloses #1'
run 1 "no Closes line" "$(body "" "" "")"
run 1 "Closes without a number" "$(body "" "" "Closes #")"
run 1 "Closes not last" "$good"$'\nMore text.'

if [[ $failed -eq 0 ]]; then echo "all check-pr-body cases passed"; fi
exit $failed
