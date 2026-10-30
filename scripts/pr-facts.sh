#!/usr/bin/env bash
# Prints the facts a pull request body needs, as Markdown to paste or edit (rules: docs/agents/pull-requests.md).
#   scripts/pr-facts.sh [base]    base defaults to origin/main; compares the merge base with HEAD
#
# Sections: tests that cover the changed code, new and removed tests, critical paths touched,
# and the UI files that call for snapshots. It reads the committed diff only, so commit first.
set -euo pipefail

base=${1:-origin/main}
root=$(git rev-parse --show-toplevel)
cd "$root"
git rev-parse --verify -q "$base^{commit}" >/dev/null || { echo "pr-facts: unknown base '$base'" >&2; exit 1; }
range="$base...HEAD"

changed=$(git diff --name-status --no-renames "$range" | awk -F'\t' '$1 != "D" { print $2 }')
if [[ -z "$(git diff --name-only "$range")" ]]; then
  echo "pr-facts: no committed changes against $base" >&2
  exit 1
fi

kit_src=BreathnestKit/Sources/BreathnestKit/
kit_tests=BreathnestKit/Tests/BreathnestKitTests/
app_src=App/Breathnest/
app_tests=App/BreathnestTests/

# Number of @Test attributes in a file at HEAD.
count_tests() { git show "HEAD:$1" | grep -c '@Test' || true; }

# Test names (func after @Test) found on the added (+) or removed (-) lines of the diff, as "file<TAB>name".
test_names() {
  git diff -U0 --no-renames "$range" -- '*Tests/*.swift' | awk -v sign="$1" '
    /^(\+\+\+|---) / { if ($1 == "+++" && $2 != "/dev/null") file = substr($2, 3); else if ($1 == "---" && $2 != "/dev/null") file = substr($2, 3); next }
    substr($0, 1, 1) != sign { next }
    {
      line = substr($0, 2)
      if (line ~ /@Test/) pending = 1
      if (pending && match(line, /func [A-Za-z_][A-Za-z0-9_]*/)) {
        print file "\t" substr(line, RSTART + 5, RLENGTH - 5)
        pending = 0
      }
    }'
}

print_names() { # file<TAB>name lines -> "- `file`: `a`, `b`"
  awk -F'\t' '
    { if (!($1 in names)) order[++n] = $1; names[$1] = names[$1] (names[$1] ? ", " : "") "`" $2 "`"; count[$1]++ }
    END { for (i = 1; i <= n; i++) printf "- `%s` (%d): %s\n", order[i], count[order[i]], names[order[i]] }'
}

echo "### Tests for the changed code"
echo
covered=0
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  case "$f" in
    "$kit_src"*) mirror="$kit_tests${f#"$kit_src"}" ;;
    "$app_src"*) mirror="$app_tests${f#"$app_src"}" ;;
    *) continue ;;
  esac
  mirror="${mirror%.swift}Tests.swift"
  covered=1
  if git cat-file -e "HEAD:$mirror" 2>/dev/null; then
    printf -- '- `%s` -> `%s` (tests: %s)\n' "$f" "$mirror" "$(count_tests "$mirror")"
  else
    printf -- '- `%s` -> **no mirrored test file** (`%s` does not exist)\n' "$f" "$mirror"
  fi
done <<<"$changed"
[[ $covered -eq 0 ]] && echo "- No Swift source changed."
echo
touched_tests=$(printf '%s\n' "$changed" | grep -E "^($kit_tests|$app_tests).*\.swift$" || true)
if [[ -n "$touched_tests" ]]; then
  echo "Test files touched:"
  while IFS= read -r f; do printf -- '- `%s` (tests: %s)\n' "$f" "$(count_tests "$f")"; done <<<"$touched_tests"
  echo
fi

added=$(test_names +)
removed=$(test_names -)
echo "### New tests"
echo
if [[ -n "$added" ]]; then printf '%s\n' "$added" | print_names; else echo "- None."; fi
echo
if [[ -n "$removed" ]]; then
  echo "### Removed or renamed tests"
  echo
  printf '%s\n' "$removed" | print_names
  echo "A renamed test shows up here and under New tests. Explain every real removal in Reviewer notes."
  echo
fi

echo "### Critical paths touched"
echo
registry=docs/agents/critical-paths.md
hits=0
if [[ -f "$registry" ]]; then
  # "### Area" headings followed by a "Paths:" line of backticked globs -> "area<TAB>glob".
  while IFS=$'\t' read -r area glob; do
    matched=""
    while IFS= read -r f; do
      # shellcheck disable=SC2254
      case "$f" in $glob) matched="$matched \`$f\`" ;; esac
    done < <(git diff --name-only "$range")
    if [[ -n "$matched" ]]; then
      hits=1
      printf -- '- **%s**:%s\n' "$area" "$matched"
    fi
  done < <(awk '
    /^### / { area = substr($0, 5); next }
    /^Paths:/ { s = $0; while (match(s, /`[^`]+`/)) { print area "\t" substr(s, RSTART + 1, RLENGTH - 2); s = substr(s, RSTART + RLENGTH) } }
  ' "$registry")
fi
[[ $hits -eq 0 ]] && echo "- None of the paths in \`$registry\` changed."
echo

echo "### Snapshots"
echo
ui=$(git diff --name-only "$range" | grep '^App/Breathnest/' || true)
if [[ -n "$ui" ]]; then
  echo "UI files changed:"
  while IFS= read -r f; do printf -- '- `%s`\n' "$f"; done <<<"$ui"
  echo
  shots=$(ls build/*.png 2>/dev/null || true)
  if [[ -n "$shots" ]]; then
    echo "Screenshots in build/ (attach those from this commit, \`git rev-parse --short HEAD\` = $(git rev-parse --short HEAD)):"
    while IFS= read -r f; do printf -- '- `%s`\n' "$f"; done <<<"$shots"
  else
    echo "No screenshot in build/ yet: run \`make run screenshot\` (and the \`ui-verifier\` agent for AX5)."
  fi
else
  echo "No UI change."
fi
