#!/usr/bin/env bash
# Tests scripts/pr-facts.sh against a throwaway repository (rules: docs/agents/pull-requests.md).
# Usage: test-pr-facts.sh   (exit 1 when a case fails)
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
mkdir -p "$kit" "$kit_tests" App/Breathnest docs/agents
cp "$root/docs/agents/critical-paths.md" docs/agents/
printf 'struct Session {}\n' >"$kit/Session.swift"
printf '@Suite struct SessionTests {\n    @Test func oldBehaviour() {}\n    @Test func kept() {}\n}\n' >"$kit_tests/SessionTests.swift"
git add -A && git commit -qm base
git update-ref refs/remotes/origin/main HEAD

printf 'struct Session { var x = 1 }\n' >"$kit/Session.swift"
printf '@Suite struct SessionTests {\n    @Test func kept() {}\n    @Test("display name")\n    func lastCycleEndsAfterRequestedDuration() {}\n    @Test func leadInIsNotCounted() {}\n}\n' >"$kit_tests/SessionTests.swift"
printf 'struct Exercise {}\n' >"$kit/Exercise.swift"
printf 'import SwiftUI\n' >App/Breathnest/ContentView.swift
git add -A && git commit -qm change

out=$("$root/scripts/pr-facts.sh" origin/main 2>&1)

# expect <description> <fixed string that must appear in the output>
expect() {
  if ! grep -qF -- "$2" <<<"$out"; then
    printf 'FAIL: %s\n  missing: %s\n' "$1" "$2"
    failed=1
  fi
}
# reject <description> <fixed string that must not appear>
reject() {
  if grep -qF -- "$2" <<<"$out"; then
    printf 'FAIL: %s\n  unexpected: %s\n' "$1" "$2"
    failed=1
  fi
}

expect "mirrored test file with its count" "\`$kit/Session.swift\` -> \`$kit_tests/SessionTests.swift\` (tests: 3)"
expect "source without a test file" "\`$kit/Exercise.swift\` -> **no mirrored test file**"
expect "new tests on one line, @Test and func on separate lines" "(2): \`lastCycleEndsAfterRequestedDuration\`, \`leadInIsNotCounted\`"
reject "a kept test is not new" "\`kept\`, "
expect "removed test" "### Removed or renamed tests"
expect "removed test name" "\`oldBehaviour\`"
expect "critical path: session engine" "**Session engine and timing**: \`$kit/Session.swift\`"
expect "critical path: exercise data" "**Exercise data and identity**: \`$kit/Exercise.swift\`"
reject "an untouched area is not listed" "Log, Reminders"
reject "module name is not a keyword hit" "Breath level and Haptic plan"
expect "UI files" "- \`App/Breathnest/ContentView.swift\`"

# A diff without tests or critical paths says so.
git checkout -q -b docs-only origin/main
printf 'note\n' >README.md
git add -A && git commit -qm docs
out=$("$root/scripts/pr-facts.sh" origin/main 2>&1)
expect "no Swift source" "- No Swift source changed."
expect "no new tests" "- None."
expect "no critical path" "- None of the paths in"
expect "no UI" "No UI change."
reject "no removed section" "Removed or renamed"

# An unknown base fails.
if "$root/scripts/pr-facts.sh" no-such-ref >/dev/null 2>&1; then
  echo "FAIL: unknown base should exit 1"
  failed=1
fi

if [[ $failed -eq 0 ]]; then echo "all pr-facts cases passed"; fi
exit $failed
