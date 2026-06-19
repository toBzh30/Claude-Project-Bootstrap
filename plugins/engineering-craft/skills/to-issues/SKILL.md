---
name: to-issues
description: Break a plan, spec, or PRD into independently-grabbable issues on the GitHub Project using tracer-bullet vertical slices. Use when user wants to convert a plan into issues, create implementation tickets, or break down work into issues.
---

# To Issues

Break a plan into independently-grabbable issues using vertical slices (tracer bullets).

This marketplace's issue/Project contract is set up by `github-project-setup` and recorded in `.claude/gh-project.json`; the filing lifecycle (labels, fields, report-back) lives in the repo's `working-agreements.md`. Follow that contract when publishing — don't fall back to bare `gh issue create`.

## Process

### 1. Gather context

Work from whatever is already in the conversation context. If the user passes an issue reference (number, URL, or path) as an argument, fetch it from GitHub and read its full body and comments.

### 2. Explore the codebase (optional)

If you have not already explored the codebase, do so to understand the current state of the code. Issue titles and descriptions should use the project's domain vocabulary from `CLAUDE.md` / `.claude/rules/glossary.md`, and respect `.claude/rules/decisions.md` for the area you're touching.

### 3. Draft vertical slices

Break the plan into **tracer bullet** issues. Each issue is a thin vertical slice that cuts through ALL integration layers end-to-end, NOT a horizontal slice of one layer. (When a slice spans repos, see the `tdd` skill's "Cross-repo slices" — the slice splits at the contract, with one real cross-repo e2e proof.)

Each slice gets an execution **Mode** matching the `Mode` Project field:

- **`HITL`** (default) — needs human interaction at a checkpoint: an architectural decision, a design review.
- **`AFK`** — clears the eligibility bar in `working-agreements.md` → *"AFK vs HITL issues"*: unambiguous scope, no unresolved architectural fork, no irreversible/outward-facing step, a plausible test seam, bounded. `AFK` is **earned**, not preferred-by-default — when unsure, leave it `HITL`.

<vertical-slice-rules>
- Each slice delivers a narrow but COMPLETE path through every layer (schema, API, UI, tests)
- A completed slice is demoable or verifiable on its own
- Prefer many thin slices over few thick ones
</vertical-slice-rules>

### 4. Quiz the user

Present the proposed breakdown as a numbered list. For each slice, show:

- **Title**: short descriptive name
- **Mode**: AFK / HITL
- **Blocked by**: which other slices (if any) must complete first
- **User stories covered**: which user stories this addresses (if the source material has them)

Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the dependency relationships correct?
- Should any slices be merged or split further?
- Are the correct slices marked as AFK vs HITL?

Iterate until the user approves the breakdown.

### 5. Publish the issues

For each approved slice, follow the repo's `working-agreements.md` filing lifecycle: `gh issue create` with the right labels, then set the Project fields — `Area`, `Priority`, and **`Mode`** (the slice's AFK/HITL classification) — and report back as the lifecycle prescribes. The issue is auto-added to the Project.

**If there's a parent** (a PRD issue, or a source issue you were handed), link each slice as a **sub-issue** of it — GitHub's native sub-issue relationship, which drives the `Sub-issues progress` bar:

```bash
# sub_issue_id is the child's DATABASE id (.id) — NOT its issue number; -F sends it typed (int)
child_id=$(gh api repos/<owner>/<repo>/issues/<child-number> --jq '.id')
gh api -X POST repos/<owner>/<repo>/issues/<parent-number>/sub_issues -F sub_issue_id="$child_id"
```

With no parent, a flat issue is correct — sub-issues are optional, not required.

Publish issues in dependency order (blockers first) so you can reference real issue numbers in the "Blocked by" field.

Use the issue body template below (aligned with the repo's `.github/ISSUE_TEMPLATE/`):

<issue-template>
## Parent

`References #N` for the parent issue (a PRD or source issue), if any — and link it as a real **sub-issue** per step 5 (the prose reference is just for readers). Omit this section for a standalone issue. Never use `Closes` in an issue body.

## What to build

A concise description of this vertical slice. Describe the end-to-end behavior, not layer-by-layer implementation.

Avoid specific file paths or code snippets — they go stale fast. Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it here and note briefly that it came from a prototype. Trim to the decision-rich parts — not a working demo, just the important bits.

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Blocked by

`References #N` for the blocking issue (if any), or "None — can start immediately".

</issue-template>

Do NOT close or modify any parent issue.
