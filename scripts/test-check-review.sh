#!/usr/bin/env bash
# Tests scripts/check-review.sh (rules: docs/agents/git.md, Enforcement).
# Usage: test-check-review.sh   (exit 1 when a case fails)
set -uo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
check="$root/scripts/check-review.sh"
failed=0

head=1111111111111111111111111111111111111111
old=2222222222222222222222222222222222222222

# run <expected exit> <description> <draft> <reviews json> [head sha]
run() {
  local want=$1 desc=$2 draft=$3 json=$4 sha=${5:-$head} got
  printf '%s' "$json" | "$check" "$sha" "$draft" >/dev/null 2>&1
  got=$?
  if [[ "$got" -ne "$want" ]]; then
    printf 'FAIL (want %s, got %s): %s\n' "$want" "$got" "$desc"
    failed=1
  fi
}

# review <body> [state]: one review object as the GitHub API returns it.
review() {
  ruby -rjson -e 'puts JSON.generate({ "id" => 1, "state" => ARGV[1], "body" => ARGV[0] })' "$1" "${2:-COMMENTED}"
}

reviewed="Findings: none.

<!-- code-reviewer: $head -->"
stale="Findings: none.

<!-- code-reviewer: $old -->"

run 0 "review for the head commit" false "[$(review "$reviewed")]"
run 0 "review for the head commit among other reviews" false "[$(review "Looks fine."),$(review "$stale"),$(review "$reviewed")]"
run 0 "marker with extra spaces" false "[$(review "<!--   code-reviewer:   $head   -->")]"
run 0 "draft with no review" true "[]"
run 0 "draft with a stale review" true "[$(review "$stale")]"
run 0 "review for the head commit is a request for changes" false "[$(review "$reviewed" CHANGES_REQUESTED)]"
run 0 "a dismissed review for an older commit next to a live one for the head" false "[$(review "$stale" DISMISSED),$(review "$reviewed")]"
run 1 "dismissed review for the head commit" false "[$(review "$reviewed" DISMISSED)]"
run 1 "pending review for the head commit" false "[$(review "$reviewed" PENDING)]"
run 1 "no reviews" false "[]"
run 1 "review without a marker" false "[$(review "Looks fine.")]"
run 1 "review for an older commit" false "[$(review "$stale")]"
run 1 "marker in a review of an older commit only, newer review has none" false "[$(review "$stale"),$(review "Looks fine.")]"
run 1 "marker with a short sha" false "[$(review "<!-- code-reviewer: ${head:0:7} -->")]"
run 1 "marker text outside an HTML comment" false "[$(review "code-reviewer: $head")]"
run 1 "review with a null body" false '[{"id":1,"state":"APPROVED","body":null}]'
run 1 "empty input" false ""
run 1 "input that is not JSON" false "not json"
run 1 "input that is not a list" false '{"message":"Not Found"}'
run 1 "head sha is not a full sha" false "[$(review "$reviewed")]" abc123
run 1 "draft flag is not true or false" maybe "[$(review "$reviewed")]"

if [[ $failed -eq 0 ]]; then echo "all check-review cases passed"; fi
exit $failed
