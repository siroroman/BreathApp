#!/usr/bin/env bash
# Fails when the Kit stops being UI free or a dependency sneaks in (rules: docs/agents/ios.md, Conventions):
#   - a file in BreathnestKit/Sources imports anything but Foundation, Synchronization or Swift
#   - BreathnestKit/Package.swift declares a dependency (`.package(`)
#   - project.yml lists a package other than the local BreathnestKit
#   scripts/check-architecture.sh [repo root]    root defaults to the repository
# Pure bash and awk, so it runs on the ubuntu `Script tests` job too.
set -euo pipefail

root=${1:-$(git rev-parse --show-toplevel)}
[[ -d "$root" ]] || { echo "check-architecture: no such directory '$root'" >&2; exit 1; }
cd "$root"

sources=BreathnestKit/Sources
package=BreathnestKit/Package.swift
project=project.yml
allowed_imports="Foundation Synchronization Swift"

bad=()
[[ -d "$sources" ]] || bad+=("$sources does not exist")
[[ -f "$package" ]] || bad+=("$package does not exist")
[[ -f "$project" ]] || bad+=("$project does not exist")

if [[ -d "$sources" ]]; then
  while IFS= read -r file; do
    # `public import Foundation`, `@testable import X`, `import struct Foundation.URL`: the module is the first
    # word of the path after `import` (and after an optional declaration kind). Lines in a `//` comment are skipped.
    while IFS= read -r module; do
      [[ -n "$module" ]] || continue
      case " $allowed_imports " in
        *" $module "*) ;;
        *) bad+=("$file imports $module") ;;
      esac
    done < <(sed -nE 's://.*$::; s/^[[:space:]]*(@[A-Za-z]+[[:space:]]+)*((public|internal|package|private|fileprivate)[[:space:]]+)?import[[:space:]]+((typealias|struct|class|enum|protocol|let|var|func)[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*).*/\6/p' "$file")
  done < <(find "$sources" -name '*.swift' | sort)
fi

if [[ -f "$package" ]] && grep -qE '\.package\(' "$package"; then
  bad+=("$package declares a dependency")
fi

if [[ -f "$project" ]]; then
  while IFS= read -r name; do
    [[ "$name" == "BreathnestKit" ]] || bad+=("$project lists the package $name")
  done < <(awk '
    /^packages:/ { in_packages = 1; next }
    in_packages && /^[^[:space:]#]/ { in_packages = 0 }
    in_packages && /^  [A-Za-z0-9_.-]+:/ { name = $1; sub(/:$/, "", name); print name }
  ' "$project")
fi

if [[ ${#bad[@]} -gt 0 ]]; then
  printf '  - %s\n' "${bad[@]}" >&2
  echo >&2
  echo "  The Kit imports only Foundation, Synchronization and Swift, so it builds on every platform and in the" >&2
  echo "  tests. UIKit, SwiftUI, CoreHaptics and the like belong in App/Breathnest. A third-party dependency needs" >&2
  echo "  a decision recorded as an ADR first, then it is added to this script. Rules: docs/agents/ios.md, Conventions." >&2
  exit 1
fi
echo "The Kit imports only Foundation, Synchronization and Swift, and no third-party package is declared."
