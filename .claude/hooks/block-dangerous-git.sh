#!/bin/bash
# PreToolUse hook for Bash: blocks destructive git commands.
# `git push origin <branch>` is allowed so agents can open pull requests,
# see docs/agents/git.md ("Rules for agents").

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

DANGEROUS_PATTERNS=(
  "git push.*(--force|-f( |$)|--delete| \+|:[^ ]*$)"
  "git push.*( |:)(main|master)( |$)"
  "git reset --hard"
  "git clean -[a-z]*f"
  "git branch -D"
  "git checkout \.( |$)"
  "git restore \.( |$)"
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    echo "BLOCKED: '$COMMAND' matches dangerous pattern '$pattern'. The user has prevented you from doing this." >&2
    exit 2
  fi
done

# A bare `git push` pushes the current branch, so refuse it on main.
if echo "$COMMAND" | grep -qE "git push( |$)"; then
  BRANCH=$(git -C "${CLAUDE_PROJECT_DIR:-.}" branch --show-current 2>/dev/null)
  if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
    echo "BLOCKED: '$COMMAND' would push $BRANCH. Work on a feature branch and open a pull request." >&2
    exit 2
  fi
fi

exit 0
