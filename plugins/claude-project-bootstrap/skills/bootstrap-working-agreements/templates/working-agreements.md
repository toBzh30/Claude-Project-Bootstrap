# Working agreements

How we collaborate on this repo. Cross-session, cross-machine defaults — apply at all times.

The user drives **product intent** through conversation; **Claude maintains the project board state**. The user shouldn't have to remember to file issues, update Status, or link PRs — those are Claude's responsibility, same as commits and pushes. The board exists for cross-session/cross-machine continuity, not as something the user manicures.

---

## Make rules concrete, not aspirational

Vague guidance ("be careful", "use judgment", "break this when needed") doesn't fire in practice. Concrete patterns are what trigger Claude to apply or override a rule at the right moment.

When adding to this doc or any `.claude/rules/` file:
- Name the specific situation, file, command, or pattern that triggers the rule.
- If the rule has overrides, **list the exact situations** that justify breaking it — don't just say "use judgment".
- Examples beat principles. *"Filter `gh issue list` with `--jq 'map({number, title})'` — default returns ~15KB"* beats *"filter command output"*.
- If you can't think of a concrete trigger or counter-example, the rule probably isn't ready to write down.

This rule applies recursively to itself — note the concrete examples in each bullet above.

---

## When to file an issue

File when the item has **continuity value** — when a future session, the user on another machine, or a milestone scope debate would benefit from seeing it. Don't file housekeeping inside an active task.

