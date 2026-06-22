# Working agreements

How we collaborate on this repo. Cross-session, cross-machine defaults — apply at all times.

The user drives **product intent** through conversation; **Claude maintains the project board state**. The user shouldn't have to remember to file issues, update Status, or link PRs — those are Claude's responsibility, same as commits and pushes. The board exists for cross-session/cross-machine continuity, not as something the user manicures.

---

## Make rules concrete, not aspirational

Vague guidance ("be careful", "use judgment") doesn't fire in practice — concrete patterns do. When adding to this doc or any `.claude/rules/` file: name the specific situation / file / command that triggers the rule; for overrides, **list the exact situations** that justify breaking it, not "use judgment"; lead with an example — *"filter `gh issue list` with `--jq 'map({number, title})'` — default returns ~15KB"* beats *"filter command output"*. If you can't name a concrete trigger or counter-example, the rule isn't ready to write down. (Applies to itself — note the example just used.)

---

## When to file an issue

File when the item has **continuity value** — when a future session, the user on another machine, or a scope debate would benefit from seeing it. Don't file housekeeping inside an active task.

**File:**
- Discrete intent surfaced in conversation (*"we should also let users…"*, *"eventually we'll need …"*)
- Bugs noticed independently of current work (you spotted it while doing something else)
- Refactors worth deferring to a separate moment (`# TODO: clean up X` you'd otherwise drop in code)
- Anything cross-cutting enough that it should appear on a tracking issue's checklist

**Don't file:**
- Typos, comment fixes, formatting, lint, type errors — fix in place
- Doc updates that ship with the same change as the code (e.g. updating `CLAUDE.md` when changing a skill step — same commit)
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
  - **Gotcha:** `Closes` only auto-fires on merges into the **default branch** (`main`). PRs merging into other branches *don't* auto-close. After merging such a PR, manually `gh issue close <N>` and flip the project Status to Done.

**Trivia** → direct commits to `main`. No branch, no PR, no issue. Each commit is one logical change with a future-readable message. Push immediately. Direct commits are allowed for single-line fixes, typos, and config tweaks.

**Multi-machine sequencing**: each machine works on its own feature branch; only merges to `main` need to sequence across machines. This is the structural fix for multi-machine divergence.

---

## Commits and merging

**Mode: Solo — Claude squash-merges automatically. Direct commits to `main` allowed for trivia.**

**Principle:** commit granularity should match what survives the merge.

- **Squash-merge.** Branch commits are scratchpad — collapsed at merge. Commit as often as helps you; the PR title/body becomes the one merged commit on `main`. Best for single-concern PRs.
- **Regular merge / rebase-merge.** Branch commits become permanent `main` history. Each must be one logical change with a future-readable message; clean review-iteration noise via interactive rebase before merging. Use for: branches whose intermediate commits each say something a future reader or `git bisect` needs.

**Local commit habit:** commit at every meaningful waypoint on the branch. With squash-merge there's no cost — commits collapse anyway.

---

## Lifecycle ownership (Claude's defaults)

| Event | Claude does (exact commands) |
|---|---|
| User mentions a discrete idea/bug/refactor | `gh issue create -t "<title>" -b "<body>" -l <labels>` (auto-added to project). Set Project fields: `Area`, `Priority`, `Mode` (`HITL` unless the issue clears the AFK bar — see *AFK vs HITL issues*). Then report back: *"filed as #N — title, labels=…, Area=…, Priority=…, Mode=…. Anything you'd add?"* |
| User says something ambiguously trackable | Ask first: *"Should I file this as an issue, or handle it inline?"* |
| Substantive new feature surfaces | Ask 2–3 clarifying questions (*who uses this? what triggers it? what's the simplest version that ships?*), then `gh issue create` with a real body |
| Picking up a tracked issue #N | Follow read → architect → plan → review → execute → reconcile (see "How we work through issues"). **Don't run `git checkout -b` or flip Status until the user has signed off on the approach.** Once approved: `git checkout -b <type>/N-<slug>`, set Status → In Progress, `gh issue comment N -b "<one-line plan>"`. |
| Implementing | Read source first (narrow when possible), propose before destructive changes, verify before push |
| Hit a blocker | Set Status → Blocked, `gh issue comment N -b "blocked on: <one-line reason>"` |
| Out-of-scope item surfaces mid-PR | Push back, propose a new issue, `gh issue create …`, keep current PR focused |
| Decision worth logging surfaces | Add an entry to `.claude/rules/decisions.md` per the format in "When to log a decision" |
| Shipping | PR body ends with `Closes #N`, `gh pr merge <PR> --squash`; if target ≠ default branch, follow up with `gh issue close N` and flip Status to Done manually |
| User explicitly says *"work through the AFK issues"* (or starts a `/loop`) | Run the **sweep**: drain `Mode = AFK` issues one at a time (Priority desc, then issue # asc), each through the full lifecycle → PR → green CI + clean `/code-review` → the `afk.merge` gate. Park-and-continue on any downgrade trigger. End with a report. **Never start this from user silence** — only an explicit instruction. See *AFK vs HITL issues*. |
| AFK issue hits a downgrade trigger mid-sweep | Flip `Mode → HITL`, `gh issue comment N -b "parked: <one-line reason>"`, leave the branch/PR for the user, continue the sweep |
| Stale items in Todo for weeks | Surface for user: *"#N has been Todo since <date> — still relevant or close as wontfix?"* — user makes the call, never auto-close |

---

## How we work through issues

Tracked issues follow **read → architect → plan → review → execute → reconcile**. The user drives intent; Claude proposes structure.

### The six phases

1. **Read.** Issue body + comments. The linked code (the file the issue points at, plus its callers and tests). Relevant `plugins/CLAUDE.md`, `.claude/rules/<topic>.md`, and `decisions.md` entries that touch this area. **Skipping this is the #1 cause of "Claude proposed a fix that contradicts an already-documented constraint".**

2. **Architect.** Propose the shape of the change. Concretely surface:
   - Files / modules / data structures that change
   - What stays the same (so the user knows what's not at risk)
   - 1–2 alternatives considered, each with one-line *"rejected because…"*
   - Anything that smells like it'll pull in an out-of-scope cleanup (file separately, don't smuggle)

3. **Plan.** Break into 3–7 logical steps, each one logical commit's worth. For every step: a verification line — what command, test, or UI flow proves it works.

4. **Review.** Present arch + plan to the user. **Two modes — user picks per issue:**
   - **Conversational** (default for novel or scope-fluid issues): back-and-forth across a few turns, refine together before any code is written.
   - **Proposed-for-review** (default for well-scoped issues): write the full proposal as one message — usually as an issue comment so it persists. User reviews, refines, approves.

   In both modes: **don't start implementing until the user signs off on the approach.** "Sign off" is explicit — *"yes, do it"* or *"start with step 1"*. Silence is not approval — and a *yes* to filing, or to a batch of items, approves the intent, not each item's design; if a fork or inter-item conflict is still open, surface it first (see Anti-patterns).

5. **Execute.** `git checkout -b <type>/<N>-<slug>`, flip Status → In Progress, implement step-by-step. If a step turns out wrong mid-execution, surface it before continuing — don't silently improvise.

6. **Reconcile docs.** Before you flip Status → Done, close the documentation loop — part of *done*, not a follow-up. The `doc-gate.sh` hook prompts at `gh pr create`/`merge` when the diff changed code but touched no docs. Update, in the **same PR as the code**: `plugins/CLAUDE.md` / the relevant `SKILL.md` if behaviour or structure a future session relies on changed; `.claude/rules/decisions.md` if the *why* would be non-obvious in 3 months. If there's genuinely no doc impact, say so in the PR body (and re-run the gated command with `no docs needed`) so the next session knows it was considered.

### Example architect output

> *Issue #N asks for X. Shape of the change:*
> - **Changes:** `core/foo.py` (add `handle_x()`), `tests/test_foo.py` (3 cases)
> - **Stays the same:** the public API at `services/api.py`, the DB schema
> - **Alternative considered:** doing this at the API layer. Rejected because every endpoint would repeat the logic; `core/` is the single source of truth.
> - **Out-of-scope risk:** noticed `services/legacy_foo.py` is dead code. Filing separately rather than cleaning up here.

### When to skip phases (trivial issues)

Skip phases 2–4 if **both** are true:
- The entire change can be described in one sentence.
- It touches one file.

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
- Short test plan / verification steps if behaviour changed.
- `Closes #N` (or `Closes #N, #M` for tightly coupled multi-issue PRs — rare but valid).

---

## Keeping docs current

The doc-maintenance trigger table lives in the root **`CLAUDE.md` → "Keeping these files current"** (skill behaviour → `SKILL.md`, new gotcha → `plugins/CLAUDE.md`, stale fact → fix in place, etc.) — single home, don't duplicate it here. Beyond that table: reconcile docs before flipping an issue to Done (Phase 6), and log a decision worth keeping (see below).

---

## When to log a decision

The *why* of a rule or a rejected path goes in `.claude/rules/decisions.md` — **its header carries the triggers, the three-line format, and the never-rewrite policy.** Log when a decision would otherwise get re-litigated or its rationale lost in 3 months; the lifecycle table's "Decision worth logging" row points here.

---

## Push back, don't smuggle

If the user proposes something that conflicts with these working agreements: **say so**. Don't quietly comply if you think the choice is wrong; surface the tension, let the user decide.

Concrete examples:
- *"Let's also add X to this PR"* when X has its own issue — push back, propose splitting.
- *"Just skip the branch for this one"* — push back unless it genuinely qualifies as trivia.

---

## Token efficiency

Break these when they conflict with correctness or you start thrashing. A wrong fix from a too-narrow read costs more than the re-read would have.

- **Read narrowly.** When you know the section you need, use `Read` with `offset`/`limit`. SKILL.md files are long — use offset/limit when you know which step you need.
- **Don't re-read files you just edited.** The harness tracks state after `Edit`/`Write` succeed.
- **Filter command output.** Pipe `gh ... --jq`, `grep`, `head`, `tail`. Default `gh issue list` returns ~15KB; with `--jq 'map({number, title})'` it's <2KB.
- **One source of truth per question.** When `gh project item-list` answers it, don't also read the snapshot table in `CLAUDE.md`.
- **For long sessions, suggest `/clear` between unrelated work.**

### When to widen (don't ask permission — the discipline yields automatically)

- **Debugging across files** — start wide (changed file + callers + failing path), narrow once the root cause is found.
- **Refactoring a repeated pattern** — `grep` every call site and read them up front; peepholing invites inconsistency.
- **First contact with an unfamiliar subsystem** — read the relevant `plugins/CLAUDE.md`, rules file, and entry-point source in full before narrowing.
- **Three-strikes thrashing** — if you've said *"let me read a bit more of X"* three times, widen decisively.
- **Surprising tool output** — a check/test failure on code you didn't touch: read enough to tell real regression from noise, don't filter it away.
