# Decisions

The *why* — separate from `working-agreements.md` (the *what*) and the GitHub Project (the *current state*). When future-you wonders why a rule exists or why a path was rejected, this is where you look.

**Format and "when to add an entry" rules live in `working-agreements.md` → "When to log a decision".** Don't duplicate them here.

---

## 2026-06-03 — No Tier field on the Project board

**Decision:** Dropped the Tier custom field from the GitHub Project for this repo.
**Why:** This is a single-maintainer plugin repo with no user-facing tiers. The skill's own guidance says "Library or SDK → skip Tier entirely; use Priority alone." Every issue would have ended up tagged Core or Tech-debt, adding noise without signal.
**Status:** Active

## 2026-06-03 — Personal user repo, no GitHub Issue types

**Decision:** Stripped the "Setting Issue type" subsection and related lifecycle clauses from working-agreements.md.
**Why:** GitHub Issue types are an org-level feature. `toBzh30` is a personal user account — types aren't available regardless of token scope. The PATCH endpoint returns 404.
**Status:** Active

## 2026-06-03 — Continuous-flow shipping, no milestones

**Decision:** No milestone-based release planning (Alpha/Beta/GA). No roadmap.md.
**Why:** Plugin improvements ship as they're ready. There's no discrete release boundary or external dependency that warrants milestone gates for a single-maintainer tool repo.
**Status:** Active

## 2026-06-19 — AFK/HITL is a Project field, with authorize ≠ initiate

**Decision:** Execution mode (`AFK`/`HITL`, default HITL) is a Project single-select field, not a per-repo label; tagging an issue AFK only *authorizes* unattended execution — a sweep still requires an explicit human "work through the queue" to *initiate*. (References #32)
**Why:** A Project field is defined once on the shared board and applies to issues from every repo pointing at it; a per-repo label drifts across a multi-repo team. Keeping authorize separate from initiate is what stops Claude self-authorizing autonomy — Claude may *tag* AFK (it owns board state) because the human's sweep-trigger remains the consent gate.
**Status:** Active

## 2026-06-19 — AFK merge gate lives in config, not GitHub branch protection

**Decision:** Whether an AFK issue auto-merges is read from `.claude/gh-project.json` → `conventions.afkMerge` (`auto-merge` | `review-required`, default `auto-merge`), honored by Claude. Branch protection is optional hardening, never the lever.
**Why:** Branch protection is unavailable on free private personal repos, so it can't be the universal team-review mechanism. In an AFK sweep Claude is the only actor merging, so a config flag Claude honors is sufficient and works on any plan/visibility. `Mode` stays a clean "who do I wait for" primitive; merge strictness is tuned independently (per-repo) via config. `/code-review` self-review runs in both modes, so `auto-merge` is machine-reviewed, not unreviewed.
**Status:** Active

## 2026-06-19 — AFK sweep is sequential with park-and-continue; parallel deferred

**Decision:** An AFK sweep processes issues one at a time (Priority desc, then issue-number asc); any downgrade trigger parks that single issue (flip `Mode → HITL`, comment) and the sweep continues. Parallel execution via worktrees is deferred.
**Why:** Sequential composes with auto-merge — each issue branches from the updated `main`, so dependencies resolve for free and there's no two-PRs-racing-to-merge contention (matches the existing "only merges to `main` need to sequence" agreement). Parallel reintroduces stale-base/merge-conflict handling for marginal wall-clock gain on a queue you're already away from. Park-and-continue keeps one bad issue from sinking the whole unattended run.
**Status:** Active
