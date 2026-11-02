# Guardrail paths

The files that check or limit what agents and pull requests can do: hooks, CI, check scripts, lint config and the registries those scripts read. Agents edit them too (the `improver` and `implementer` agents, [workflow](workflow.md)), and a small edit can switch a guardrail off without a failing test. A pull request that touches one of them says so on the **Guardrails touched:** line under Merge Danger ([pull requests](pull-requests.md)), so the reviewer sees what got stricter or looser.

CI (`pr-body.yml`, `scripts/check-guardrail-paths.sh`) fails a pull request that changes a file matching a glob below when its body has no **Guardrails touched:** line, or the line says "none". Dependabot pull requests are skipped, they only bump pinned action versions and Swift package versions.

A glob is a shell `case` pattern on the repo-relative path, `*` also matches `/`. Whoever adds a hook, a workflow, a check script or a registry adds its glob here in the same pull request.

Paths: `.claude/settings.json` `.claude/hooks/*` `.claude/agents/*` `.claude/skills/*` `.githooks/*` `.github/*` `scripts/check-*` `scripts/test-*` `Makefile` `.swiftformat` `docs/agents/critical-paths.md` `docs/agents/guardrail-paths.md`

The repository settings and the ruleset are guardrails too, but they live on GitHub, not in the diff. A change there is recorded in the Enforcement table of [git](git.md) by its own pull request.
