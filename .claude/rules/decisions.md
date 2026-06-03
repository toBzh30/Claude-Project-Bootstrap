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
