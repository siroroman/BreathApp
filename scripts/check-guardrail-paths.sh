#!/usr/bin/env bash
# Fails when a pull request changes a guardrail without saying so in its body (rules: docs/agents/guardrail-paths.md).
#   PR_BODY="..." scripts/check-guardrail-paths.sh [base]    base defaults to origin/main
#
# Passes when no changed file matches a glob of the registry (on the base or on HEAD), or when the PR body has a
# `**Guardrails touched:**` line with text other than "none" (HTML comments do not count).
set -euo pipefail

base=${1:-origin/main}
root=$(git rev-parse --show-toplevel)
cd "$root"
git rev-parse --verify -q "$base^{commit}" >/dev/null || { echo "check-guardrail-paths: unknown base '$base'" >&2; exit 1; }
range="$base...HEAD"
registry=docs/agents/guardrail-paths.md

changed=$(git diff --name-only --no-renames "$range")
# Globs from the registry on the base and on HEAD, so a pull request that drops a glob is still checked against it.
globs=$({ git show "$base:$registry" 2>/dev/null || true; cat "$registry" 2>/dev/null || true; } |
  awk '/^Paths:/ { s = $0; while (match(s, /`[^`]+`/)) { print substr(s, RSTART + 1, RLENGTH - 2); s = substr(s, RSTART + RLENGTH) } }' | sort -u)

hits=()
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  while IFS= read -r glob; do
    # shellcheck disable=SC2254
    case "$f" in $glob) hits+=("$f"); break ;; esac
  done <<<"$globs"
done <<<"$changed"

[[ ${#hits[@]} -eq 0 ]] && { echo "No guardrail path changed."; exit 0; }

# GitHub's web editor sends CRLF. Drop \r and HTML comments, then take the text after the label.
said=$(printf '%s\n' "${PR_BODY:-}" | tr -d '\r' | perl -0pe 's/<!--.*?-->//gs' |
  awk 'sub(/^\*\*Guardrails touched:\*\*[[:space:]]*/, "") { print; exit }')
if [[ -n "${said//[[:space:]]/}" ]] && ! [[ "$said" =~ ^[Nn]one\.?[[:space:]]*$ ]]; then
  echo "Guardrail paths changed, the PR body names them."
  exit 0
fi

{
  echo "Guardrail paths changed, but the PR body does not say what changes:"
  printf '  - %s\n' "${hits[@]}"
  echo
  echo "  Add '**Guardrails touched:** ...' under Merge Danger: which guardrail, stricter or looser, and why."
  echo "  Rules: docs/agents/guardrail-paths.md, docs/agents/pull-requests.md (Merge Danger)"
} >&2
exit 1
