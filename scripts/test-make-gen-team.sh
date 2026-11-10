#!/usr/bin/env bash
# Tests that `make gen` writes the signing team of the environment or of local.env into the generated project
# (docs/agents/commands.md). It only runs xcodegen, so it needs no simulator. A local.env of the developer is put
# back afterwards.
# Usage: test-make-gen-team.sh   (exit 1 when a case fails)
set -uo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root" || exit 1
pbx=Breathnest.xcodeproj/project.pbxproj
backup=$(mktemp)
had_local=0
if [[ -f local.env ]]; then had_local=1; cp local.env "$backup"; fi
restore() {
  if [[ "$had_local" -eq 1 ]]; then cp "$backup" local.env; else rm -f local.env; fi
  rm -f "$backup"
  make -s gen >/dev/null 2>&1
}
trap restore EXIT
failed=0

# check <label> <expected team, empty for none>
check() {
  local teams
  teams=$(sed -nE 's/.*DEVELOPMENT_TEAM = "?([A-Z0-9]*)"?;.*/\1/p' "$pbx" | sort -u)
  if [[ "$teams" != "$2" ]]; then
    printf 'FAIL %s: want team "%s", project has "%s"\n' "$1" "$2" "$teams"
    failed=1
  fi
}

rm -f local.env
env -u DEVELOPMENT_TEAM make -s gen >/dev/null 2>&1 || { echo "FAIL: make gen without a team"; failed=1; }
check "no team set" ""

DEVELOPMENT_TEAM=ABCDE12345 make -s gen >/dev/null 2>&1
check "environment variable" "ABCDE12345"

echo 'DEVELOPMENT_TEAM=FILE123456' > local.env
env -u DEVELOPMENT_TEAM make -s gen >/dev/null 2>&1
check "local.env" "FILE123456"

DEVELOPMENT_TEAM=ENV1234567 make -s gen >/dev/null 2>&1
check "variable wins over local.env" "ENV1234567"

[[ "$failed" -eq 0 ]] && echo "all make gen team cases passed"
exit "$failed"