**File:**
- Discrete intent surfaced in conversation (*"we should also let users…"*, *"eventually we'll need …"*)
- Bugs noticed independently of current work (you spotted it while doing something else)
- Refactors worth deferring to a separate moment (`# TODO: clean up X` you'd otherwise drop in code)
- Anything that might prompt *"is this in scope for milestone X?"*
- Anything cross-cutting enough that it should appear on a milestone tracking issue's checklist

**Don't file:**
- Typos, comment fixes, formatting, lint, type errors — fix in place
- Doc updates that ship with the same change as the code (e.g. updating `CLAUDE.md` when changing scheduler order — same commit)
- Tooling/env corrections (a missing pin, a portable command path) unless load-bearing for cross-machine setup
- Bug-fix-on-a-line-just-written
- Sub-tasks fully scoped inside an active issue's PR — those go in *that* issue's PR, not a new issue

When ambiguous, ask. **Default-yes for discrete intent; default-no for housekeeping inside other work.**

---

## Branch and PR strategy

**Tracked issues** → branch + PR.

- Branch name: `<type>/<issue-num>-<slug>` — short, lowercase, hyphens. Real examples:
  - `feat/4-zitadel-auth`
  - `fix/22-rate-limit`
  - `chore/13-cdn-cache-headers`
  - `refactor/15-db-schema-split` (or `tech-debt/15-…`)
- PR title mirrors the issue title.
- PR body **always includes `Closes #N`** so merge auto-closes the issue and the project's *"Item closed → Status: Done"* workflow fires.
  - **`Closes #N` in PR bodies only.** In issue bodies and commit messages use `References #N` instead — GitHub renders it as a link and shows the cross-reference in the issue timeline, but never auto-closes. Using `Closes` outside a PR body can fire unexpectedly and close issues you didn't intend to close.
  - **Gotcha:** `Closes` only auto-fires on merges into the **default branch** (typically `main`). PRs merging into integration branches like `<integration-branch>` *don't* auto-close. After merging such a PR, manually `gh issue close <N>` and flip the project Status to Done. Keep the `Closes` line in the body anyway — it auto-fires later when the integration branch eventually merges to main.

<trivia-rule>

**Multi-machine sequencing**: each machine works on its own feature branch; only merges to `<integration-branch>` need to sequence across machines. This is the structural fix for multi-machine divergence.

---

## Commits and merging

<mode-line>

**Principle:** commit granularity should match what survives the merge.

- **Squash-merge.** Branch commits are scratchpad — collapsed at merge. Commit as often as helps you (safety waypoints, "checkpoint before risky refactor"); the PR title/body becomes the one merged commit on `<integration-branch>`. Best for single-concern PRs where the merged commit is the only useful unit of history.
- **Regular merge / rebase-merge.** Branch commits become permanent `<integration-branch>` history. Each must be one logical change with a future-readable message; clean review-iteration noise via interactive rebase before merging. Use for: branches whose intermediate commits each say something a future reader or `git bisect` needs — typically multi-concern work (e.g. feature + tangentially-related fix) or refactors whose phases warrant their own `git blame`-able messages.

**Multi-contributor projects:** lean harder on regular-merge with curated commits — `git blame` and `git bisect` resolution across years of history matters more when many people touch the same code. **Single-maintainer projects:** squash is almost always right.

**Local commit habit (independent of merge policy):** commit at every meaningful waypoint on the branch. Local safety (machine dies, easy `git revert HEAD` after a wrong turn) is worth more than commit-count tidiness. With squash-merge there's no cost — commits collapse anyway.

---

## Lifecycle ownership (Claude's defaults)

| Event | Claude does (exact commands) |
|---|---|
| User mentions a discrete idea/bug/refactor | `gh issue create -t "<title>" -b "<body>" -l <labels>` (auto-added to project), **then immediately set the GitHub issue type if the org has them configured**: `gh api -X PATCH repos/<owner>/<repo>/issues/<N> -f type=<type-name>` (UI-filed issues pick up `type:` from `.github/ISSUE_TEMPLATE/*.yml` automatically). Set Project fields next: `<strategic-field>`, `Area`, `Priority`, `Mode` (`HITL` unless the issue clears the AFK bar — see *AFK vs HITL issues*). Then report back: *"filed as #N — title, type=…, labels=…, `<strategic-field>`=…, Area=…, Priority=…, milestone=…, Mode=…. Anything you'd add?"* |
| User says something ambiguously trackable | Ask first: *"Should I file this as an issue, or handle it inline?"* |
| Substantive new feature surfaces | Ask 2–3 clarifying questions (*who uses this? what triggers it? what's the simplest version that ships?*), then `gh issue create` with a real body |
| Picking up a tracked issue #N | Follow read → architect → plan → review → execute → reconcile (see "How we work through issues"). **Don't run `git checkout -b` or flip Status until the user has signed off on the approach.** Once approved: `git checkout -b <type>/N-<slug>`, set Status → In Progress (`gh project item-edit … --field-id <Status> --single-select-option-id <In Progress>`), `gh issue comment N -b "<one-line plan>"`. |
| Implementing | Read source first (narrow when possible), propose before destructive changes, verify before push |
| Hit a blocker | Set Status → Blocked, `gh issue comment N -b "blocked on: <one-line reason>"` |
| Out-of-scope item surfaces mid-PR | Push back, propose a new issue, `gh issue create …`, keep current PR focused |
| Decision worth logging surfaces (rule with non-obvious why, multi-week debate ends, pivot, rejected path, invisible constraint) | Add an entry to `.claude/rules/decisions.md` per the format in "When to log a decision" |
| Shipping | <shipping-row> |
| User explicitly says *"work through the AFK issues"* (or starts a `/loop`) | Run the **sweep**: drain `Mode = AFK` issues one at a time (Priority desc, then issue # asc), each through the full lifecycle → PR → green CI + clean `/code-review` → the `afk.merge` gate. Park-and-continue on any downgrade trigger. End with a report: *"N merged, M parked, with reasons."* **Never start this from user silence** — only an explicit instruction. See *AFK vs HITL issues*. |
| AFK issue hits a downgrade trigger mid-sweep | Flip `Mode → HITL`, `gh issue comment N -b "parked: <one-line reason>"`, leave the branch/PR for the user, continue the sweep to the next issue |
| Stale items in Todo for weeks | Surface for user: *"#N has been Todo since <date> — still relevant or close as wontfix?"* — user makes the call, never auto-close |

### Setting Issue type

`gh issue create` (as of v2.90) has no `--type` flag — set the GitHub-native Issue type via REST PATCH after creation:

```bash
gh api -X PATCH repos/<owner>/<repo>/issues/<N> -f type=<type-name>
```

The PATCH accepts the type *name* directly — no GraphQL node-ID lookup needed. Map labels → type: `bug` label → Bug, `feature` label → Feature, otherwise → Task. UI-filed issues already pick up `type:` from `.github/ISSUE_TEMPLATE/*.yml`; the PATCH step is only needed for CLI-filed issues.

Org type names configured for `<owner>` (filled in at bootstrap time): `<configured-issue-types>`. Re-query with:

```bash
gh api orgs/<owner>/issue-types --jq '[.[].name]'
```

This often 403s on fine-grained PATs lacking org admin scope. **Fallback** — sample existing issues to discover the configured set:

```bash
gh api repos/<owner>/<repo>/issues/<N> --jq '.type.name'
```

across a handful of recent issues. If every sample returns `null`, types aren't enabled at the org — owner must enable them in **Org Settings → Repository policies → Issue types** before the PATCH will succeed.

---

## How we work through issues

Tracked issues follow **read → architect → plan → review → execute → reconcile**. The user drives intent; Claude proposes structure. The flow exists because going straight from `Status: Todo` to a PR produces sprawling diffs the user can't review.

### The six phases

1. **Read.** Issue body + comments. The linked code (the file the issue points at, plus its callers and tests). Relevant `<subdir>/CLAUDE.md`, `.claude/rules/<topic>.md`, and `decisions.md` entries that touch this area. **Skipping this is the #1 cause of "Claude proposed a fix that contradicts an already-documented constraint".**

2. **Architect.** Propose the shape of the change. Concretely surface:
   - Files / modules / data structures that change
   - What stays the same (so the user knows what's not at risk)
   - 1–2 alternatives considered, each with one-line *"rejected because…"*
   - Anything that smells like it'll pull in an out-of-scope cleanup (file separately, don't smuggle)

3. **Plan.** Break into 3–7 logical steps (not micro-tasks), each one logical commit's worth. For every step: a verification line — what command, test, or UI flow proves it works.

4. **Review.** Present arch + plan to the user. **Two modes — user picks per issue:**
   - **Conversational** (default for novel or scope-fluid issues): back-and-forth across a few turns, refine the approach together before any code is written.
   - **Proposed-for-review** (default for well-scoped issues, or when the user wants to time-shift the discussion): write the full proposal as one message — usually as an issue comment so it persists alongside the issue. User reviews, refines, approves.

   In both modes: **don't start implementing until the user signs off on the approach.** "Sign off" is explicit — *"yes, do it"* or *"start with step 1"*. Silence is not approval.

5. **Execute.** `git checkout -b <type>/<N>-<slug>`, flip Status → In Progress, implement step-by-step. If a step turns out wrong mid-execution, surface it before continuing — don't silently improvise.

6. **Reconcile docs.** Before you flip Status → Done, close the documentation loop — this is part of *done*, not a follow-up. The bundled `doc-gate.sh` hook prompts at `gh pr create`/`merge` when the diff changed code but touched no docs. Update, in the **same PR as the code**:
   - `CLAUDE.md` / `<subdir>/CLAUDE.md` — if behavior or structure a future session would rely on changed.
   - `ARCHITECTURE.md` (or whatever architecture doc the repo keeps) — if the change moved architecture: a new service boundary, data flow, or contract.
   - `.claude/rules/decisions.md` — if the *why* would be non-obvious in 3 months.

   If there's genuinely no doc impact, say so in the PR body — and re-run the gated command with `no docs needed` to pass the hook — so the next session knows it was considered, not forgotten.

### Example architect output

> *Issue #N asks for X. Shape of the change:*
> - **Changes:** `core/foo.py` (add `handle_x()`), `tests/test_foo.py` (3 cases)
> - **Stays the same:** the public API at `services/api.py`, the DB schema
> - **Alternative considered:** doing this at the API layer. Rejected because every endpoint would have to repeat the logic; `core/` is the single source of truth.
> - **Out-of-scope risk:** noticed `services/legacy_foo.py` is dead code. Filing as a separate issue rather than cleaning up here.

### When to skip phases (trivial issues)

Skip phases 2–4 if **both** are true:
- The entire change can be described in one sentence.
- It touches one file.

Examples that skip: typo fix, a single config-flag flip, a one-line copy change. Read, execute, push.

If you can't meet both conditions, you're past the trivial threshold — do the full flow.

### Anti-patterns

- ***"Let me just start and see"*** — produces sprawling diffs the user can't review. Architect first.
- ***"Here's a 12-step plan"*** — too granular. Plan in logical chunks, not micro-tasks.
- ***"I'll combine fixing this and improving that"*** — two issues, two PRs. Push back.
- **Skipping the Read phase because *"I remember this code"*** — context decays between sessions. Read it again.
- **Architect / plan but no review checkpoint** — implementing on inferred sign-off. Wait for an explicit *"go"*.

---

## AFK vs HITL issues

Every tracked issue carries a **`Mode`** (Project field: `HITL` default, or `AFK`). `Mode` decides whether Claude may work the issue **unattended** — under two gates, the second of which is **never inferred**:

1. **Eligibility** — `Mode = AFK` marks the issue *eligible* to run unattended.
2. **Initiation** — Claude starts an AFK sweep **only** on an explicit instruction (*"work through the AFK issues"*, or a `/loop` you start). **User silence/absence is never initiation** — going quiet does not authorize Claude to begin (same invariant as *"silence is not approval"*).

Neither gate alone suffices: an `AFK`-tagged issue sits untouched until you explicitly initiate; an explicit *"go"* only reaches `AFK`-tagged issues.

This is a **modifier on the six phases, not a replacement.** For an `AFK` issue inside an initiated sweep, the phase-4 sign-off checkpoints are **pre-authorized** (the tag *is* the up-front approval); architect→plan→execute run without pausing. `HITL` issues run the full flow unchanged.

### When Claude tags an issue `AFK`

The eligibility bar is the **inverse of the downgrade triggers** below — at file time Claude foresees *none* of them: scope unambiguous, no unresolved architectural fork, no irreversible/outward-facing step, a plausible test seam, bounded. Use the **lightest method** that clears the bar — grilling is not a per-issue tax:

| How clear at file time | Path to `AFK` |
|---|---|
| Already clear (trivial or well-specified) | tag `AFK` immediately |
| Mildly fuzzy | a clarifying question, or read the codebase, then `AFK` |
| Genuinely contested (competing designs / unresolved fork) | resolve it (e.g. a grilling session) → `AFK` |
| Unresolvable without real-time judgment, or touches prod | leave `HITL` |

Claude sets `Mode` when filing and **reports it** (you can veto). Default `HITL` — `AFK` is earned.

### The sweep

On an explicit initiation, Claude drains `AFK`-eligible issues **one at a time**, ordered **Priority desc, then issue number asc**. Each issue runs the full lifecycle → opens a PR → green CI + a clean `/code-review` self-review → the merge gate.

- **Sequential, not parallel** — each issue branches from the updated `main`, so dependencies resolve in order and no two PRs race to merge.
- **Park-and-continue** — a downgrade trigger parks *that* issue and the sweep moves on; one issue never sinks the run.
- **End-of-run report** — *"N merged, M parked for you, with reasons."*

### The merge gate (`afk.merge`)

Read from `.claude/gh-project.json` → `afk.merge`:

- **`auto-merge`** (default) — green CI + clean self-review → `gh pr merge --auto --squash`.
- **`review-required`** — open the PR, request review, **do not** arm `--auto`; a human merges. Independent issues become reviewable PRs; dependent ones park on their predecessor's merge.

`afk.merge` is a convention Claude honors, **independent of GitHub branch protection** (unavailable on some plans/visibilities). Branch protection, where available, is optional hardening on top.

### Downgrade-to-HITL triggers (park: flip `Mode → HITL`, comment why, continue the sweep)

1. Scope turns ambiguous (two+ materially different implementations).
2. Out-of-scope work is required → file a new issue, park the original as *blocked-on-#new* (never smuggle).
3. Architectural fork with no clear default (a `decisions.md`-worthy choice).
4. Irreversible / outward-facing step the issue didn't authorize.
5. The `/code-review` self-review finds a real correctness bug (not a nit).
6. Can't reach green CI / no correct test seam.
7. Thrashing guard — 3 cycles without converging.

---

## What goes in a PR description

- One-paragraph summary of what changed and why (not what the issue body said — assume the reader follows `Closes #N`).
- Short test plan / verification steps if behaviour changed (manual checks or commands run).
- `Closes #N` (or `Closes #N, #M` for tightly coupled multi-issue PRs — rare but valid).

If the change touches a milestone tracking issue's checklist, the auto-close handles it; no manual checkbox toggling.

---

## Roadmap discipline (milestone scope)

`.claude/rules/roadmap.md` is the source of truth for *"is this in scope for the current milestone?"* When tempted to add something:

1. Open `.claude/rules/roadmap.md`.
2. If it isn't in the bar or the out-of-scope list, edit `roadmap.md` *first* to add it (with rationale), then proceed.
3. If it crosses milestones, defer — we ship the current bar, not a moving target.

Tracking issues (`[milestone] X — <one-line bar>`) hold the bar + out-of-scope inline so you don't need to leave the issue context. If a discussion in a tracking issue ends with *"let's add Y to <milestone>"*, update both the tracking issue body **and** `roadmap.md` in the same turn.

---

## Cross-repo Project contract

When this Project tracks issues across multiple repos under `<owner>` (multi-repo platform setup), every issue filed in *any* tracked repo must hit the Project board with these non-negotiables set at creation time. Without this contract, the cross-repo dimension breaks — sibling-repo issues either don't appear, or appear with critical fields blank, hiding work behind filter gaps.

- **GitHub issue type** (whichever set the org has configured — typically `Bug` / `Feature` / `Task`) must be set on every issue. The org-level taxonomy — orthogonal to labels and shared across all repos in the org. Without it, the Project's Issue Type filter shows "no type" gaps that hide work. Title-prefix → type mapping convention seen in this org:
  - `[bug]` → Bug
  - `[feature]` → Feature
  - (otherwise) → Task

  Issue templates in `.github/ISSUE_TEMPLATE/` set type up-front via the `type:` key; CLI invocations follow with `gh api -X PATCH repos/<owner>/<repo>/issues/<N> -f type=<type-name>` (`gh` ≤ 2.90 has no native `--type` flag).

- **Strategic field** (`<strategic-field>` — typically `Initiative` for multi-repo Projects) must be set, even if the value is "Backlog". Filtering by `<strategic-field>` is how the Project surfaces "what's gating M1 across all repos".

- **Area** must be set. Areas are codebase-axis (Frontend / Backend / Infra) and let you see "everything backend across the platform" regardless of which repo holds it.

---

## When to update what

| When (concrete trigger) | What to update |
|---|---|
| Component in `<subdir>/` moves from mock data → real API call | Status table in `<subdir>/CLAUDE.md` |
| A "Pending" row in root `CLAUDE.md` ships | Move it to "Done" in the snapshot table (Project is live source — table is just a hint) |
| Before flipping an issue to Done (Phase 6) | Reconcile docs in the same PR if code changed — `CLAUDE.md` / `ARCHITECTURE.md` / `.claude/rules/decisions.md`. The `doc-gate.sh` hook prompts at `gh pr create` if you forget |
| Issue ships via PR | Close via `Closes #N` in PR body; if PR target ≠ default branch, manually `gh issue close N` |
| Milestone bar fully met | `gh issue close <tracking-issue>` after verifying every sub-issue is closed |
| New gotcha / constraint discovered in code | Append to that `<subdir>/CLAUDE.md` or relevant `.claude/rules/<topic>.md` |
| Decision worth logging (see "When to log a decision") | Add entry to `.claude/rules/decisions.md` |
| Stale fact found (a function renamed, a path moved) | Correct it in place — same commit as the rename if possible |

---

## When to log a decision

`.claude/rules/decisions.md` is the *why* — separate from this doc (the *what*) and the GitHub Project (the *current state*). When future-you wonders why a rule exists or why a path was rejected, that's where you look.

**Add an entry when one of these triggers fires (concrete list — if none fits, the decision probably isn't load-bearing enough to log):**

- A rule lands in this doc whose *why* would be non-obvious in 3 months. Example: *the Closes-keyword gotcha → Closes only fires on default-branch merges*.
- A multi-week debate ended. Capture the resolution **and** the alternative considered, so it doesn't get re-litigated.
- A pivot or scope change at the project level. Example: *moved from single-admin to multi-tenant on YYYY-MM-DD*.
- A path *not* taken that someone might re-propose. Example: *considered server-side X, rejected — legal posture / latency / lock-in*.
- A constraint that's load-bearing but invisible from the code. Example: *Anthropic truncates root `CLAUDE.md` at 200 lines — split is non-negotiable*.

**Don't log:**
- Routine implementation choices (variable names, file layout, library picks unless lasting consequence)
- Decisions captured cleanly in a PR description or issue thread that nobody will re-litigate
- Bug-fix rationale — the commit message is enough

**Format — three-line shape, no full ADR ceremony:**

```
## YYYY-MM-DD — <one-line decision title>
**Decision:** <one sentence>
**Why:** <one or two sentences — the load-bearing reason, not the obvious context>
**Status:** Active / Superseded by <YYYY-MM-DD entry> / Reversed
```

**Status field policy: never delete or rewrite an entry.** When a decision is overturned, leave the original (mark `Superseded by …` or `Reversed`) and add a new entry. The history is the value — without it, *"we already tried that, here's why we changed our mind"* is lost.

**When to split to `decisions/` directory:** if `decisions.md` passes ~50 entries or scrolling becomes painful, split each entry into `decisions/YYYY-MM-DD-slug.md` and replace `decisions.md` with an index pointing at them. Single-file is the default; directory is the escape hatch.

---

## Push back, don't smuggle

If the user proposes something that conflicts with the milestone bar, the out-of-scope list, or these working agreements: **say so**. Don't quietly comply if you think the choice is wrong; surface the tension, let the user decide. The whole point of the discipline mechanism is that it survives well-intentioned scope drift — that requires both sides to enforce it.

Concrete examples of when to push back:
- *"Let's also add X to this PR"* when X has its own issue under a later milestone — push back, propose splitting.
- *"Just disable the failing test for now"* when the test is failing for a real reason — push back, propose fixing the root cause.
- *"Skip the type check"* when it's flagging a real type error — push back, propose fixing the type.

---

## Infrastructure boundaries

Project-specific constraints around shipping and protected files. These override Claude's default implementation behaviour — the point is to stop "helpful" reformatting of infra files or inventing a local deploy command when the project already has a canonical one.

**How changes ship:** <deploy-flow>
*(e.g. "merges to `main` trigger the CI/CD pipeline — don't ssh anywhere or run a deploy locally")*

**Canonical local dev/deploy command:** `<local-deploy-command>`
Use this exact command — don't substitute `docker compose up`, `npm start`, or similar improvised invocations. If you think a different command is needed for a specific task, surface it before running.

**Hands-off files** — don't edit, overwrite, or auto-format without explicit request:
- `<hands-off-file-1>`
- `<hands-off-file-2>`

These are typically files where a "small cleanup" can break a pipeline nobody's watching locally — `docker-compose.yml`, deploy scripts, CI workflow YAML, IaC manifests.

If a task appears to require violating any of these, surface the conflict before acting (per "Push back, don't smuggle" above).

---

## Token efficiency

Habits to apply by default — but **break them the moment they conflict with correctness or you start thrashing**. If a narrow read makes debugging harder because you keep needing more context, widen the read. If filtering a log line hides the actual error, dump more of it. If you're guessing because you starved yourself of context, you've optimised for the wrong thing — re-reads are cheap, wrong fixes are expensive.

- **Read narrowly.** When you know the section you need, use `Read` with `offset`/`limit` instead of reading the whole file. Most edits to large files (`<example-large-file-1>`, `<example-large-file-2>`) only need 30–50 lines of context.
- **Don't re-read files you just edited.** The harness tracks state after `Edit`/`Write` succeed; re-reading to "verify" the edit duplicates hundreds of lines into context for nothing.
- **Filter command output.** Pipe `gh ... --jq`, `grep`, `head`, `tail` to extract just the relevant fields. Default `gh issue list` returns ~15KB; with `--jq 'map({number, title})'` it's <2KB.
- **Filter typecheck and lint to the file you changed.** `tsc -b 2>&1 | grep MyFile.tsx` rather than dumping all pre-existing errors in unrelated files.
- **One source of truth per question.** When `gh project item-list` answers it, don't also read the snapshot table in `CLAUDE.md` — pick one.
- **For long sessions, suggest `/clear` between unrelated work.** History accumulates and every turn carries it. Picking up issue #Y after shipping #X with no shared context is cheaper in a fresh session than a 100-turn one.
- **Don't paste full backend logs or build output into prompts.** Tail the relevant lines or `grep` for the error pattern. Same for test failures, dep-install logs, etc.

### Common override situations — widen by default

Don't ask permission for these; the discipline above yields automatically:

- **Debugging across files.** Start wide (the changed file + its callers + the failing path) and narrow once the root cause is identified. A wrong fix from a too-narrow read costs more than the re-read would have.
- **Refactoring a pattern used in many places.** `grep` for every call site first; read them all up front. Peepholing one site at a time invites inconsistency.
- **First contact with an unfamiliar subsystem.** Read the relevant `<subdir>/CLAUDE.md`, the related rules file, and the entry-point source file in full before narrowing. Tacit conventions live in surrounding code, not in the line you'd be tempted to jump straight to.
- **Three-strikes thrashing.** If you've asked *"let me read a bit more of X"* three times in a row, widen decisively instead of iterating. The narrow-then-widen-then-narrow-again loop costs more total than one honest wider read.
- **Surprising tool output that doesn't match the change.** If a typecheck fails on a file you didn't edit, or a test breaks for an unrelated reason, don't filter it away — read enough to tell whether it's a real regression you caused or genuine noise to ignore.
