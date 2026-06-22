#!/usr/bin/env bash
# SessionStart hook — report-only cross-repo freshness + in-flight picture.
#
# When you keep several related repos side-by-side under one parent folder, each
# session starts with some behind origin, dirty, or with work already in flight
# on another repo/machine. This surfaces that picture as additionalContext on
# turn 1 so you're not bitten by sync drift (stale handoff docs, "this function
# doesn't exist") or duplicate work.
#
# It REPORTS, it never mutates: it fetches, but never merges/pulls/checks-out.
# Claude or the user decides what to pull.
#
# Opt-in, config-gated via .claude/gh-project.json (in the repo of the session
# cwd). No-op entirely unless `siblings.sync == true`:
#   { "siblings": { "sync": true,        # git-freshness report (git-only, free)
#                   "inflight": true } }  # + cross-repo In-Progress + open PRs
#                                         #   (spends GraphQL budget; own sub-key)
# Single-repo bootstraps never set the flag, so the hook is inert for them.
#
# Siblings root is derived from the session cwd's git toplevel (dirname of it),
# NOT this script's path — the script runs from ${CLAUDE_PLUGIN_ROOT}, outside
# any repo tree. Fails open / quiet: missing git/jq/gh/auth/config → emit
# nothing for the affected section, never block the session.

set -uo pipefail

done0() { exit 0; }
command -v jq >/dev/null 2>&1 || done0
command -v git >/dev/null 2>&1 || done0

input=$(cat)
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')

cd "${cwd:-${CLAUDE_PROJECT_DIR:-.}}" 2>/dev/null || done0
toplevel=$(git rev-parse --show-toplevel 2>/dev/null) || done0
siblings_root=$(dirname "$toplevel")

# --- opt-in gate ------------------------------------------------------------
config=".claude/gh-project.json"
[ -f "$config" ] || done0
[ "$(jq -r '.siblings.sync // false' "$config" 2>/dev/null)" = "true" ] || done0
inflight=$(jq -r '.siblings.inflight // false' "$config" 2>/dev/null)

# A best-effort fetch that can't hang the session: cap it if a timeout tool
# exists, otherwise just fetch and rely on git's own backstops.
fetch() {
  if command -v timeout >/dev/null 2>&1; then timeout 10 git -C "$1" fetch --quiet 2>/dev/null
  elif command -v gtimeout >/dev/null 2>&1; then gtimeout 10 git -C "$1" fetch --quiet 2>/dev/null
  else git -C "$1" fetch --quiet 2>/dev/null; fi
}

# --- git-freshness section --------------------------------------------------
fresh_lines=""
found=0
while IFS= read -r gitdir; do
  [ -n "$gitdir" ] || continue
  d=$(dirname "$gitdir")
  git -C "$d" rev-parse --git-dir >/dev/null 2>&1 || continue
  found=$((found + 1))
  name=$(basename "$d")
  fetch "$d"

  def=$(git -C "$d" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')
  [ -n "$def" ] || def=main
  cur=$(git -C "$d" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")

  flags=""
  [ -n "$(git -C "$d" status --porcelain 2>/dev/null)" ] && flags="DIRTY"
  if [ -n "$cur" ] && [ "$cur" != "$def" ]; then
    flags="${flags:+$flags, }on ${cur}"
  fi
  if git -C "$d" rev-parse --verify --quiet "origin/${def}" >/dev/null 2>&1; then
    behind=$(git -C "$d" rev-list --count "HEAD..origin/${def}" 2>/dev/null || echo 0)
    ahead=$(git -C "$d" rev-list --count "origin/${def}..HEAD" 2>/dev/null || echo 0)
    [ "${behind:-0}" -gt 0 ] && flags="${flags:+$flags, }behind ${behind}"
    [ "${ahead:-0}" -gt 0 ] && flags="${flags:+$flags, }ahead ${ahead}"
  fi
  [ -n "$flags" ] || flags="clean & current"
  fresh_lines="${fresh_lines}- ${name}: ${flags}"$'\n'
done < <(find "$siblings_root" -maxdepth 2 -name .git -type d 2>/dev/null | sort)

# Nothing to report on (no siblings discovered) → stay silent entirely.
[ "$found" -gt 0 ] || done0

out="Sibling repos (under ${siblings_root}):"$'\n'"${fresh_lines}"

# --- in-flight section (opt-in sub-key; spends GraphQL budget) --------------
if [ "$inflight" = "true" ] && command -v gh >/dev/null 2>&1; then
  owner=$(jq -r '.project.owner // empty' "$config" 2>/dev/null)
  number=$(jq -r '.project.number // empty' "$config" 2>/dev/null)

  # Self-limiting guard: yield the GraphQL budget when low rather than draining
  # it and blocking later gh issue/PR creation. rate_limit itself is free.
  remaining=$(gh api rate_limit --jq '.resources.graphql.remaining' 2>/dev/null || echo "")
  if [ -n "$owner" ] && [ -n "$number" ] && [ -n "$remaining" ] && [ "$remaining" -ge 100 ]; then
    inprog=$(gh project item-list "$number" --owner "$owner" --format json --limit 200 2>/dev/null \
      | jq -r '.items[] | select(.status == "In Progress")
               | "- \(.content.repository // "?")#\(.content.number) \"\(.content.title)\"\((.assignees // "") | if . == "" then "" else " (\(.))" end)"' 2>/dev/null || echo "")
    if [ -n "$inprog" ]; then
      out="${out}"$'\n'"In progress across board:"$'\n'"${inprog}"$'\n'
    fi
  elif [ -n "$remaining" ] && [ "$remaining" -lt 100 ]; then
    out="${out}"$'\n'"(board scan skipped — GraphQL budget low: ${remaining} remaining)"$'\n'
  fi

  # Open PRs in the current repo (cheap; runs regardless of the budget guard).
  prs=$(gh pr list --state open --json number,headRefName,author \
          --jq '.[] | "- #\(.number) \(.headRefName) (@\(.author.login))"' 2>/dev/null || echo "")
  if [ -n "$prs" ]; then
    out="${out}"$'\n'"Open PRs here:"$'\n'"${prs}"$'\n'
  fi
fi

jq -n --arg c "$out" \
  '{hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$c}}'
exit 0
