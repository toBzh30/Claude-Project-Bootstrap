#!/usr/bin/env bash
# PreToolUse(Bash) hook — collision guard for branch creation.
#
# When a Bash command creates a branch following the repo convention
# (<type>/<N>-<slug>), check three GitHub-native signals for issue N *in this
# repo* before letting the branch be created:
#   1. an unmerged remote branch matching */<N>-* on origin
#   2. an open PR whose head branch matches */<N>-*
#   3. the issue assigned to someone (and not me)
# Any signal NOT attributable to me → ask the user to confirm (permissionDecision
# "ask"); a clean check or one that's only my own work → allow silently.
#
# Issue numbers are per-repo, so every check is scoped to the current repo +
# its origin — a */<N>-* branch in a sibling repo is a different issue N and is
# deliberately ignored. Fails open: any missing tool / auth / network error
# allows the command rather than blocking the workflow.

set -uo pipefail

allow() { exit 0; }  # default-allow: emit nothing, exit 0

# Tooling we depend on; without it we can't check, so fail open.
command -v jq >/dev/null 2>&1 || allow
command -v gh >/dev/null 2>&1 || allow

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
[ -n "$cmd" ] || allow

# Anchor at the session cwd first so any relative target resolves against it.
cd "${cwd:-${CLAUDE_PROJECT_DIR:-.}}" 2>/dev/null || allow

# Follow the command to the repo it actually operates on, not the session cwd.
# Cross-repo branch creation takes one of two shapes — honor both so the checks
# below run against the *target* repo's origin/issues/PRs:
#   cd ../sibling-repo && git checkout -b feat/52-x   → target = ../sibling-repo
#   git -C ../sibling-repo checkout -b feat/52-x      → target = ../sibling-repo
# `git -C` wins if both appear (it's what git actually obeys).
if [[ "$cmd" =~ (^|\&\&|\;|\|)[[:space:]]*cd[[:space:]]+([^[:space:]\&\;\|]+) ]]; then
  cd "${BASH_REMATCH[2]}" 2>/dev/null || allow
fi
if [[ "$cmd" =~ git[[:space:]]+-C[[:space:]]+([^[:space:]]+) ]]; then
  cd "${BASH_REMATCH[1]}" 2>/dev/null || allow
fi
# Bail out (allow) if we didn't land in a git repo — nothing to check against.
git rev-parse --git-dir >/dev/null 2>&1 || allow

# Is this a branch-creating command? Match checkout -b/-B, switch -c/-C, branch.
[[ "$cmd" =~ git[[:space:]]+(checkout[[:space:]]+-[bB]|switch[[:space:]]+-[cC]|branch)[[:space:]]+([^[:space:]]+) ]] || allow
branch="${BASH_REMATCH[2]}"
# `git branch -d/-D/-m/-r/...` captures a flag, not a new branch — skip those.
case "$branch" in -*) allow ;; esac

# Pull the issue number out of the <type>/<N>-<slug> convention.
[[ "$branch" =~ ^[a-zA-Z]+/([0-9]+)- ]] || allow
num="${BASH_REMATCH[1]}"

me_login=$(gh api user --jq '.login' 2>/dev/null || echo "")
me_email=$(git config user.email 2>/dev/null || echo "")

reasons=""

# --- 1. remote branch on origin matching */<N>-* ---------------------------
git fetch --quiet origin 2>/dev/null
while IFS=$'\t' read -r sha ref; do
  [ -n "$ref" ] || continue
  rbranch="${ref#refs/heads/}"
  # author of the branch tip; if it's me, treat as my own resumed work.
  author=$(git show -s --format='%ae' "$sha" 2>/dev/null || echo "")
  if [ -n "$me_email" ] && [ "$author" = "$me_email" ]; then
    continue
  fi
  reasons="${reasons}- remote branch \`${rbranch}\` already exists on origin (tip by ${author:-unknown})"$'\n'
done < <(git ls-remote --heads origin 2>/dev/null | grep -E "refs/heads/[^[:space:]]*/${num}-" || true)

# --- 2. open PR whose head branch matches */<N>-* --------------------------
prs=$(gh pr list --state open --json number,title,headRefName,author \
        --jq '.[] | select(.headRefName | test("/'"$num"'-")) | "\(.number)\t\(.author.login)\t\(.title)"' 2>/dev/null || true)
while IFS=$'\t' read -r pnum pauthor ptitle; do
  [ -n "$pnum" ] || continue
  [ "$pauthor" = "$me_login" ] && continue
  reasons="${reasons}- open PR #${pnum} (\"${ptitle}\") by @${pauthor} targets this issue"$'\n'
done <<< "$prs"

# --- 3. issue assigned to someone who isn't me -----------------------------
assignees=$(gh issue view "$num" --json assignees --jq '.assignees[].login' 2>/dev/null || true)
if [ -n "$assignees" ]; then
  others=""
  while IFS= read -r a; do
    [ -n "$a" ] || continue
    [ "$a" = "$me_login" ] && continue
    others="${others}@${a} "
  done <<< "$assignees"
  [ -n "$others" ] && reasons="${reasons}- issue #${num} is assigned to ${others}"$'\n'
fi

# No non-self signal → let it through.
[ -z "$reasons" ] && allow

# Collision: ask the user to confirm rather than hard-blocking.
msg="Possible duplicate work on issue #${num} before creating \`${branch}\`:"$'\n'"${reasons}"$'\n'"Create the branch anyway?"
jq -n --arg r "$msg" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:$r}}'
exit 0
