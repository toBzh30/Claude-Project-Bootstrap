# Working agreements

How we collaborate on this repo. Cross-session, cross-machine defaults — apply at all times.

The user drives **product intent** through conversation; **Claude maintains the project board state**. The user shouldn't have to remember to file issues, update Status, or link PRs — those are Claude's responsibility, same as commits and pushes. The board exists for cross-session/cross-machine continuity, not as something the user manicures.

---

## Make rules concrete, not aspirational

Vague guidance ("be careful", "use judgment") doesn't fire in practice — concrete patterns do. When adding to this doc or any `.claude/rules/` file: name the specific situation / file / command that triggers the rule; for overrides, **list the exact situations** that justify breaking it, not "use judgment"; lead with an example — *"filter `gh issue list` with `--jq 'map({number, title})'` — default returns ~15KB"* beats *"filter command output"*. If you can't name a concrete trigger or counter-example, the rule isn't ready to write down. (Applies to itself — note the example just used.)

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
  - `feat/4-user-auth`
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

`gh issue create` has no `--type` flag — set the org's Issue type via REST PATCH after creation (command in the lifecycle filing row above; the type *name* goes in directly, no node-ID lookup). Map `bug` label → Bug, `feature` → Feature, else → Task. UI-filed issues pick up `type:` from `.github/ISSUE_TEMPLATE/*.yml` automatically; the PATCH is only for CLI-filed issues.

