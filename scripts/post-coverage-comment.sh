#!/usr/bin/env bash
# Posts the coverage table as one comment on a pull request and updates that comment on every later run (rules: docs/agents/testing.md, Coverage).
#   scripts/post-coverage-comment.sh <owner/repo> <pull request number> <markdown file>
#
# The comment is found by a hidden marker on its first line and by its author (github-actions[bot]), so a comment of a person
# is never edited. Needs `gh` with GH_TOKEN allowed to write pull requests, and `jq`; both are on the ubuntu runners.
set -euo pipefail

[[ $# -eq 3 ]] || { echo "usage: post-coverage-comment.sh <owner/repo> <pull request number> <markdown file>" >&2; exit 2; }
repo=$1 pr=$2 file=$3
[[ "$pr" =~ ^[0-9]+$ ]] || { echo "post-coverage-comment: '$pr' is not a pull request number" >&2; exit 2; }
[[ -s "$file" ]] || { echo "post-coverage-comment: '$file' is missing or empty" >&2; exit 1; }

marker='<!-- kit-coverage -->'
body=$(mktemp)
trap 'rm -f "$body"' EXIT
{ echo "$marker"; cat "$file"; } > "$body"

# `sed -n 1p` and not `head -n 1`: head would close the pipe early and fail `gh` under pipefail.
id=$(gh api --paginate "repos/$repo/issues/$pr/comments" |
  jq -r --arg marker "$marker" '.[] | select(.user.login == "github-actions[bot]" and (.body | startswith($marker))) | .id' |
  sed -n 1p)

if [[ -n "$id" ]]; then
  gh api --method PATCH "repos/$repo/issues/comments/$id" -F "body=@$body" > /dev/null
  echo "Updated the coverage comment $id on pull request #$pr."
else
  gh api --method POST "repos/$repo/issues/$pr/comments" -F "body=@$body" > /dev/null
  echo "Posted the coverage comment on pull request #$pr."
fi
