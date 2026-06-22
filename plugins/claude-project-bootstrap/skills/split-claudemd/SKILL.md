---
name: split-claudemd
description: Refactor a long root CLAUDE.md into a hub root + subdirectory spokes + .claude/rules/ topic files — use when the root CLAUDE.md nears Anthropic's line cap (~200 as of writing) or gets hard to maintain.
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash(ls *)
  - Bash(find *)
  - Bash(wc *)
  - Bash(test *)
  - Bash(mkdir *)
---

# /split-claudemd — Refactor CLAUDE.md into hub-and-spokes

The goal: a short root `CLAUDE.md` that anyone can read in 30 seconds, with longer detail pushed to per-subdirectory `CLAUDE.md` files (Claude Code auto-loads these when the cwd is inside that subtree) and topic files under `.claude/rules/`.

**Hard constraint — root `CLAUDE.md` only.** Anthropic truncates the project root `CLAUDE.md` at **200 lines as of writing**. Anything past the cap is silently dropped from the model's context — no warning to the user. **Target ≤150 lines** for the root to leave headroom. If you suspect the cap has changed, verify against current Claude Code docs before relying on the number.

**Sub-`CLAUDE.md` files** (`frontend/CLAUDE.md`, `backend/CLAUDE.md`, etc.) are **not subject to the 200-line cap** — they auto-load in full when Claude Code's cwd is inside that subtree. No hard cap, but keep them under ~250 lines as a soft target so they stay scannable and don't become new monoliths.

**Topic files under `.claude/rules/`** are not auto-loaded — they're read on demand when something points to them. No cap, no soft target, but split if a single topic file turns into a reference manual.

This skill **proposes** a split and waits for confirmation before writing. The right split is project-specific — never auto-refactor.

---

## Step 0 — Working tree check

This skill writes files (root `CLAUDE.md`, new spokes, topic files). Before any changes, give the user a clean baseline to `git diff` against if something goes wrong:

```bash
git status --short
```

**If the output is non-empty**, halt and report:

> Uncommitted changes in `<N>` files:
> ```
> <git status --short output, truncated to 10 lines if longer>
> ```
> This skill rewrites your root `CLAUDE.md` and may write new spoke files. If anything goes wrong you'll want a clean baseline. Commit/stash first, or continue anyway?

Wait for explicit *"continue"* before proceeding. Don't proceed silently.

**If `git status --short` errors** (not a git repo), warn the user and ask whether to proceed without a revert baseline. Recommend `git init` first.

---

## Step 1 — Survey the project

Run in parallel:
- `wc -l CLAUDE.md` (Anthropic truncates at 200 lines; if the file is already comfortably under ~150 the user may not need this skill — confirm before proceeding)
- `ls` at repo root to identify top-level directories
- `find . -maxdepth 3 -name CLAUDE.md` to find existing sub-CLAUDE.md files
- `test -d .claude/rules && ls .claude/rules` to see if topic files already exist

Read the root `CLAUDE.md` in full.

If a subdirectory CLAUDE.md already exists, read it too — the skill should merge into it, not overwrite it.

## Step 2 — Identify split candidates

Classify each section of the root CLAUDE.md into one of four buckets:

**Keep in root (the hub):**
- One-paragraph "what this project is"
- Product/feature status table (built vs pending)
- Cross-cutting commands (how to run frontend, backend, tests)
- Branch strategy, deploy strategy
- A "keeping these files current" meta-rule that points to the spokes
- A table of contents linking to every spoke

**Move to `<subdir>/CLAUDE.md`:**
- Anything specific to one top-level directory (frontend component conventions, backend data flow, infra/Terraform notes)
- Gotchas, constraints, and decisions that only apply when working in that subtree
- If the section names a directory in its heading or its body refers almost exclusively to files under one subtree → it belongs there