Org types configured for `<owner>`: `<configured-issue-types>`. If they ever change, re-discover with `gh api orgs/<owner>/issue-types --jq '[.[].name]'` (403s on PATs without org-admin scope → sample recent issues' `.type.name` instead).

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

   In both modes: **don't start implementing until the user signs off on the approach.** "Sign off" is explicit — *"yes, do it"* or *"start with step 1"*. Silence is not approval — and a *yes* to filing, or to a batch of items, approves the intent, not each item's design; if a fork or inter-item conflict is still open, surface it first (see Anti-patterns).

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
- **Treating "yes" as a waiver of the design checkpoint** — *"yes, file these"* / *"go ahead"* approves the *intent*, not the *shape*. If you've found a genuine fork (the answer changes scope) or a conflict between the items you're proposing, **lead with it before filing or executing.** A conflict between two proposed items is the *strongest* trigger to grill, not a detail to bury in an issue body.

---

## Craft skills — when to suggest one

The `engineering-craft` plugin ships discipline skills — `grill-with-docs`, `prototype`, `tdd`, `diagnose`, `to-issues`, `to-prd`, `improve-codebase-architecture`, `code-review`. They earn their keep when **offered at the right moment**, not only when the user names them. Each trigger below is deliberately narrow — the failure mode here is *nagging*, so a cue fires on a **named condition**, never "consider a craft skill at every phase." Calibrate to what the skill is *for*, not how often you could invoke it.

**Three rules govern every cue:**
- **Suggest once per occurrence, then drop it** — a decline silences the cue *for that situation only*, never globally and never persisted. When the condition recurs (another fork, another bug, a later task) the cue is live again; never write a single "no" into a standing "don't suggest this skill." (Same restraint as *"silence is not approval"* — local to the moment.)
- **Frame around the discipline, not the tool** — *"let's drive this test-first"* lands even in a repo that enabled bootstrap but not `engineering-craft` (the two plugins have separate lifecycles); the skill is just the vehicle.
- **Honor the skills' own handoffs** — `diagnose` → `improve-codebase-architecture` (when the fix needs architectural change), `to-prd` → `to-issues` (slices), `prototype` → log the answer in `decisions.md`.

**The cues** (⤴ = lean proactive — *you* forecast the condition rather than waiting; ↩ = reactive on the named signal):

- ⤴ **`grill-with-docs`** — foreseen **branchy** uncertainty: interdependent decisions or a design tree to walk, cheaper to resolve by structured Q&A *before* executing than to discover mid-build. *Not:* a single isolated gap → ask one clarifying question; *"does this shape even work?"* → `prototype`.
- ⤴ **`prototype`** — uncertainty that's **empirical**: state-machine / data-model behavior, or UI feel — where *seeing it run or rendered* beats reasoning on paper. *Not:* conceptual/branchy → `grill-with-docs`; a plain fact → ask.
- ⤴ **`tdd`** (at execute) — about to implement **net-new or changed behavior that has a public seam**. *Not:* no seam (that absence is itself a finding → `improve-codebase-architecture`); a pure refactor, config, or docs change.
- ↩ **`diagnose`** — a **non-trivial** bug or perf regression whose cause isn't obvious. *Not:* an obvious one-liner → just fix it (the full reproduce→hypothesise loop is overkill).
- ⤴ **`to-issues`** (at plan) — a plan exceeds **one PR's worth** of independent work. *Not:* a single slice → file one issue.
- **`to-prd`** (conservative) — an **initiative-scale** effort that needs a parent spec holding sub-issues. *Not:* anything smaller → `to-issues` or a single issue (a PRD on small work creates a competing intake path).
- ↩ **`improve-codebase-architecture`** — a **coupling / no-seam smell** surfaces during `diagnose`, `tdd`, or Phase 6 reconcile. *Not:* a standalone "let's improve the architecture" — that stays user-initiated.

**`code-review` — before a PR leaves your hands.** Run it on any **non-trivial** change, *for a human reviewer or for auto-merge alike*. Mode decides what happens **after** the review, not whether it runs:
- **Solo / AFK `auto-merge`** → the review *is* the gate → merge.
- **Team / `review-required`** → the review is pre-handoff polish → the human then reviews cleaner code.
- **Either mode, trivia** (typo, one-line config, doc fix) → skip.

Effort scales with size/risk (medium default; high for large or risky diffs). The value is the **cold-agent fan-out** — fresh reviewers catch what you, the author, are blind to — so don't substitute "re-read my own diff" for the real thing. (`zoom-out` is intentionally *not* cued: its frontmatter is `disable-model-invocation: true`, i.e. `/`-only by design.)

---

## AFK vs HITL issues

Every tracked issue carries a **`Mode`** (Project field: `HITL` default, or `AFK`) deciding whether Claude may work it **unattended**, under two gates:

1. **Eligibility** — `Mode = AFK` marks the issue *eligible*.
2. **Initiation** — Claude starts an AFK sweep **only** on an explicit instruction (*"work through the AFK issues"* / a `/loop` you start). **Silence/absence is never initiation** (same invariant as *"silence is not approval"*).

Neither gate alone suffices. AFK is a **modifier on the six phases, not a replacement**: inside an initiated sweep the phase-4 sign-off is **pre-authorized** (the tag *is* the approval), so architect→plan→execute run without pausing; `HITL` issues run the full flow unchanged.

**Tagging `AFK`** — Claude sets `Mode` at file time and **reports it** (you can veto; default `HITL`, `AFK` is earned). The bar is the **inverse of the downgrade triggers below** — at file time Claude foresees none of them. Use the lightest method that clears it: immediate for clear/well-specified; a clarifying question or codebase read for mildly fuzzy; resolve via grilling for a genuine fork; leave `HITL` if it needs real-time judgment or touches prod.

**The sweep** — on explicit initiation, drain `AFK` issues **one at a time** (Priority desc, then issue # asc), each through the full lifecycle → PR → green CI + clean `/code-review` → the merge gate. **Sequential** (each branches from updated `main`, so dependencies resolve in order and no two PRs race to merge); **park-and-continue** (a downgrade trigger parks that issue, the sweep moves on); end with *"N merged, M parked, with reasons."*

**The merge gate** — read from `.claude/gh-project.json` → `afk.merge`: **`auto-merge`** (default) green CI + clean self-review → `gh pr merge --auto --squash`; **`review-required`** self-review the diff if non-trivial (per *Craft skills → `code-review`*), then open the PR and stop — a human merges (independent issues become reviewable PRs; dependent ones park on their predecessor's merge). A convention Claude honors, **independent of branch protection** (optional hardening, unavailable on some plans).

**Downgrade-to-HITL triggers** (park: flip `Mode → HITL`, comment why, continue): (1) scope turns ambiguous; (2) out-of-scope work needed → file a new issue, park as *blocked-on-#new*; (3) architectural fork with no clear default; (4) irreversible/outward-facing step the issue didn't authorize; (5) `/code-review` finds a real bug, not a nit; (6) can't reach green CI / no test seam; (7) thrashing — 3 cycles without converging.

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

- **GitHub issue type** must be set on *every* issue in *every* tracked repo (set it per *Setting Issue type* above; title-prefix convention: `[bug]` → Bug, `[feature]` → Feature, else → Task). This is the multi-repo stakes: the org-level type taxonomy is shared across all repos, so one untyped issue anywhere shows up as a "no type" gap that hides work behind the Project's type filter.

- **Strategic field** (`<strategic-field>` — typically `Initiative` for multi-repo Projects) must be set, even if the value is "Backlog". Filtering by `<strategic-field>` is how the Project surfaces "what's gating M1 across all repos".

- **Area** must be set. Areas are codebase-axis (Frontend / Backend / Infra) and let you see "everything backend across the platform" regardless of which repo holds it.

**GraphQL budget on a shared board.** GitHub's GraphQL API is ~5,000 points/user/hour (per *user* — shared across every session, hook, and machine; paid plans don't raise it). `gh project item-list <N> --owner <owner> --limit 1000` pulls every item × every field — thousands of points — and a couple of those drain the hour, after which `gh pr create` / `gh issue create` (both GraphQL) fail until it resets. The risk is acute on a cross-repo board (many items). So never casually scan the board — use the cheap per-issue `projectItems` query (see *Token efficiency*). **REST survives a drain:** `gh api repos/<owner>/<repo>/issues -f title=… -F body=@file -f "labels[]=…"` creates issues; PR creation has no `gh` REST shortcut, but `gh api repos/<owner>/<repo>/pulls -f title=… -f head=… -f base=<integration-branch> -F body=@file` works.

---

## Multi-repo sync

When you keep sibling clones side-by-side under one parent folder, be aware of **every** sibling at session start — not just the one you're working in. Stale clones cause stale handoff docs and "this function doesn't exist" surprises that are really sync drift, and a fresh session can pick up work already in flight on another repo/machine.

- **Discover, don't enumerate:** from the repo root, `find .. -maxdepth 2 -name .git -type d` (sibling clones sit under the same parent folder) — the set grows as services split out, so never hardcode the list; and the path is deliberately relative (`..`), never an absolute machine path, so it works on any host or layout.
- **Never pull onto a dirty tree or a non-default branch** — report the state, let the user decide what to pull.
- **Concrete trigger:** first turn after `/clear`, first turn of a new session, or any turn that names a sibling repo. Get the cross-repo freshness picture before reading handoff docs or proposing cross-repo changes.

The bundled `sibling-status.sh` SessionStart hook automates the *reporting* half of this (freshness per clone, plus optional cross-repo In-Progress + open PRs) — **opt-in, report-only, never mutates.** Enable it by writing `"siblings": { "sync": true }` (and optionally `"inflight": true`) into `.claude/gh-project.json`. The hook surfaces the picture; this rule is the judgment it can't encode.

---

## Keeping docs current

Doc-maintenance triggers *not* already covered by Phase 6 (reconcile-before-Done), the lifecycle table (shipping / decision-logging), or Branch strategy (`Closes #N`):

| When (concrete trigger) | What to update |
|---|---|
| Component in `<subdir>/` moves from mock data → real API call | Status table in `<subdir>/CLAUDE.md` |
| A "Pending" row in root `CLAUDE.md` ships | Move it to "Done" in the snapshot table (Project is live source — table is just a hint) |
| Milestone bar fully met | `gh issue close <tracking-issue>` after verifying every sub-issue is closed |
| New gotcha / constraint discovered in code | Append to that `<subdir>/CLAUDE.md` or relevant `.claude/rules/<topic>.md` |
| Stale fact found (a function renamed, a path moved) | Correct it in place — same commit as the rename if possible |

---

## When to log a decision

The *why* of a rule or a rejected path goes in `.claude/rules/decisions.md` — **its header carries the triggers, the three-line format, and the never-rewrite / split policy.** Log when a decision would otherwise get re-litigated or its rationale lost in 3 months; the lifecycle table's "Decision worth logging" row points here.

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

Habits to apply by default — but **break them the moment they conflict with correctness or you start thrashing**: re-reads are cheap, wrong fixes are expensive. If a narrow read makes debugging harder, widen it; if filtering hides the actual error, dump more.

- **Read narrowly.** When you know the section you need, use `Read` with `offset`/`limit` instead of reading the whole file. Most edits to large files (`<example-large-file-1>`, `<example-large-file-2>`) only need 30–50 lines of context.
- **Don't re-read files you just edited.** The harness tracks state after `Edit`/`Write` succeed; re-reading to "verify" the edit duplicates hundreds of lines into context for nothing.
- **Filter command output.** Pipe `gh ... --jq`, `grep`, `head`, `tail` to extract just the relevant fields. Default `gh issue list` returns ~15KB; with `--jq 'map({number, title})'` it's <2KB.
- **Filter typecheck and lint to the file you changed.** `tsc -b 2>&1 | grep MyFile.tsx` rather than dumping all pre-existing errors in unrelated files.
- **One source of truth per question.** When `gh project item-list` answers it, don't also read the snapshot table in `CLAUDE.md` — pick one.
- **Don't scan the whole board to find one item.** To get an issue's Project item id, query its `projectItems` directly (~1 GraphQL point) — `gh api graphql -f query='query($n:Int!){repository(owner:"<owner>",name:"<repo>"){issue(number:$n){projectItems(first:5){nodes{id project{number}}}}}}' -F n=<N>` — never `gh project item-list` to find it (that pulls every item × every field). Reuse the static field/option IDs already saved in `.claude/gh-project.json` rather than re-discovering via `field-list`. `gh api rate_limit` is free — check `.resources.graphql.remaining` before a board op if a prior call failed with "API rate limit exceeded".
- **For long sessions, suggest `/clear` between unrelated work.** History accumulates and every turn carries it. Picking up issue #Y after shipping #X with no shared context is cheaper in a fresh session than a 100-turn one.
- **Don't paste full backend logs or build output into prompts.** Tail the relevant lines or `grep` for the error pattern. Same for test failures, dep-install logs, etc.

### When to widen (don't ask permission — the discipline yields automatically)

- **Debugging across files** — start wide (changed file + callers + failing path), narrow once the root cause is found.
- **Refactoring a repeated pattern** — `grep` every call site and read them up front; peepholing invites inconsistency.
- **First contact with an unfamiliar subsystem** — read the relevant `<subdir>/CLAUDE.md`, rules file, and entry-point source in full before narrowing; tacit conventions live in surrounding code.
- **Three-strikes thrashing** — if you've said *"let me read a bit more of X"* three times, widen decisively.
- **Surprising tool output** — a typecheck/test failure on code you didn't touch: read enough to tell real regression from noise, don't filter it away.
