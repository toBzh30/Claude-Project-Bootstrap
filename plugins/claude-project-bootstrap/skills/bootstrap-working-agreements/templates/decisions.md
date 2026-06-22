# Decisions

The *why* — separate from `working-agreements.md` (the *what*) and the GitHub Project (the *current state*). When future-you wonders why a rule exists or why a path was rejected, this is where you look.

## When to log a decision

**Add an entry when one of these fires** (if none fits, it's probably not load-bearing enough to log):

- A rule landed in `working-agreements.md` whose *why* would be non-obvious in 3 months (e.g. *`Closes` only fires on default-branch merges*).
- A multi-week debate ended — capture the resolution **and** the rejected alternative, so it isn't re-litigated.
- A project-level pivot or scope change (e.g. *moved single-admin → multi-tenant on YYYY-MM-DD*).
- A path *not* taken that someone might re-propose (e.g. *considered server-side X, rejected — latency / lock-in*).
- A constraint that's load-bearing but invisible from the code (e.g. *root `CLAUDE.md` truncates at ~200 lines*).

**Don't log:** routine implementation choices (names, layout, library picks without lasting consequence); decisions already captured cleanly in a PR/issue thread nobody will re-litigate; bug-fix rationale (the commit message is enough).

## Format — three lines, no ADR ceremony

```
## YYYY-MM-DD — <one-line decision title>
**Decision:** <one sentence>
**Why:** <one or two sentences — the load-bearing reason, not the obvious context>
**Status:** Active / Superseded by <YYYY-MM-DD entry> / Reversed
```

**Never delete or rewrite an entry.** When a decision is overturned, leave the original (mark `Superseded by …` or `Reversed`) and add a new entry — the history is the value. If this file passes ~50 entries, split each into `decisions/YYYY-MM-DD-slug.md` and replace this file with an index.

---

<!-- Example entry — delete this comment block once you've logged your first real decision.

## YYYY-MM-DD — <one-line decision title>
**Decision:** <one sentence stating what was decided>
**Why:** <one or two sentences — the load-bearing reason, not the obvious context>
**Status:** Active

-->
