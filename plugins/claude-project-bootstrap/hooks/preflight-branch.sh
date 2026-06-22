#!/usr/bin/env bash
# PreToolUse(Bash) hook — branch-creation guard. Two ask-only checks:
#
# A. Freshness gate (ALL branch creation): if you're forking *from* the default
#    branch and local default is behind origin, ask before branching off a stale
#    base. Skipped on a feature branch — being behind default is expected there.
# B. Collision guard (only <type>/<N>-<slug> convention branches): three
#    GitHub-native signals for issue N *in this repo* —
#      1. an unmerged remote branch matching */<N>-* on origin
#      2. an open PR whose head branch matches */<N>-*
#      3. the issue assigned to someone (and not me)
#    Any signal NOT attributable to me → ask.
#
# Either check firing → ask the user to confirm (permissionDecision "ask");
# nothing firing → allow silently. Issue numbers are per-repo, so the collision
# checks are scoped to the current repo + its origin. Fails open: any missing
# tool / auth / network error allows the command rather than blocking.

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

# Both checks below accumulate into $reasons; one "ask" covers whatever fired.
reasons=""

# --- Freshness gate: forking from a stale base (runs on ALL branch creation) ---
# Integration branch: origin/HEAD → gh default → "main". Fail-open to "main".
def=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')
[ -n "$def" ] || def=$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name' 2>/dev/null || echo "")
[ -n "$def" ] || def=main
cur=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
git fetch --quiet origin 2>/dev/null   # single fetch; the collision check below reuses it
# Only fire when forking *from* the default branch — a feature-off-feature branch
# is expected to sit behind the default, and isn't stale-forking.
if [ -n "$cur" ] && [ "$cur" = "$def" ]; then
  behind=$(git rev-list --count "HEAD..origin/${def}" 2>/dev/null || echo 0)
  if [ "${behind:-0}" -gt 0 ]; then
    reasons="${reasons}- local \`${def}\` is ${behind} commit(s) behind \`origin/${def}\` — pull first so \`${branch}\` forks from current ${def}"$'\n'
  fi
fi

# --- Collision checks (only for <type>/<N>-<slug> convention branches) ---------
if [[ "$branch" =~ ^[a-zA-Z]+/([0-9]+)- ]]; then
  num="${BASH_REMATCH[1]}"
  me_login=$(gh api user --jq '.login' 2>/dev/null || echo "")
  me_email=$(git config user.email 2>/dev/null || echo "")

  # 1. remote branch on origin matching */<N>-*
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

  # 2. open PR whose head branch matches */<N>-*
  prs=$(gh pr list --state open --json number,title,headRefName,author \
          --jq '.[] | select(.headRefName | test("/'"$num"'-")) | "\(.number)\t\(.author.login)\t\(.title)"' 2>/dev/null || true)
  while IFS=$'\t' read -r pnum pauthor ptitle; do
    [ -n "$pnum" ] || continue
    [ "$pauthor" = "$me_login" ] && continue
    reasons="${reasons}- open PR #${pnum} (\"${ptitle}\") by @${pauthor} targets this issue"$'\n'
  done <<< "$prs"

  # 3. issue assigned to someone who isn't me
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
fi

# Nothing fired → let it through.
[ -z "$reasons" ] && allow

# Stale base and/or duplicate-work signal — ask, don't hard-block.
msg="Before creating \`${branch}\`:"$'\n'"${reasons}"$'\n'"Proceed anyway?"
jq -n --arg r "$msg" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:$r}}'
exit 0