**Move to `.claude/rules/<topic>.md`:**
- Long topic-specific sections that span multiple subdirs (deferred features, domain rules, naming conventions, a particular subsystem's design)
- Anything the user has clearly written as a reference document rather than as guidance

**Drop entirely (propose, don't auto-delete):**
- Stale "TODO" notes that have shipped
- Duplicated content already obvious from the code
- Commentary that reads like a journal entry

## Step 3 — Propose the split

Present the proposal as a tree, with one-line descriptions of what goes where and rough line counts. Example:

```
CLAUDE.md (root, ~80 lines)
  ├── what <project> is, tiers, architecture diagram
  ├── built-vs-pending table
  ├── run commands, branch strategy
  └── TOC linking to spokes

frontend/CLAUDE.md (~60 lines)  [NEW — currently mixed into root]
  └── component status, design rules, CSS gotchas, caching

backend/CLAUDE.md (~70 lines)  [EXISTS — append data flow + scheduler sections]
  └── data pipeline, DB schema, scheduler jobs

.claude/rules/deferred.md (~50 lines)  [NEW]
  └── all "deferred" / "planned" features

DROP:
  └── "Migration notes from v0" section — migration shipped <date>
```

**Verify the proposed root fits the cap before showing the tree.** Sum the rough line counts you've assigned to root sections (including blank lines, the TOC, and headings). If the total exceeds **150 lines**, push more content into spokes before presenting the proposal — do not propose a root that's already near the 200-line cliff.

Then ask: *Does this split look right? Anything to move, merge, or keep in root?*

**Wait for confirmation.** Do not write files until the user agrees (or asks for adjustments).

## Step 4 — Write the files

After confirmation:

1. **Write spokes first** — each new `<subdir>/CLAUDE.md` and each `.claude/rules/<topic>.md`. If a subdir CLAUDE.md already exists, use Edit to append, not Write to overwrite.
2. **Rewrite the root `CLAUDE.md`** as a hub with a clear TOC. Sample shape:

   ```markdown
   # CLAUDE.md

   ## What <project> is
   <one paragraph>

   ## <built vs pending / status table>

   ## Running it
   <commands>

   ## Detailed guidance (auto-loaded by subdirectory)

   - `frontend/CLAUDE.md` — <one-line summary>
   - `backend/CLAUDE.md` — <one-line summary>
   - `.claude/rules/<topic>.md` — <one-line summary>

   ## Keeping these files current
   <meta-rule: when X changes, update Y>
   ```

3. **Do not delete the original CLAUDE.md content** by accident — every paragraph either lands in a spoke, lands in the new root, or was explicitly approved for drop in step 3.

4. After writing, run `wc -l` on every file you touched and report the before/after sizes in one line each.

## Step 5 — Verify and hand off

After writing, **re-run `wc -l` on the root and every spoke**. Then enforce:

- **Root `CLAUDE.md` >200 lines: fail loud.** This crosses Anthropic's hard truncation cap. Don't stop at warning — identify the largest section that could move and propose a follow-up edit before handing off.
- **Root `CLAUDE.md` 150–200 lines:** warn the user that headroom is thin and offer to push more into a spoke.
- **Any sub-`CLAUDE.md` >250 lines:** soft warning only. No hard cap on these, but flag it as a candidate for a future split.

Tell the user:
- What was created vs edited
- Final line count of the root (must be ≤200; ideally ≤150) plus per-spoke counts
- A reminder that the per-subdir files only auto-load when Claude Code's cwd is inside that subtree — so guidance for working *across* subtrees stays in the root

**Committing:** during initial bootstrap there's no `Mode` yet — don't auto-commit; the user reviews the first scaffold. When run **standalone** on a repo with established conventions, honor its `Mode` (from `working-agreements.md`): Solo → commit/merge per the repo's policy after a `/code-review` self-review; Team → present the diff and stop.

---

## Edge cases

- **Project has no clear subdirectory split** (single-package repo): skip subdir spokes, lean on `.claude/rules/<topic>.md` files instead.
- **`.claude/rules/` already exists with files**: read them first; merge new topics in, don't duplicate.
- **Existing subdir CLAUDE.md is already long**: offer a second pass to split *it* further (e.g. `frontend/components/CLAUDE.md`) only if the user asks — don't recurse automatically.
- **Repo isn't a git repo**: still works, but mention that the user can't easily diff-review without `git init`.
