#!/usr/bin/env bash
# Runs the Kit tests with code coverage and prints the line coverage of BreathnestKit/Sources (rules: docs/agents/testing.md, Coverage):
#   scripts/coverage.sh [repo root]    root defaults to the repository of this script
#
# It fails when a test fails, when the coverage data is missing, and when a file or the total is under the floor of
# scripts/check-coverage.sh. Test and support files are not counted.
# When GITHUB_STEP_SUMMARY is set (a GitHub Actions step) the table goes there too, with the files under the floor.
set -euo pipefail

# No git here: the Kit job of CI runs in a Swift image that may have no git, so the root comes from the script path.
root=${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}
[[ -d "$root/BreathnestKit" ]] || { echo "coverage: no BreathnestKit directory in '$root'" >&2; exit 1; }
cd "$root/BreathnestKit"

swift test --enable-code-coverage --quiet

# The test bundle is a directory on macOS (the program is in Contents/MacOS) and a plain executable on Linux.
bin_dir=$(swift build --show-bin-path)
profile="$(dirname "$(swift test --show-codecov-path)")/default.profdata"
[[ -f "$profile" ]] || { echo "coverage: no profile data at $profile, did the tests run with coverage?" >&2; exit 1; }

programs=()
for bundle in "$bin_dir"/*.xctest; do
  [[ -e "$bundle" ]] || continue
  if [[ -d "$bundle" ]]; then
    program="$bundle/Contents/MacOS/$(basename "$bundle" .xctest)"
  else
    program="$bundle"
  fi
  [[ -f "$program" ]] || { echo "coverage: the test bundle $bundle has no program at $program" >&2; exit 1; }
  programs+=("$program")
done
[[ ${#programs[@]} -gt 0 ]] || { echo "coverage: no .xctest in $bin_dir" >&2; exit 1; }

# Further test programs are passed as -object, the first one is the positional argument.
objects=()
for program in "${programs[@]:1}"; do objects+=(-object "$program"); done

if command -v xcrun >/dev/null 2>&1; then llvm_cov=(xcrun llvm-cov); else llvm_cov=(llvm-cov); fi

# Columns of `llvm-cov report`: name, 3 region, 3 function, 3 line (total, missed, percent), 3 branch. The path is made relative to Sources.
report=$("${llvm_cov[@]}" report "${programs[0]}" ${objects[@]+"${objects[@]}"} -instr-profile="$profile" \
  -ignore-filename-regex='/(Tests|\.build)/' | awk -v root="$root/BreathnestKit/" '
    /^(Filename|---)/ { next }
    {
      name = $1
      if ($1 == "TOTAL") { total = sprintf("%-60s %6d lines %6d missed %8s", "TOTAL", $8, $9, $10); next }
      sub("^" root, "", name)
      printf "%-60s %6d lines %6d missed %8s\n", name, $8, $9, $10
    }
    END { if (total != "") print total }')

[[ -n "$report" ]] || { echo "coverage: llvm-cov reported no source file under BreathnestKit/Sources" >&2; exit 1; }

echo
echo "Line coverage of BreathnestKit/Sources:"
echo "$report"

# The files under the floor, taken from the check so the number lives in one place. The summary is written before the exit.
status=0
failures=$("$root/scripts/check-coverage.sh" <<<"$report" 2>&1) || status=$?
[[ -z "$failures" ]] || echo "$failures" >&2

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  {
    echo "### Kit line coverage (BreathnestKit/Sources)"
    echo
    echo '```'
    echo "$report"
    [[ -z "$failures" ]] || { echo; echo "$failures"; }
    echo '```'
  } >> "$GITHUB_STEP_SUMMARY"
fi

exit "$status"
