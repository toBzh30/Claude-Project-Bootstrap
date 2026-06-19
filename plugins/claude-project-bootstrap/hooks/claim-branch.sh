#!/usr/bin/env bash
# PostToolUse(Bash) hook — auto-claim the issue when a convention branch is
# created. Mirror of preflight-branch.sh's target detection, but runs *after*
# the branch exists and declares intent on the board so other sessions/machines
# can see it:
#   - assign the issue to me (idempotent)
#   - flip the project Status to "In Progress"
# Best-effort and silent on failure — a claim that doesn't land must never break
# the workflow. Scoped to the repo the branch was actually created in (honors
# cd / git -C exactly like the preflight guard).
#
# Project coordinates are read from .claude/gh-project.json in the target repo
# (written by the github-project-setup skill). Absent or incomplete config →
# no-op entirely: a repo that hasn't opted into the board workflow is never
# touched, neither the assignment nor the status flip.

set -uo pipefail

done0() { exit 0; }
command -v jq >/dev/null 2>&1 || done0
command -v gh >/dev/null 2>&1 || done0

input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
[ -n "$cmd" ] || done0

cd "${cwd:-${CLAUDE_PROJECT_DIR:-.}}" 2>/dev/null || done0
if [[ "$cmd" =~ (^|\&\&|\;|\|)[[:space:]]*cd[[:space:]]+([^[:space:]\&\;\|]+) ]]; then
  cd "${BASH_REMATCH[2]}" 2>/dev/null || done0
fi
if [[ "$cmd" =~ git[[:space:]]+-C[[:space:]]+([^[:space:]]+) ]]; then
  cd "${BASH_REMATCH[1]}" 2>/dev/null || done0
fi
git rev-parse --git-dir >/dev/null 2>&1 || done0

[[ "$cmd" =~ git[[:space:]]+(checkout[[:space:]]+-[bB]|switch[[:space:]]+-[cC]|branch)[[:space:]]+([^[:space:]]+) ]] || done0
branch="${BASH_REMATCH[2]}"
case "$branch" in -*) done0 ;; esac
[[ "$branch" =~ ^[a-zA-Z]+/([0-9]+)- ]] || done0
num="${BASH_REMATCH[1]}"

# Verify the branch actually came into being (PostToolUse fires even on failed
# commands) — no point claiming an issue for a branch that didn't get created.
git rev-parse --verify --quiet "refs/heads/${branch}" >/dev/null 2>&1 || done0

# --- project coordinates from .claude/gh-project.json -----------------------
# Absent or incomplete config → no-op entirely (both halves gated) so a repo
# that hasn't opted into the board workflow is never touched.
config=".claude/gh-project.json"
[ -f "$config" ] || done0
PROJECT_OWNER=$(jq -r '.project.owner // empty' "$config" 2>/dev/null)
PROJECT_NUMBER=$(jq -r '.project.number // empty' "$config" 2>/dev/null)
PROJECT_ID=$(jq -r '.project.id // empty' "$config" 2>/dev/null)
STATUS_FIELD_ID=$(jq -r '.project.statusFieldId // empty' "$config" 2>/dev/null)
IN_PROGRESS_OPT=$(jq -r '.project.inProgressOptionId // empty' "$config" 2>/dev/null)
[ -n "$PROJECT_OWNER" ] && [ -n "$PROJECT_NUMBER" ] && [ -n "$PROJECT_ID" ] \
  && [ -n "$STATUS_FIELD_ID" ] && [ -n "$IN_PROGRESS_OPT" ] || done0

notes=""

# --- assign the issue to me -------------------------------------------------
if gh issue edit "$num" --add-assignee @me >/dev/null 2>&1; then
  notes="assigned #${num} to @me"
fi

# --- flip project Status → In Progress --------------------------------------
# Find this issue's item in the project, scoped to the current repo so we don't
# grab a same-numbered issue from a sibling repo on a multi-repo board.
repo=$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null || echo "")
item_id=$(gh project item-list "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --format json --limit 500 2>/dev/null \
  | jq -r --argjson n "$num" --arg repo "$repo" \
      '.items[] | select(.content.number == $n and (.content.repository // "" | endswith($repo))) | .id' 2>/dev/null | head -1)

if [ -n "$item_id" ]; then
  if gh project item-edit --id "$item_id" --project-id "$PROJECT_ID" \
        --field-id "$STATUS_FIELD_ID" --single-select-option-id "$IN_PROGRESS_OPT" >/dev/null 2>&1; then
    notes="${notes:+$notes; }Status → In Progress"
  fi
fi

[ -z "$notes" ] && done0
jq -n --arg c "Auto-claim on \`${branch}\`: ${notes}." \
  '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$c}}'
exit 0
