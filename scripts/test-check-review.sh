#!/usr/bin/env bash
# Tests scripts/check-review.sh (rules: docs/agents/git.md, Enforcement).
# Usage: test-check-review.sh   (exit 1 when a case fails)
#
# The check asks git whether the reviewed commit is in the PR, so the cases run in a throwaway repo:
#   A - B - C   main, C is the head of the PR
#    \
#     X         a commit that is not in the PR
set -uo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
check="$root/scripts/check-review.sh"
failed=0

repo=$(mktemp -d)
trap 'rm -rf "$repo"' EXIT
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null
git_() { git -C "$repo" -c user.name=test -c user.email=test@example.com -c commit.gpgsign=false "$@"; }
git_ init -q -b main
git_ commit -q --allow-empty -m A
a=$(git_ rev-parse HEAD)
git_ commit -q --allow-empty -m B
b=$(git_ rev-parse HEAD)
git_ commit -q --allow-empty -m C
head=$(git_ rev-parse HEAD)
git_ switch -q -c side "$a"
git_ commit -q --allow-empty -m X
side=$(git_ rev-parse HEAD)
git_ switch -q main
unknown=3333333333333333333333333333333333333333

# run <expected exit> <description> <draft> <reviews json> [head sha]
run() {
  local want=$1 desc=$2 draft=$3 json=$4 sha=${5:-$head} got
  printf '%s' "$json" | (cd "$repo" && "$check" "$sha" "$draft") >/dev/null 2>&1
  got=$?
  if [[ "$got" -ne "$want" ]]; then
    printf 'FAIL (want %s, got %s): %s\n' "$want" "$got" "$desc"
    failed=1
  fi
}

# review <body> [state] [author_association]: one review object as the GitHub API returns it.
review() {
  ruby -rjson -e 'puts JSON.generate({ "id" => 1, "state" => ARGV[1], "author_association" => ARGV[2], "body" => ARGV[0] })' "$1" "${2:-COMMENTED}" "${3:-OWNER}"
}

# marker <sha>: the body the code-reviewer agent posts.
marker() { printf 'Findings: none.\n\n<!-- code-reviewer: %s -->' "$1"; }

reviewed=$(marker "$head")
ancestor=$(marker "$b")
outside=$(marker "$side")

# The reviewed commit is the head, or one the PR contains.
run 0 "review of the head commit" false "[$(review "$reviewed")]"
run 0 "review of a commit before the head (one round, fixes pushed after it)" false "[$(review "$ancestor")]"
run 0 "review of the first commit of the PR" false "[$(review "$(marker "$a")")]"
run 0 "review of an earlier commit next to other reviews" false "[$(review "Looks fine."),$(review "$outside"),$(review "$ancestor")]"
run 0 "earlier review, a later review has no marker" false "[$(review "$ancestor"),$(review "Looks fine.")]"
run 0 "marker with extra spaces" false "[$(review "<!--   code-reviewer:   $b   -->")]"
run 0 "draft with no review" true "[]"
run 0 "draft with a review of a commit outside the PR" true "[$(review "$outside")]"
run 0 "review of the head is a request for changes" false "[$(review "$reviewed" CHANGES_REQUESTED)]"
run 0 "an approval with the marker" false "[$(review "$reviewed" APPROVED)]"
run 0 "a dismissed review next to a live one for the head" false "[$(review "$outside" DISMISSED),$(review "$reviewed")]"

# Who counts: the repo is public, anyone can comment on a PR.
run 0 "review by a member" false "[$(review "$reviewed" COMMENTED MEMBER)]"
run 0 "review by a collaborator" false "[$(review "$reviewed" COMMENTED COLLABORATOR)]"
run 1 "review by an outside user" false "[$(review "$reviewed" COMMENTED NONE)]"
run 1 "review by a first-time contributor" false "[$(review "$reviewed" COMMENTED FIRST_TIME_CONTRIBUTOR)]"
run 1 "review by a contributor" false "[$(review "$reviewed" COMMENTED CONTRIBUTOR)]"
run 1 "review with no author_association" false '[{"id":1,"state":"COMMENTED","body":"<!-- code-reviewer: '"$head"' -->"}]'
run 0 "outside review next to a collaborator review" false "[$(review "$reviewed" COMMENTED NONE),$(review "$reviewed" COMMENTED COLLABORATOR)]"
run 1 "dismissed review of the head" false "[$(review "$reviewed" DISMISSED)]"
run 1 "pending review of the head" false "[$(review "$reviewed" PENDING)]"

# No review of a commit in the PR.
run 1 "no reviews" false "[]"
run 1 "review without a marker" false "[$(review "Looks fine.")]"
run 1 "review of a commit that is not in the PR" false "[$(review "$outside")]"
run 1 "review of a commit the repo does not have" false "[$(review "$(marker "$unknown")")]"
run 1 "review of a commit after the head" false "[$(review "$reviewed")]" "$b"
run 1 "marker with a short sha" false "[$(review "<!-- code-reviewer: ${head:0:7} -->")]"
run 1 "marker text outside an HTML comment" false "[$(review "code-reviewer: $head")]"
run 1 "review with a null body" false '[{"id":1,"state":"APPROVED","body":null}]'

# Bad input.
run 1 "empty input" false ""
run 1 "input that is not JSON" false "not json"
run 1 "input that is not a list" false '{"message":"Not Found"}'
run 1 "head sha is not a full sha" false "[$(review "$reviewed")]" abc123
run 1 "draft flag is not true or false" maybe "[$(review "$reviewed")]"

if [[ $failed -eq 0 ]]; then echo "all check-review cases passed"; fi
exit $failed
