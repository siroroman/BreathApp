#!/usr/bin/env bash
# Fails when the installed swiftformat or swiftlint is not the version pinned in tools.env (rules: docs/agents/commands.md, Tools):
#   scripts/check-tools.sh [repo root]    root defaults to the repository
#
# Another version formats and lints differently, so a local `make lint` would not match CI. xcodegen is only recorded:
# a different version prints a warning. The `.tools/bin` of the repo (scripts/install-tools.sh) comes before PATH.
set -euo pipefail

root=${1:-$(git rev-parse --show-toplevel)}
[[ -d "$root" ]] || { echo "check-tools: no such directory '$root'" >&2; exit 1; }
cd "$root"

[[ -f tools.env ]] || { echo "check-tools: tools.env does not exist in $root" >&2; exit 1; }
PATH="$root/.tools/bin:$PATH"

# pinned <KEY>: the value of KEY in tools.env, empty when it is missing.
pinned() { sed -nE "s/^$1=([^[:space:]#]+).*/\\1/p" tools.env | head -1; }

# installed <tool>: the first x.y or x.y.z that `<tool> --version` prints, empty when the tool is not installed.
installed() {
  command -v "$1" >/dev/null || return 0
  "$1" --version 2>&1 | grep -Eo '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1 || true
}

bad=()
for tool in swiftformat swiftlint; do
  key=$(printf '%s_VERSION' "$tool" | tr '[:lower:]' '[:upper:]')
  want=$(pinned "$key")
  if [[ -z "$want" ]]; then
    bad+=("tools.env has no $key")
    continue
  fi
  have=$(installed "$tool")
  if [[ -z "$have" ]]; then
    bad+=("$tool is not installed, tools.env pins $want")
  elif [[ "$have" != "$want" ]]; then
    bad+=("$tool $have is installed, tools.env pins $want")
  fi
done

want=$(pinned XCODEGEN_VERSION)
have=$(installed xcodegen)
if [[ -n "$want" && -n "$have" && "$have" != "$want" ]]; then
  echo "warning: xcodegen $have is installed, tools.env records $want" >&2
fi

if [[ ${#bad[@]} -gt 0 ]]; then
  {
    echo "The tools do not match the versions pinned in tools.env:"
    printf '  - %s\n' "${bad[@]}"
    echo
    echo "  Fix: scripts/install-tools.sh   (installs the pinned versions into .tools/bin, which make puts first on PATH)"
    echo "  Why: another version formats and lints differently, so make lint would not match CI. Details: docs/agents/commands.md (Tools)"
  } >&2
  exit 1
fi
echo "Tools match tools.env."
