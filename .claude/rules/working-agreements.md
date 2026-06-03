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
  - `feat/4-zitadel-auth`
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
| User mentions a discrete idea/bug/refactor | `gh issue create -t "<title>" -b "<body>" -l <labels>` (auto-added to project). Set Project fields: `Area`, `Priority`. Then report back: *"filed as #N — title, labels=…, Area=…, Priority=…. Anything you'd add?"* |
| User says something ambiguously trackable | Ask first: *"Should I file this as an issue, or handle it inline?"* |
| Substantive new feature surfaces | Ask 2–3 clarifying questions (*who uses this? what triggers it? what's the simplest version that ships?*), then `gh issue create` with a real body |
| Picking up a tracked issue #N | Follow read → architect → plan → review → execute (see "How we work through issues"). **Don't run `git checkout -b` or flip Status until the user has signed off on the approach.** Once approved: `git checkout -b <type>/N-<slug>`, set Status → In Progress, `gh issue comment N -b "<one-line plan>"`. |
| Implementing | Read source first (narrow when possible), propose before destructive changes, verify before push |
| Hit a blocker | Set Status → Blocked, `gh issue comment N -b "blocked on: <one-line reason>"` |
| Out-of-scope item surfaces mid-PR | Push back, propose a new issue, `gh issue create …`, keep current PR focused |
| Decision worth logging surfaces | Add an entry to `.claude/rules/decisions.md` per the format in "When to log a decision" |
| Shipping | PR body ends with `Closes #N`, `gh pr merge <PR> --squash`; if target ≠ default branch, follow up with `gh issue close N` and flip Status to Done manually |
| Stale items in Todo for weeks | Surface for user: *"#N has been Todo since <date> — still relevant or close as wontfix?"* — user makes the call, never auto-close |

---

## How we work through issues

Tracked issues follow **read → architect → plan → review → execute**. The user drives intent; Claude proposes structure.

### The five phases

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

   In both modes: **don't start implementing until the user signs off on the approach.** "Sign off" is explicit — *"yes, do it"* or *"start with step 1"*. Silence is not approval.

5. **Execute.** `git checkout -b <type>/<N>-<slug>`, flip Status → In Progress, implement step-by-step. If a step turns out wrong mid-execution, surface it before continuing — don't silently improvise.

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

---

## What goes in a PR description

- One-paragraph summary of what changed and why (not what the issue body said — assume the reader follows `Closes #N`).
- Short test plan / verification steps if behaviour changed.
- `Closes #N` (or `Closes #N, #M` for tightly coupled multi-issue PRs — rare but valid).

---

## When to update what

| When (concrete trigger) | What to update |
|---|---|
| A skill's behaviour changes | Update the relevant `SKILL.md` in the same commit |
| A "Pending" row in root `CLAUDE.md` ships | Move it to "Done" in the snapshot table (Project is live source — table is just a hint) |
| Issue ships via PR | Close via `Closes #N` in PR body |
| New gotcha / constraint discovered | Append to `plugins/CLAUDE.md` or relevant `.claude/rules/<topic>.md` |
| Decision worth logging (see "When to log a decision") | Add entry to `.claude/rules/decisions.md` |
| Stale fact found (a function renamed, a path moved) | Correct it in place — same commit as the rename if possible |

---

## When to log a decision

`.claude/rules/decisions.md` is the *why* — separate from this doc (the *what*) and the GitHub Project (the *current state*).

**Add an entry when one of these triggers fires:**
- A rule lands in this doc whose *why* would be non-obvious in 3 months.
- A multi-week debate ended. Capture the resolution **and** the alternative considered.
- A pivot or scope change at the project level.
- A path *not* taken that someone might re-propose.
- A constraint that's load-bearing but invisible from the code.

**Don't log:**
- Routine implementation choices (variable names, file layout)
- Decisions captured cleanly in a PR description or issue thread that nobody will re-litigate
- Bug-fix rationale — the commit message is enough

**Format:**

```
## YYYY-MM-DD — <one-line decision title>
**Decision:** <one sentence>
**Why:** <one or two sentences — the load-bearing reason, not the obvious context>
**Status:** Active / Superseded by <YYYY-MM-DD entry> / Reversed
```

Never delete or rewrite an entry. When a decision is overturned, mark it `Superseded by …` and add a new entry.

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
