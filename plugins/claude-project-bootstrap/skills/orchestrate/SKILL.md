---
name: orchestrate
description: Drive a multi-issue plan (an issue list, a milestone, or an epic) as an orchestrator. Delegate each issue to a worker (cloud child sessions or local worktree subagents, picked from the tools available) and keep planning, review, merging and the issue lifecycle yourself. Use when the user names a set of issues, a milestone or an epic and asks you to orchestrate it, run it in parallel, or work through it while they are away. The parallel counterpart to the sequential AFK sweep in working-agreements.md.
user-invocable: true
---

# /orchestrate — Run a multi-issue plan through delegated workers

You hold the plan. You don't implement it. Workers implement; you brief them, check their evidence, review their PRs, merge, close issues and report.

This is the **parallel** counterpart to the sequential AFK sweep in `.claude/rules/working-agreements.md`. Everything there still applies: the issue lifecycle, the downgrade triggers, the `afk.merge` gate and "silence is not approval". This skill adds how to fan the work out and keep it coherent.

Where a repo was never bootstrapped (no `working-agreements.md`, no `.claude/gh-project.json`), use the defaults stated below.

---

## Step 0 — Gate: no concrete goal, no start

The goal must be one of:

- an explicit issue list (`#12 #14 #15`),
- a milestone, or
- an epic or tracking issue with sub-issues.

**Stop and ask** if any of these holds:

- the goal is a placeholder or vague ("the plan", "everything", `<issues / goal>`),
- the goal is already done (epic closed, milestone empty),
- the set includes items that are on hold, discussions, or another milestone.

"Go" is not a goal. A wrong guess here costs a whole unattended run.

Then confirm, in one message:

- **Definition of done:** "Done = #A, #B, #C closed. Anything needing a decision goes into one decisions issue at the end."
- **Fix policy** (step 5). Default is `inline`.
- **Merge gate** (step 4). Read `afk.merge` from `.claude/gh-project.json`; if that is absent, ask. Don't assume.
- **Pre-authorised outward-facing steps**, if any (e.g. "deploy to staging is fine"). The default is none.

If the user has already said they'll be away, send this message, use the defaults for anything they didn't answer, and proceed.

## Step 1 — Pick the executor

- **`mcp__claude-code-remote__create_session` is available** → you are in a cloud session that can start children. Read `executors/cloud.md`.
- **Otherwise** → read `executors/local.md`.

Read only the one that applies. Everything below holds for both.

## Step 2 — Read, check, plan

1. **Read every issue in the set: the body *and* every comment.** Later comments often narrow, widen or reverse the original ask. Also read the rules files and decision entries each issue touches.
2. **Check current state** of `main` (or the integration branch). Recent merges may already have done an item, fully or partly. Close a fully done item yourself, quoting the file:line or command output as evidence. For a partly done item, rewrite the remaining scope before you brief anyone. Optionally delegate this check to one read-only agent for large sets.
3. **Order the work.**
   - Items run in parallel when their changed files don't overlap.
   - Items run in sequence when one needs another's output, or when both touch a hot file (schema, a shared module, a central config).
   - Foundations go first. The concurrency cap is in the executor file.
4. **Integration branch or not.**
   - Use one (e.g. `v2`, `int/<milestone>`) when there are more than ~5 items, or when half-finished work must not reach the default branch, e.g. a published image built from `main`.
   - Workers' PRs then target it. **`Closes #N` won't fire there**, so you close each issue by hand when its PR lands.
   - The release is one merge into the default branch at the end, handled by you and gated like any other outward-facing step.
5. **Write the plan down** as a comment on the epic or tracking issue: waves, order, and which items park if blocked. If none exists, create one tracking issue. This is the memory that survives compaction.

## Step 3 — Brief each worker

Use `brief-template.md`. Every brief contains:

