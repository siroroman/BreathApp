#!/usr/bin/env bash
# Tests .swiftlint.yml against throwaway sources: every rule fails on a file that breaks it, a clean file passes
# (rules: docs/agents/ios.md, Conventions, and docs/agents/testing.md, Time).
# Usage: test-swiftlint-rules.sh   (exit 1 when a case fails, needs swiftlint)
set -uo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
command -v swiftlint >/dev/null || { echo "test-swiftlint-rules: swiftlint is not installed (brew install swiftlint)" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
failed=0

kit=BreathnestKit/Sources/BreathnestKit
app=App/Breathnest

fixture() {
  rm -rf "$tmp/repo" && mkdir -p "$tmp/repo/$kit" "$tmp/repo/$app" "$tmp/repo/BreathnestKit/Tests/BreathnestKitTests" && cd "$tmp/repo" || exit 1
  cp "$root/.swiftlint.yml" .swiftlint.yml
  # SwiftLint exits with an error when it finds nothing to lint, so a tree always has one clean file.
  printf 'import Foundation\n' >"$app/Clean.swift"
}

# case_ <file> <rule id or ""> <description> <swift source>: writes the file and lints the tree. An empty rule id
# means the tree must pass, otherwise it must fail and the output must name the rule.
case_() {
  local file=$1 rule=$2 desc=$3 source=$4 got
  fixture
  mkdir -p "$(dirname "$file")" && printf '%s\n' "$source" >"$file"
  swiftlint lint --strict --no-cache --quiet >"$tmp/out" 2>&1
  got=$?
  if [[ -z "$rule" ]]; then
    if [[ "$got" -ne 0 ]]; then printf 'FAIL (should pass): %s\n' "$desc"; sed 's/^/    /' "$tmp/out"; failed=1; fi
  elif [[ "$got" -eq 0 ]] || ! grep -q "($rule)" "$tmp/out"; then
    printf 'FAIL (want %s): %s\n' "$rule" "$desc"; sed 's/^/    /' "$tmp/out"; failed=1
  fi
}

case_ "$kit/A.swift" "" "clean Kit file" $'import Foundation\n\nstruct A {\n    func run(clock: some Clock<Duration>) async throws {\n        try await clock.sleep(for: .seconds(1))\n    }\n}'

case_ "$kit/A.swift" time_from_injected_clock "Date() in the Kit" $'import Foundation\n\nlet now = Date()'
case_ "$kit/A.swift" time_from_injected_clock "ContinuousClock() in the Kit" $'let clock = ContinuousClock()'
case_ "$kit/A.swift" time_from_injected_clock "Task.sleep in the Kit" $'func f() async throws {\n    try await Task.sleep(for: .seconds(1))\n}'
case_ "$app/A.swift" "" "ContinuousClock() at the edge in the app" $'let clock = ContinuousClock()'

case_ "$app/A.swift" no_dispatch_queue "DispatchQueue in the app" $'import Foundation\n\nfunc f() {\n    DispatchQueue.main.async {}\n}'
case_ "$kit/A.swift" no_dispatch_queue "DispatchQueue in the Kit" $'import Foundation\n\nlet queue = DispatchQueue(label: "x")'
case_ "$app/A.swift" no_combine "import Combine" $'import Combine'
case_ "$app/A.swift" no_observable_object "ObservableObject" $'import Foundation\n\nfinal class Model: ObservableObject {}'
case_ "$app/A.swift" no_completion_handler "completion parameter" $'func load(completion: @escaping (Int) -> Void) {}'
case_ "$app/A.swift" no_completion_handler "completionHandler parameter" $'func load(completionHandler: (Int) -> Void) {}'
case_ "$app/A.swift" no_completion_handler "handler parameter" $'func load(handler: @escaping @Sendable () -> Void) {}'
case_ "$app/A.swift" "" "an unrelated closure parameter" $'func map(transform: (Int) -> Int) {}'

case_ "$app/A.swift" force_unwrapping "force unwrap" $'let x: Int? = 1\nlet y = x!'
case_ "$app/A.swift" force_try "try!" $'let y = try! JSONEncoder().encode(1)'
case_ "BreathnestKit/Tests/BreathnestKitTests/ATests.swift" "" "force unwrap, try! and Date() in tests" $'import Foundation\n\nlet x: Int? = 1\nlet y = x!\nlet z = try! JSONEncoder().encode(1)\nlet now = Date()'

# Every message names a doc.
fixture
printf 'let now = Date()\n' >"$kit/A.swift"
swiftlint lint --strict --no-cache --quiet >"$tmp/out" 2>&1
grep -q 'docs/agents/testing.md' "$tmp/out" || { echo "FAIL: the time message should name docs/agents/testing.md"; failed=1; }
printf 'import Combine\n' >"$kit/A.swift"
swiftlint lint --strict --no-cache --quiet >"$tmp/out" 2>&1
grep -q 'docs/agents/ios.md' "$tmp/out" || { echo "FAIL: the Combine message should name docs/agents/ios.md"; failed=1; }

if [[ $failed -eq 0 ]]; then echo "all swiftlint rule cases passed"; fi
exit $failed
