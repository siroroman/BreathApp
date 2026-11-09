#!/usr/bin/env bash
# Fails when what every session loads grows past its budget (rules: docs/agents/rules-enforcement.md, docs/agents/tokens.md):
#   - CLAUDE.md is over 3000 bytes
#   - the `description:` of a skill (.claude/skills/*/SKILL.md) or an agent (.claude/agents/*.md) is over 700 characters
#     (every description is in the catalog of every session, the body is read only when the skill or agent runs)
#   scripts/check-context-size.sh [repo root]    root defaults to the repository
# Needs ruby (ships with macOS and the ubuntu runners).
set -euo pipefail

root=${1:-$(git rev-parse --show-toplevel)}
[[ -d "$root" ]] || { echo "check-context-size: no such directory '$root'" >&2; exit 1; }

ruby -E UTF-8 -e '
  Dir.chdir(ARGV[0])
  bad = []
  claude_max = 3000
  desc_max = 700

  if File.file?("CLAUDE.md") && File.size("CLAUDE.md") > claude_max
    bad << "CLAUDE.md is #{File.size("CLAUDE.md")} bytes, the budget is #{claude_max}: move detail into docs/agents/ and link it"
  end

  (Dir[".claude/skills/*/SKILL.md"] + Dir[".claude/agents/*.md"]).sort.each do |f|
    front = File.read(f)[/\A---\n(.*?)\n---/m, 1].to_s
    desc = front[/^description:[ \t]*(.*)$/, 1].to_s
    bad << "#{f}: description is #{desc.length} characters, the budget is #{desc_max}" if desc.length > desc_max
  end

  unless bad.empty?
    warn bad.map { |b| "  - #{b}" }
    warn
    warn "  Rules: docs/agents/tokens.md, docs/agents/rules-enforcement.md."
    exit 1
  end
' "$root"
echo "CLAUDE.md and the skill and agent descriptions are within their budgets."
