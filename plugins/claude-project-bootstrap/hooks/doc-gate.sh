#!/usr/bin/env bash
# PreToolUse(Bash) hook — documentation gate on the shipping command.
#
# Fires when a Bash command ships a branch (`gh pr create` or `gh pr merge`).
# Compares the branch's diff against the repo's default branch:
#   - if it changed CODE but touched NO docs, and the command isn't already
#     opted out, DENY the command (permissionDecision "deny") with a reason
#     directed at Claude: check whether a doc update is needed, update it in
#     this branch (working-agreements phase 6), then re-run. The user is never
#     prompted — Claude actions the gate itself and re-ships.
#   - any other command, or a diff that already includes docs, allows silently.
#
# Enforces the doc-reconcile rule via the harness instead of relying on Claude's
# discipline. It is a prompt, not proof: the diff heuristic (code changed, zero
# docs) cannot tell whether a *specific* doc was needed.
#
# Fails open: any missing tool / auth / git / parse error ALLOWS the command
# rather than blocking the workflow.

set -uo pipefail

allow() { exit 0; }  # default-allow: emit nothing, exit 0

command -v jq  >/dev/null 2>&1 || allow
command -v git >/dev/null 2>&1 || allow

# PreToolUse passes the tool call as JSON on stdin.
payload=$(cat)
cmd=$(printf '%s' "$payload" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -n "$cmd" ] || allow

# Only gate the shipping commands.
printf '%s' "$cmd" | grep -qE 'gh[[:space:]]+pr[[:space:]]+(create|merge)' || allow

# Author opt-out: the command / PR body already declares no doc impact.
printf '%s' "$cmd" | grep -qiE 'no docs?( needed)?' && allow

# Default branch (origin/HEAD), fall back to main.
base=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')
[ -n "$base" ] || base=main

# Files this branch changes vs the merge-base with the default branch.
files=$(git diff --name-only "origin/$base...HEAD" 2>/dev/null) || allow
[ -n "$files" ] || allow

# Source files across common languages, excluding tests / mocks / vendored deps.
code=$(printf '%s\n' "$files" \
  | grep -E '\.(go|rs|py|rb|java|kt|kts|swift|scala|c|cc|cpp|cxx|h|hh|hpp|cs|php|ex|exs|clj|cljs|m|mm|ts|tsx|js|jsx|mjs|cjs|vue|svelte|sql)$' \
  | grep -vE '(_test\.|\.test\.|\.spec\.|(^|/)(mocks?|vendor|node_modules|dist|build|target)/)' || true)
docs=$(printf '%s\n' "$files" | grep -E '(^|/)(CLAUDE|ARCHITECTURE|README)\.md$|^\.claude/rules/.*\.md$|^docs/' || true)

# Code changed, no docs in the branch → deny so Claude actions it (never the user).
if [ -n "$code" ] && [ -z "$docs" ]; then
  reason="This branch changes code but touches no docs. Before shipping, CHECK whether these \
changes need a doc update (CLAUDE.md / ARCHITECTURE.md / .claude/rules/decisions.md) per \
working-agreements phase 6 — if so, update the relevant doc in this branch and re-run. If you \
determine there is genuinely no doc impact, re-run with 'no docs needed' in the command or PR \
body. This gate is for you (Claude) to action — do not ask the user to decide."
  jq -nc --arg r "$reason" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $r
    }
  }'
  exit 0
fi

allow
