#!/usr/bin/env bash
# Validates a pull request body against the contract in docs/agents/pull-requests.md.
# Usage: check-pr-body.sh <file | ->   ("-" reads stdin, e.g. the PR body in CI)
#
# Required: the six sections in order, each with text (HTML comments do not count),
# and `Closes #<issue>` as the last line of your own text (attribution lines after it are ignored).
set -euo pipefail

src="${1:--}"
if [[ "$src" == "-" ]]; then raw=$(cat); else raw=$(cat "$src"); fi

# GitHub's web editor sends CRLF. Drop \r, then HTML comments (also multi-line ones).
body=$(printf '%s\n' "$raw" | tr -d '\r' | perl -0pe 's/<!--.*?-->//gs')

sections=("Summary" "Tests" "Snapshots" "Evidence" "Merge Danger" "Reviewer notes")
errors=()

# Text of one section: lines after its heading up to the next "## " heading or the Closes line.
section_text() {
  printf '%s\n' "$body" | awk -v h="## $1" '
    $0 == h { on = 1; next }
    /^## / || /^Closes #/ { on = 0 }
    on'
}

last=0
for name in "${sections[@]}"; do
  line=$(printf '%s\n' "$body" | grep -n -x -F -m1 -- "## $name" | cut -d: -f1 || true)
  if [[ -z "$line" ]]; then
    errors+=("missing section '## $name'")
    continue
  fi
  if (( line < last )); then errors+=("section '## $name' is out of order"); fi
  last=$line
  if ! section_text "$name" | grep -q '[^[:space:]]'; then
    errors+=("section '## $name' is empty, write one line (e.g. \"No UI change.\")")
  fi
done

closing=$(printf '%s\n' "$body" | grep -v -e '^🤖' -e '^Co-Authored-By:' | awk 'NF { l = $0 } END { print l }')
if ! [[ "$closing" =~ ^Closes\ \#[0-9]+$ ]]; then
  errors+=("the last line must be 'Closes #<issue>' (found: ${closing:-<empty>})")
fi

if (( ${#errors[@]} > 0 )); then
  {
    echo "Pull request body rejected:"
    printf '  - %s\n' "${errors[@]}"
    echo
    echo "  Contract: docs/agents/pull-requests.md, template: .github/pull_request_template.md"
  } >&2
  exit 1
fi
