# Executor: local subagents in worktrees

Use when no cloud-session tools are available: Claude Code in a terminal, IDE or desktop app. Each worker is an `Agent` subagent working in its own git worktree, on the same machine and sharing its CPU, disk and ports.

## Start a worker

- `Agent` with `isolation: "worktree"`, `run_in_background: true`, a short `description` (`#<N> <slug>`), and the filled brief as `prompt`.
- The brief names the branch. The worker creates it in its worktree from the base branch.

**Concurrency cap: 2–3.** Builds and test suites compete for the same machine. Drop to 1–2 for heavy builds.

## Talk to it

- `SendMessage` to the agent's id or name, for review findings and follow-ups. Its context is intact, so don't restate the brief.
- A new `Agent` call starts from zero. Use it only when the old worker is genuinely dead.

## Hear back

- Background agents notify you when they finish. Don't poll and don't sleep. Start the next independent item or end the turn.
- The final report is all you see. If it lacks quoted test output, send it back and ask for the output.

## Worktree setup

Fresh worktrees have no installed dependencies, so the brief must say how to get them:

- **Python:** create a venv in the worktree (`python -m venv .venv && .venv/bin/pip install -r …`), or point at the main checkout's venv if dependencies didn't change.
- **Node:** `npm ci` in the worktree, or symlink the main checkout's `node_modules` when `package-lock.json` is untouched.
- **Ports:** give each worker its own port range if it starts a dev server, e.g. `5173 + 10·slot`.
- **Untracked config:** gitignored files such as `config.yaml` and `.env` don't exist in a new worktree. Name them in the brief and say whether to copy them.

## PRs and merging

- The worker pushes its branch and opens the PR. You review with `/code-review`, send findings back via `SendMessage`, and merge per the gate.
- After merging, pull the base branch in the main checkout so the next wave branches from current state.

## Cleanup

- Unchanged worktrees are removed automatically. Remove the worktree of each merged item yourself (`git worktree remove`).
- Leave parked items' worktrees and branches in place for the user.
