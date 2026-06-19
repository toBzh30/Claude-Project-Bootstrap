---
name: checkpoint
description: Generate a session handover document and save it to disk so the session can be resumed after /clear. Use when wrapping up a session, before a context reset, or when the user asks to checkpoint / save progress for a fresh session.
disable-model-invocation: true
---

Capture the current session as a resumable handover so a fresh session (after `/clear`) can pick up cold without undoing work.

## Steps

1. Run `printf '%s-%s' "$(date +%Y-%m-%dT%H%M)" "$(openssl rand -hex 3)"` to get a timestamp with a random suffix (e.g. `2026-04-22T1717-a3f9c1`) for the filename.

2. Generate a summary covering these sections — keep the whole document under 400 words:
   - **Project**: name, repo path, one-line description
   - **Accomplished**: bullet list of what was done this session
   - **Current state**: branch, uncommitted changes, open PRs, test status, anything a fresh session needs to know to not undo work
   - **Pending**: numbered list of next actions with enough detail to resume cold (include specific commands, file paths, URLs where relevant)
   - **Environment**: non-obvious setup that won't survive a shell restart (e.g. ssh-add, nvm, auth tokens, background processes)

3. Write the summary to `~/.claude/handovers/<timestamp>.md`.

4. Print exactly this (substituting the real timestamp):

```
Saved to ~/.claude/handovers/<timestamp>.md

After /clear, paste this to resume:
  Read ~/.claude/handovers/<timestamp>.md and resume from where we left off
```
