#!/usr/bin/env bash
# Tests scripts/check-tools.sh against throwaway trees and fake tools (rules: docs/agents/commands.md, Tools).
# Usage: test-check-tools.sh   (exit 1 when a case fails)
set -uo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
failed=0

# fake <dir> <tool> <version output>: an executable that prints what the real tool prints for --version.
fake() {
  mkdir -p "$1"
  printf '#!/bin/sh\necho "%s"\n' "$3" >"$1/$2"
  chmod +x "$1/$2"
}

# fixture: a tree with tools.env and fake tools on PATH that all match. Each case then changes one thing.
fixture() {
  rm -rf "$tmp/repo" "$tmp/bin" && mkdir -p "$tmp/repo" "$tmp/bin"
  cat >"$tmp/repo/tools.env" <<'EOF'
SWIFTFORMAT_VERSION=1.2.3
SWIFTLINT_VERSION=4.5.6
XCODEGEN_VERSION=7.8.9
EOF
  fake "$tmp/bin" swiftformat "1.2.3"
  fake "$tmp/bin" swiftlint "4.5.6"
  fake "$tmp/bin" xcodegen "Version: 7.8.9"
}

# case_ <expected exit> <description>: runs the check on the fixture as the case left it. Only the fake tools and
# the system tools are on PATH, so a tool installed on this machine cannot leak into a case.
case_() {
  local want=$1 desc=$2 got
  PATH="$tmp/bin:/usr/bin:/bin" "$root/scripts/check-tools.sh" "$tmp/repo" >"$tmp/out" 2>&1
  got=$?
  if [[ "$got" -ne "$want" ]]; then
    printf 'FAIL (want %s, got %s): %s\n' "$want" "$got" "$desc"
    failed=1
  fi
}

# says <text> <description>: the output of the last case contains the text.
says() {
  if ! grep -qF -- "$1" "$tmp/out"; then
    printf 'FAIL: %s (output has no "%s")\n' "$2" "$1"
    failed=1
  fi
}

fixture
case_ 0 "every version matches"

fixture
fake "$tmp/bin" swiftformat "0.64.5"
case_ 1 "swiftformat differs"
says "swiftformat 0.64.5" "names the installed swiftformat"
says "1.2.3" "names the pinned swiftformat"
says "scripts/install-tools.sh" "names the fix"

fixture
fake "$tmp/bin" swiftlint "0.65.1"
case_ 1 "swiftlint differs"
says "swiftlint 0.65.1" "names the installed swiftlint"
says "4.5.6" "names the pinned swiftlint"
says "scripts/install-tools.sh" "names the fix"

fixture
fake "$tmp/bin" swiftformat "0.64.5"
fake "$tmp/bin" swiftlint "0.65.1"
case_ 1 "both differ"
says "swiftformat 0.64.5" "names both, swiftformat"
says "swiftlint 0.65.1" "names both, swiftlint"

fixture
rm "$tmp/bin/swiftformat"
case_ 1 "swiftformat is missing"
says "swiftformat is not installed" "names the missing tool"
says "scripts/install-tools.sh" "names the fix"

fixture
rm "$tmp/bin/swiftlint"
case_ 1 "swiftlint is missing"
says "swiftlint is not installed" "names the missing tool"

fixture
fake "$tmp/bin" xcodegen "Version: 2.99.0"
case_ 0 "xcodegen differs, only a warning"
says "warning" "warns about xcodegen"
says "2.99.0" "names the installed xcodegen"

fixture
rm "$tmp/bin/xcodegen"
case_ 0 "xcodegen is not installed, make lint does not need it"

fixture
fake "$tmp/bin" swiftformat "0.64.5"
fake "$tmp/repo/.tools/bin" swiftformat "1.2.3"
case_ 0 ".tools/bin of the repo wins over PATH"

fixture
fake "$tmp/repo/.tools/bin" swiftformat "0.64.5"
case_ 1 "a wrong version in .tools/bin is not hidden by a right one on PATH"

fixture
rm "$tmp/repo/tools.env"
case_ 1 "tools.env is missing"
says "tools.env" "names tools.env"

fixture
sed -i.bak '/^SWIFTLINT_VERSION/d' "$tmp/repo/tools.env" && rm "$tmp/repo/tools.env.bak"
case_ 1 "tools.env has no SWIFTLINT_VERSION"
says "SWIFTLINT_VERSION" "names the missing key"

fixture
PATH="$tmp/bin:/usr/bin:/bin" "$root/scripts/check-tools.sh" "$tmp/nowhere" >"$tmp/out" 2>&1
if [[ $? -ne 1 ]]; then
  echo "FAIL: a missing repo root should exit 1"
  failed=1
fi

if [[ $failed -eq 0 ]]; then echo "all check-tools cases passed"; fi
exit $failed
