# Decisions

The *why* — separate from `working-agreements.md` (the *what*) and the GitHub Project (the *current state*). When future-you wonders why a rule exists or why a path was rejected, this is where you look.

## When to log a decision

**Add an entry when one of these fires** (if none fits, it's probably not load-bearing enough to log):

- A rule landed in `working-agreements.md` whose *why* would be non-obvious in 3 months.
- A multi-week debate ended — capture the resolution **and** the rejected alternative.
- A project-level pivot or scope change.
- A path *not* taken that someone might re-propose.
- A constraint that's load-bearing but invisible from the code.

**Don't log:** routine implementation choices (names, layout); decisions already captured cleanly in a PR/issue thread nobody will re-litigate; bug-fix rationale (the commit message is enough).

## Format — three lines, no ADR ceremony

```
## YYYY-MM-DD — <one-line decision title>
**Decision:** <one sentence>
**Why:** <one or two sentences — the load-bearing reason, not the obvious context>
**Status:** Active / Superseded by <YYYY-MM-DD entry> / Reversed
```

**Never delete or rewrite an entry.** When a decision is overturned, leave the original (mark `Superseded by …` or `Reversed`) and add a new entry — the history is the value. If this file passes ~50 entries, split each into `decisions/YYYY-MM-DD-slug.md` and replace this file with an index.

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

## 2026-06-19 — engineering-craft also holds homegrown Claude-coding craft skills

**Decision:** `engineering-craft` is no longer purely vendored-from-Matt — it also carries **homegrown** skills that are tool-agnostic *Claude-coding* craft (first: `checkpoint`, the session-handover skill). Kept the plugin name; broadened its description to "engineering & Claude-coding craft"; `ATTRIBUTION.md` now marks vendored-vs-original and notes the integration wiring is our work. (References #51)
**Why:** A dedicated plugin for one small session/workflow skill is more overhead (new marketplace entry, settings/enablement, dogfooding) than the identity gain — "craft" already stretches to cover disciplined session handoff, which is tool-agnostic and additive like the vendored skills. The "tool-agnostic discipline, never infrastructure" constraint still holds: `checkpoint` prescribes no framework/CI, just writes a handover to the Claude Code-standard `~/.claude/handovers/`. Rejected: a separate `claude-workflow` plugin (revisit only if such skills accumulate); a rename (too much blast radius for one skill).
**Status:** Active

## 2026-06-22 — Sibling-status is one report-only SessionStart hook, never auto-merge

**Decision:** Cross-repo session-start freshness ships as a single `sibling-status.sh` SessionStart hook that *reports* (fetch + show behind/ahead/dirty/branch, plus an opt-in in-flight board surface) and **never mutates** — no merge/pull/checkout. Opt-in and doubly gated via `.claude/gh-project.json` (`siblings.sync`, with `siblings.inflight` a separate sub-key for the GraphQL-spending board scan). Collapsed from the original two-hook / two-flag / auto-`ff-merge` design (#56 + #57). (References #56, #57)
**Why:** The value is *awareness*, not mutation — the silent cross-repo `git merge --ff-only` was the only genuinely risky/complex piece (mutating repos the user didn't open, shipping to a marketplace with no CI) and the smallest slice of value; dropping it also dissolved the plugin-root-vs-cwd design blocker, since a read-only walk derives its siblings root from the session cwd's git toplevel and doesn't care where the script runs from. Two hooks + two flags + four offer wirings was over-engineering for a marginal "free-git-only" user; the in-flight surface folds into one hook gated internally by the GraphQL rate-limit guard (the first consumer to *demonstrate* the budget rule by yielding when low). Rejected: auto-merge (a later opt-in `ff-merge` sub-flag if reporting proves it's always safe-and-annoying); a prose-only rule with no hook (loses turn-1 determinism — the rule stays as the judgment layer the hook can't encode).
**Status:** Active

## 2026-06-22 — Craft-skill cues are suggestion-prose; code-review gates on complexity, not merge-mode

**Decision:** The `engineering-craft` skills are wired into `working-agreements.md` as **proactive suggestion cues** — one named trigger each, "suggest once then drop" — not as auto-invocation or hooks; and `code-review` is recalibrated to fire before any PR handoff on **non-trivial** changes in *every* mode (Team/HITL included), with `Mode` deciding only what happens *after* the review. `zoom-out` gets no cue (its frontmatter `disable-model-invocation: true` makes it `/`-only by design). Triggers were calibrated against each skill's `SKILL.md`, not its one-line description. (References #70)
**Why:** Suggestion-prose composes with the existing "Claude proposes, user signs off" model and degrades gracefully when `engineering-craft` isn't enabled; a hook / auto-invoke would fire mechanically regardless of fit and couldn't carry the per-skill judgment (*"branchy vs single gap"*, *"non-trivial bug"*, *"has a test seam"*). The prior wiring coupled `code-review` to *who merges*, which captured only its merge-gate role and dropped its quality-cross-check role — valuable in Team mode too, where "open the PR and stop" otherwise hands a human an unreviewed diff. Gating on **complexity, not mode** keeps the cross-check where it pays and skips it on trivia. Rejected: a PostToolUse/SessionStart hook to fire the cues (mechanical, can't judge fit, would nag); leaving `code-review` Solo/AFK-only (under-reviews Team handoffs).
**Status:** Active

## 2026-06-25 — Team onboarding is the committed project-scope block + trust prompt, not a per-machine user-scope install

**Decision:** A new developer onboards to a bootstrapped repo by *clone → open Claude Code → trust the folder → accept the auto-prompts*. The committed project-scope `.claude/settings.json` (`extraKnownMarketplaces` GitHub source + `enabledPlugins`) is the whole mechanism; no per-machine `claude plugin install … --scope user` or `marketplace add` step is required.
**Why:** Per the Claude Code docs, project-scope `enabledPlugins` + `extraKnownMarketplaces` drives a self-contained marketplace-fetch → plugin-install chain once the folder is trusted (the per-repo, per-user trust prompt is the consent gate) — no user-scope prerequisite. Corroborated empirically: every Pyrois repo shows `scope: project` installs, exactly what the committed block produces on trust, never a manual user-scope install. Rejected: requiring each dev to run one user-scope install per machine — unnecessary ceremony that the committed block already obviates, and it would drift from the "board/config travels with the repo" principle.
**Status:** Active
