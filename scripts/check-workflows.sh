#!/usr/bin/env bash
# Fails when a workflow can run longer or with more rights than docs/agents/git.md (Enforcement) allows:
# top-level `permissions: contents: read` and a numeric `timeout-minutes` on every job.
#   scripts/check-workflows.sh [dir]    dir defaults to .github/workflows
# Needs ruby (ships with macOS and the ubuntu runners), only for its YAML parser.
set -euo pipefail

dir=${1:-$(git rev-parse --show-toplevel)/.github/workflows}
shopt -s nullglob
files=("$dir"/*.yml "$dir"/*.yaml)
[[ ${#files[@]} -gt 0 ]] || { echo "check-workflows: no workflow files in $dir" >&2; exit 1; }

ruby -ryaml -e '
  bad = []
  ARGV.each do |f|
    begin
      doc = YAML.load_file(f)
    rescue StandardError => e
      bad << "#{f}: not valid YAML (#{e.message.lines.first.strip})"
      next
    end
    unless doc.is_a?(Hash)
      bad << "#{f}: not a workflow"
      next
    end
    bad << "#{f}: top-level permissions must be exactly `contents: read`" unless doc["permissions"] == { "contents" => "read" }
    jobs = doc["jobs"]
    if !jobs.is_a?(Hash) || jobs.empty?
      bad << "#{f}: no jobs"
      next
    end
    jobs.each do |name, job|
      t = job.is_a?(Hash) ? job["timeout-minutes"] : nil
      bad << "#{f}: job `#{name}` needs a numeric `timeout-minutes`" unless t.is_a?(Integer) && t.positive?
    end
  end
  unless bad.empty?
    warn bad.map { |b| "  - #{b}" }
    warn
    warn "  Every workflow sets `permissions: contents: read` and a `timeout-minutes` on each job"
    warn "  (5 for ubuntu jobs, 10 for Kit tests, 30 for the iOS build). Rules: docs/agents/git.md, Enforcement table."
    exit 1
  end
' "${files[@]}"
echo "Workflows set read-only permissions and a timeout on every job."
