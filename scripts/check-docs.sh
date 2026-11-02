#!/usr/bin/env bash
# Fails when CLAUDE.md or docs/agents/*.md point at something that does not exist (rules: docs/agents/rules-enforcement.md):
#   - a relative markdown link whose file is missing
#   - a backticked path (docs/ only with an extension or a trailing slash) under scripts/, docs/, App/, BreathnestKit/, .githooks/, .claude/ or .github/ that is missing
#     (a word with a glob or placeholder character * ? < > { } [ ] is not a path)
#   - a `make <target>` that is not in the Makefile, in a backtick span or at the start of a code block line
#   - a skill directory in .claude/skills/ that docs/agents/skills.md does not name, or a skill in its two "vendored" and
#     "written for this repo" tables without a directory
#   scripts/check-docs.sh [repo root]    root defaults to the repository
# Needs ruby (ships with macOS and the ubuntu runners).
set -euo pipefail

root=${1:-$(git rev-parse --show-toplevel)}
[[ -d "$root" ]] || { echo "check-docs: no such directory '$root'" >&2; exit 1; }

ruby -E UTF-8 -e '
  root = ARGV[0]
  Dir.chdir(root)
  docs = ["CLAUDE.md"].select { |f| File.file?(f) } + Dir["docs/agents/*.md"].sort
  bad = []

  makefile = File.file?("Makefile") ? File.read("Makefile") : ""
  targets = makefile.scan(/^([a-z][a-z0-9-]*):/).flatten

  path_prefix = %r{\A(scripts|docs|App|BreathnestKit|\.githooks|\.claude|\.github)/}
  glob_chars = /[*?<>{}\[\]]/

  check_make = lambda do |file, words|
    words.shift while words.first&.start_with?("-")
    words.each do |w|
      break unless w =~ /\A[a-z][a-z0-9-]*\z/
      bad << "#{file}: `make #{w}` is not a target of the Makefile" unless targets.include?(w)
    end
  end

  docs.each do |file|
    text = File.read(file)
    dir = File.dirname(file)

    text.scan(/\]\(([^)\s]+)\)/).flatten.each do |link|
      next if link =~ %r{\A([a-z][a-z0-9+.-]*:|#)}i
      target = link.sub(/#.*\z/, "")
      next if target.empty?
      bad << "#{file}: link to #{link} does not resolve" unless File.exist?(File.join(dir, target))
    end

    in_fence = false
    text.each_line do |line|
      if line.start_with?("```")
        in_fence = !in_fence
        next
      end
      if in_fence
        words = line.strip.split(/\s+/)
        check_make.call(file, words[1..]) if words.first == "make"
        next
      end
      line.scan(/`([^`]+)`/).flatten.each do |span|
        words = span.strip.split(/\s+/)
        first = words.first.to_s.sub(/[.,;:]+\z/, "")
        # A docs/ word without an extension or a trailing slash is a branch name such as docs/git-conventions.
        branch_like = first.start_with?("docs/") && first !~ %r{(/\z|\.[a-z]+\z)}
        if first =~ path_prefix && first !~ glob_chars && !branch_like
          bad << "#{file}: `#{first}` does not exist" unless File.exist?(first)
        end
        check_make.call(file, words[1..]) if words.first == "make"
      end
    end
  end

  skills_doc = "docs/agents/skills.md"
  if File.file?(skills_doc)
    skills_text = File.read(skills_doc)
    dirs = Dir[".claude/skills/*"].select { |d| File.directory?(d) }.map { |d| File.basename(d) }.sort
    dirs.each do |d|
      bad << "#{skills_doc}: skill `#{d}` is in .claude/skills/ but not named in the doc" unless skills_text.include?("`#{d}`")
    end
    section = skills_text[/^## Skills the workflow needs.*?(?=^## Skills that stay personal)/m].to_s
    section.scan(/^\| `([a-z0-9-]+)`/).flatten.each do |name|
      bad << "#{skills_doc}: skill `#{name}` is in a table of skills kept in the repo but has no .claude/skills/#{name}" unless dirs.include?(name)
    end
  end

  unless bad.empty?
    warn bad.uniq.map { |b| "  - #{b}" }
    warn
    warn "  Fix the doc, or add what it names. Rules: docs/agents/rules-enforcement.md, docs/agents/skills.md."
    exit 1
  end
' "$root"
echo "Docs only name files, make targets and skills that exist."
