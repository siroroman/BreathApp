#!/usr/bin/env bash
# Installs the swiftformat and swiftlint pinned in tools.env (rules: docs/agents/commands.md, Tools):
#   scripts/install-tools.sh
#
# Homebrew installs only the newest version, so these two do not come from the Brewfile. The release zip is downloaded
# from GitHub, checked against the SHA256 in tools.env and kept in a cache shared by all worktrees
# ($BREATHNEST_TOOLS_CACHE, default ~/.cache/breathnest/tools). .tools/bin of this checkout links to it, and the
# Makefile puts .tools/bin first on PATH. Safe to run again: a tool that already has the pinned version is skipped.
# The binaries are macOS ones: the Kit tests and script checks on Linux do not need them.
set -euo pipefail

[[ "$(uname -s)" == Darwin ]] || { echo "install-tools: the pinned swiftformat and swiftlint are macOS binaries" >&2; exit 1; }

root=$(git rev-parse --show-toplevel)
cd "$root"
[[ -f tools.env ]] || { echo "install-tools: tools.env does not exist in $root" >&2; exit 1; }
# shellcheck disable=SC1091
source tools.env

cache=${BREATHNEST_TOOLS_CACHE:-$HOME/.cache/breathnest/tools}
mkdir -p "$cache" .tools/bin
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

# install <tool> <version> <sha256> <release url> <zip name> <binary name in the zip>
install() {
  local tool=$1 version=$2 sha=$3 url=$4 zip=$5 member=$6
  local kept="$cache/$tool-$version"
  if [[ -z "$version" || -z "$sha" ]]; then
    echo "install-tools: tools.env needs the version and the SHA256 of $tool" >&2
    exit 1
  fi
  if [[ ! -x "$kept" ]]; then
    echo "downloading $tool $version"
    curl -fsSL "$url" -o "$tmp/$zip"
    local got
    got=$(shasum -a 256 "$tmp/$zip" | awk '{print $1}')
    if [[ "$got" != "$sha" ]]; then
      echo "install-tools: $zip of $tool $version has SHA256 $got, tools.env says $sha. Nothing was installed." >&2
      exit 1
    fi
    unzip -q "$tmp/$zip" "$member" -d "$tmp/$tool"
    chmod +x "$tmp/$tool/$member"
    mv "$tmp/$tool/$member" "$kept"
  fi
  ln -sf "$kept" ".tools/bin/$tool"
  echo "$tool $version: .tools/bin/$tool"
}

install swiftformat "$SWIFTFORMAT_VERSION" "${SWIFTFORMAT_SHA256:-}" \
  "https://github.com/nicklockwood/SwiftFormat/releases/download/$SWIFTFORMAT_VERSION/swiftformat.zip" swiftformat.zip swiftformat
install swiftlint "$SWIFTLINT_VERSION" "${SWIFTLINT_SHA256:-}" \
  "https://github.com/realm/SwiftLint/releases/download/$SWIFTLINT_VERSION/portable_swiftlint.zip" portable_swiftlint.zip swiftlint

scripts/check-tools.sh
