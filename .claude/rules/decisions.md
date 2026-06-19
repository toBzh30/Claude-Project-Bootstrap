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

**Decision:** Whether an AFK issue auto-merges is read from `.claude/gh-project.json` → `afk.merge` (`auto-merge` | `review-required`, default `auto-merge`), honored by Claude. Branch protection is optional hardening, never the lever. (Schema: `conventions` path-pointers are *not* added — bootstrap conventions are hardcoded since `engineering-craft` is a companion to bootstrap; only the `afk` policy block and the opt-in `externalTruth` key extend the file.)
**Why:** Branch protection is unavailable on free private personal repos, so it can't be the universal team-review mechanism. In an AFK sweep Claude is the only actor merging, so a config flag Claude honors is sufficient and works on any plan/visibility. `Mode` stays a clean "who do I wait for" primitive; merge strictness is tuned independently (per-repo) via config. `/code-review` self-review runs in both modes, so `auto-merge` is machine-reviewed, not unreviewed.
**Status:** Active

## 2026-06-19 — AFK sweep is sequential with park-and-continue; parallel deferred

**Decision:** An AFK sweep processes issues one at a time (Priority desc, then issue-number asc); any downgrade trigger parks that single issue (flip `Mode → HITL`, comment) and the sweep continues. Parallel execution via worktrees is deferred.
**Why:** Sequential composes with auto-merge — each issue branches from the updated `main`, so dependencies resolve for free and there's no two-PRs-racing-to-merge contention (matches the existing "only merges to `main` need to sequence" agreement). Parallel reintroduces stale-base/merge-conflict handling for marginal wall-clock gain on a queue you're already away from. Park-and-continue keeps one bad issue from sinking the whole unattended run.
**Status:** Active

## 2026-06-19 — AFK initiation is a strong convention, not a mechanical gate (for now)

**Decision:** "Claude only starts an AFK sweep on an explicit user instruction, and never infers it from user silence/absence" is enforced as a strong working-agreements convention — *not* by a `/afk-sweep` command + PreToolUse hook. The mechanical initiation gate is deferred, not built.
**Why:** The user accepts the soft-guardrail residual (ambiguous NL initiation, `/loop` drift, skill-local "proceed if AFK" text, context decay, cold sub-agents) because the blast radius is already bracketed at the *other* end by the merge gate (review-required / branch-protection can't be talked past) — an over-eager model can prepare PRs but not land them unreviewed. A hard initiation gate (explicit token + hook) stays a future opt-in if the convention proves leaky. On vendoring, Matt's craft skills' own "proceed if the user is AFK" absence-detection is **stripped** — only an explicitly-initiated sweep unlocks proceed-without-waiting; outside that, checkpoints wait (silence ≠ approval).
**Status:** Active

## 2026-06-19 — Craft skills are tool-agnostic discipline, never infrastructure

**Decision:** The vendored `engineering-craft` skills teach *discipline* (test-first, mock-at-boundary, contract-at-seam) and stay tool-agnostic — they never prescribe a test framework, mocking library, or CI shape. (References #35)
**Why:** A craft skill propagates into already-bootstrapped repos that have their own mature, possibly-divergent test infrastructure. If the skill carried infrastructure, the "update" would fight or overwrite what's there. Discipline-only is additive: a repo with existing tests gains invokable craft tools + absorbable prose, never an infra rewrite. Baking in a framework would also weld a public-marketplace plugin to one stack.
**Status:** Active

## 2026-06-19 — Cross-repo tdd slices: contract-at-seam, not single-owner e2e

**Decision:** When a vertical slice spans repos, treat the other repo as a system boundary: tracer-bullet each side against a shared SDK-style contract (consumer mocks the provider at the contract; provider tested standalone), plus exactly one real cross-repo e2e proof per slice. Opt-in, gated on "slice spans repos" — single-repo repos never see it. (References #35)
**Why:** Falls directly out of Matt's existing `mocking.md` rule ("mock at system boundaries, never what you control") — a separate repo *is* a boundary. The rejected alternative (one owning-repo e2e driving both real systems per slice) is slow, couples the two repos' test runs on every change, and contradicts mock-at-boundaries. The single real e2e is the only place mock drift gets caught. Tool-agnostic (Pact / shared-schema snapshot / scripted harness — team's call).
**Status:** Active

## 2026-06-19 — A PRD is a regular issue with sub-issues, not a doc/milestone/new entity

**Decision:** `to-prd` publishes a PRD as an ordinary GitHub issue whose body is the PRD spec (`Mode = HITL`); its slices (via `to-issues`) become native **sub-issues** of it. Sub-issues are a universal capability of *any* issue — regular issue creation is unchanged and can decompose into sub-issues too. (References #35)
**Why:** Keeps the existing setup intact — no new artifact type, no committed PRD doc (which would rot after fan-out and contradict the "no roadmap.md / no planning docs" decision), and no repurposing of milestones (those answer *when it ships*, a release axis orthogonal to *what we're building*). Everything is an issue; the `Parent issue` / `Sub-issues progress` fields already on the board give the hierarchy and a progress bar; the PRD closes naturally when its slices do.
**Status:** Active