- the issue number and the scope as *you* rewrote it after step 2,
- branch name and base branch,
- what the worker may touch and what it must not,
- the rules files and decision entries to read first,
- **how to prove it works**: the exact commands, plus what output counts as passing,
- the docs to reconcile in the **same** PR (CLAUDE.md spokes, rules files, decisions log) per working-agreements Phase 6,
- the report-back format: PR link, quoted test output, anything deferred or surprising.

Long builds and test runs go in the background. A worker that needs a product decision stops and reports. It doesn't guess.

## Step 4 — Gate each result

1. **Verified = output you can quote.** A worker saying "tests pass" is a claim, not evidence. Ask for the command and its output, or run it yourself on the branch.
2. **Review** the PR with `/code-review`. Effort is medium by default, high for large or risky diffs.
3. **Fix loop.** Findings go back to the **same** worker, then review again. You get at most two fix rounds. A real bug still open after round two parks the item (downgrade trigger 5). Nits don't block.
4. **Merge** per the merge gate:
   - **`auto-merge`**: merge after green CI and a clean review (squash, unless the repo says otherwise).
   - **`review-required`**: leave the reviewed PR for a human. An item that depends on it parks until it merges.
5. **Close the issue** (by hand if merging into an integration branch), set the board Status, and comment one line with the PR link.
6. A **stalled worker is resumed**, not replaced. A fresh worker loses its context and repeats its mistakes. Replace it only if it is dead (failed session, crashed agent).

## Step 5 — What comes up mid-run

Apply the fix policy the user chose in step 0.

| Situation | `inline` (default) | `strict` |
|---|---|---|
| Blocks the current item | Fix inside that item's PR | Fix inside that item's PR |
| Small and adjacent: one file, obvious fix, same area | Fix in that item's PR, note it in the PR body | File an issue |
| Anything larger, or another area | File an issue and add it to the plan if in scope | File an issue |
| Out of scope for the goal | File an issue, don't do it | File an issue, don't do it |

**Park** an item (move on, record it for the decisions issue) only on a downgrade trigger:

1. Scope turned ambiguous.
2. It needs out-of-scope work first.
3. An architectural fork with no clear default.
4. An irreversible or outward-facing step that wasn't pre-authorised.
5. A real bug survived two review rounds.
6. No green CI or no test seam.
7. Thrashing: three cycles without converging.

Parking flips `Mode → HITL` (where the board has it) and comments the reason on the issue.

## Step 6 — What you keep

Never delegate:

- merging and closing issues,
- board fields,
- the decisions issue,
- anything irreversible or outward-facing: releases, deploys, production data, migrations against a live database, external accounts, messages to people, comments on others' PRs.

For those, ask unless step 0 pre-authorised the exact step.

## Step 7 — Durable log

Your context will be compacted mid-run, and the conversation may not survive. Keep the state on GitHub:

- a one-line comment on each issue as it changes state: briefed, PR open, merged, parked, with links;
- the plan comment on the tracking issue, updated when the order changes.

After compaction, reload state from those comments, the open PRs, and (cloud) `list_sessions`. Don't rely on memory.

## Step 8 — Finish

1. If an integration branch was used, open its release PR into the default branch. Merge it only if step 0 authorised that. Otherwise leave it for the user.
2. File **one** decisions issue listing every parked item and every open question. For each: what is blocked, the options, and your recommendation.
3. Report to the user:
   - what merged (PR links),
   - what closed without code (with evidence),
   - what was filed,
   - what parked and why,
   - the link to the decisions issue.

## Anti-patterns

- **Starting from a vague goal.** That is step 0's whole job.
- **Implementing items yourself** "because it's quick". It bloats your context, which is the scarce resource here, and skips the review gate.
- **Briefing from the issue title alone.** Read the comments and check current state first.
- **Accepting "done" without quoted output.**
- **Replacing a stalled worker** instead of resuming it.
- **Two workers touching the same hot file in parallel.** Sequence them.
- **Leaving issues open** after merging into an integration branch.
