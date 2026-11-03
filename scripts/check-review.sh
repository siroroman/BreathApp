#!/usr/bin/env bash
# Fails when a pull request that is not a draft has no code-reviewer review for its current head commit
# (rules: docs/agents/git.md, Enforcement). The `code-reviewer` agent ends the review it posts with
# `<!-- code-reviewer: <head sha> -->`. A push after the review changes the head, so it needs a new review.
# GitHub cannot tell a fresh session from the one that wrote the code, so this proves a review was posted, not that it was fresh.
# A dismissed or pending review does not count, and neither does one by a user who is not the owner, a member or a
# collaborator of the repo (the repo is public, anyone can post a comment review).
#   scripts/check-review.sh <head sha> <draft: true|false>   reads the JSON list of reviews on stdin
#   (gh api repos/<owner>/<repo>/pulls/<number>/reviews --paginate --slurp, the pages flattened into one list:
#   --paginate alone prints one list per page, which is not one JSON document)
# Needs ruby (ships with macOS and the ubuntu runners), only for its JSON parser.
set -euo pipefail

sha=${1:-}
draft=${2:-}

[[ "$sha" =~ ^[0-9a-f]{40}$ ]] || { echo "check-review: '$sha' is not a full commit sha" >&2; exit 1; }
[[ "$draft" == "true" || "$draft" == "false" ]] || { echo "check-review: draft must be true or false, got '$draft'" >&2; exit 1; }

raw=$(cat)
if [[ "$draft" == "true" ]]; then
  echo "Draft pull request, no review needed yet."
  exit 0
fi

ruby -rjson -e '
  sha = ARGV[0]
  begin
    reviews = JSON.parse(STDIN.read)
  rescue JSON::ParserError => e
    warn "check-review: the reviews are not valid JSON (#{e.message.lines.first.strip})"
    exit 1
  end
  unless reviews.is_a?(Array)
    warn "check-review: expected a list of reviews"
    exit 1
  end
  marker = /<!--\s*code-reviewer:\s*#{sha}\s*-->/
  states = %w[COMMENTED APPROVED CHANGES_REQUESTED]
  trusted = %w[OWNER MEMBER COLLABORATOR]
  counts = lambda do |r|
    r.is_a?(Hash) && states.include?(r["state"]) && trusted.include?(r["author_association"]) && r["body"].to_s.match?(marker)
  end
  if reviews.any?(&counts)
    puts "The code-reviewer reviewed #{sha[0, 7]}."
    exit 0
  end
  warn "No code-reviewer review for the current head commit #{sha[0, 7]}."
  warn
  warn "  Run the `code-reviewer` agent on this pull request in a fresh session. It posts a review that ends with"
  warn "  <!-- code-reviewer: #{sha} -->. A push after the review needs a new one. Rules: docs/agents/git.md."
  exit 1
' "$sha" <<<"$raw"
