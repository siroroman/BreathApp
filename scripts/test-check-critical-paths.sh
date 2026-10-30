#!/usr/bin/env bash
# Tests scripts/check-critical-paths.sh against a throwaway repository (rules: docs/agents/critical-paths.md).
# Usage: test-check-critical-paths.sh   (exit 1 when a case fails)
set -uo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
failed=0

kit=BreathnestKit/Sources/BreathnestKit
kit_tests=BreathnestKit/Tests/BreathnestKitTests

git init -q -b main "$tmp/repo"
cd "$tmp/repo" || exit 1
git config user.email t@example.com
git config user.name t
mkdir -p "$kit" "$kit_tests" App/Breathnest docs/agents scripts
cp "$root/docs/agents/critical-paths.md" docs/agents/
printf 'struct Session {}\n' >"$kit/Session.swift"
git add -A && git commit -qm base
git update-ref refs/remotes/origin/main HEAD

# case <expected exit> <description> <PR body> <files to change...>: each case starts from main.
case_() {
  local want=$1 desc=$2 pr_body=$3 f got
  shift 3
  git checkout -q -B work origin/main
  for f in "$@"; do mkdir -p "$(dirname "$f")"; printf 'change %s\n' "$RANDOM" >"$f"; done
  git add -A && git commit -qm change
  PR_BODY="$pr_body" "$root/scripts/check-critical-paths.sh" origin/main >/dev/null 2>&1
  got=$?
  if [[ "$got" -ne "$want" ]]; then
    printf 'FAIL (want %s, got %s): %s\n' "$want" "$got" "$desc"
    failed=1
  fi
}

case_ 1 "critical source without a test" "Summary" "$kit/Session.swift"
case_ 0 "critical source with a Kit test" "Summary" "$kit/Session.swift" "$kit_tests/SessionTests.swift"
case_ 0 "critical source with an app test" "Summary" "$kit/Session.swift" App/BreathnestTests/TickerTests.swift
case_ 0 "critical source with a warning first line" $'> **Warning:** not covered.\n\n## Summary' "$kit/Session.swift"
case_ 1 "warning that is not the first line" $'## Summary\n> **Warning:** late' "$kit/Session.swift"
case_ 0 "warning with CRLF" $'\r\n> **Warning:** not covered.\r\n' "$kit/Session.swift"
case_ 0 "source outside the registry" "Summary" "$kit/Greeting.swift"
case_ 0 "module name alone is no keyword hit" "Summary" App/Breathnest/ContentView.swift
case_ 0 "CI file is critical but not source" "Summary" Makefile scripts/x.sh
case_ 0 "docs only" "Summary" README.md

git checkout -q -B work origin/main
if "$root/scripts/check-critical-paths.sh" no-such-ref >/dev/null 2>&1; then
  echo "FAIL: unknown base should exit 1"
  failed=1
fi

if [[ $failed -eq 0 ]]; then echo "all check-critical-paths cases passed"; fi
exit $failed
