---
name: bootstrap-working-agreements
description: Bootstrap a new repo with the full working-agreements + GitHub Project + CLAUDE.md hub-and-spokes setup in one pass. Use on a fresh repo, or on an existing repo that has no .claude/ tooling yet. Calls github-project-setup and split-claudemd as sub-steps; writes .claude/rules/working-agreements.md and a starter root CLAUDE.md from templates with project-specific values filled in.
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash(gh *)
  - Bash(git *)
  - Bash(ls *)
  - Bash(find *)
  - Bash(grep *)
  - Bash(test *)
  - Bash(mkdir *)
  - Bash(wc *)
---

# /bootstrap-working-agreements — One-shot project setup

The goal: in one pass on a fresh (or fresh-to-tooling) repo, lay down everything that makes future Claude sessions productive — GitHub Project, working agreements, roadmap, CLAUDE.md hub + spokes — with project-specific values substituted in (not generic placeholders left for the user to fill in later).

**This skill proposes and waits for confirmation before writing anything.** Almost every value is project-specific.

---

## Step 0 — Working tree check

This skill writes multiple files (`.claude/rules/working-agreements.md`, root `CLAUDE.md`, optional spokes) and calls into `github-project-setup` (which writes more). Before any changes, give the user a clean baseline to `git diff` against if something goes wrong:

```bash
git status --short
```

**If the output is non-empty**, halt and report:

> Uncommitted changes in `<N>` files:
> ```
> <git status --short output, truncated to 10 lines if longer>
> ```
> This skill writes several new and modified files across the repo. If anything goes wrong you'll want a clean baseline. Commit/stash first, or continue anyway?

Wait for explicit *"continue"* before proceeding. Don't proceed silently.

**If `git status --short` errors** (not a git repo), warn the user and ask whether to proceed without a revert baseline. Recommend `git init` first.

---

## Step 0.5 — Check `.gitignore` for `.claude/` patterns

This skill writes durable rules under `.claude/rules/` that need to be committed. A directory-level ignore (`.claude/` with a trailing slash) silently excludes them — git can't re-include children of a fully-excluded directory, so `.claude/rules/working-agreements.md` won't show up in `git status` until someone notices.

```bash
grep -nE '^\.claude/?$' .gitignore 2>/dev/null
```

If a `.claude/` line is found, propose the carve-out fix — replace it with:

```
.claude/*
!.claude/rules/
```

(plus a one-line comment: *"durable team contract committed; other Claude session state stays local"*). Wait for explicit user confirmation before editing — `.gitignore` changes affect what the team commits and shouldn't be silent.

After the fix, verify:

```bash
git check-ignore -v .claude/rules/working-agreements.md
```

Should report **NOT IGNORED** (no output, exit code 1).

Three cases:
- **`.gitignore` has `.claude/` (directory ignore)** → propose the carve-out, wait for confirmation, then edit.
- **`.gitignore` has `.claude/*` already** → no change needed; the carve-out pattern is the desired state.
- **`.gitignore` doesn't mention `.claude/` at all** → no change needed; rules will be tracked by default.

If `.gitignore` doesn't exist, skip silently — the rules will be tracked by default.

---

## Step 1 — Preflight checks

Run in parallel:

```bash
gh auth status 2>&1 | grep -E 'scope|Logged'
git rev-parse --show-toplevel 2>&1
gh repo view --json nameWithOwner,defaultBranchRef -q '{repo: .nameWithOwner, default: .defaultBranchRef.name}'
test -f CLAUDE.md && echo "CLAUDE.md exists" || echo "no CLAUDE.md"
test -f .claude/rules/working-agreements.md && echo "working-agreements exists" || echo "no working-agreements"
ls -d */ 2>/dev/null | grep -vE '^(node_modules|\.git|__pycache__|\.venv|dist|build|design)/$'
```

Required scopes on the gh token: `repo`, `project`. If `project` is missing, instruct: `gh auth refresh -s project`.

If `CLAUDE.md` already exists and is >150 lines, recommend running `/split-claudemd` first instead of overwriting — surface this before proceeding.

If `.claude/rules/working-agreements.md` already exists, **do not overwrite**. Ask: *"working-agreements.md exists. Skip rewriting it, or back up the existing one and replace?"*

---

## Step 2 — Gather project-specific values (sequential questions)

Ask questions one at a time, in order. Each question should include a suggested default and brief context so the user understands why it matters — they confirm or adjust, rather than thinking from scratch. Capture all answers, then **echo back a single confirmation table before proceeding to Step 3**. Do not write any files until the user confirms.

**Q1 — Project name**
Say: *"What should we call this project? This will be the title of the GitHub Project board we're about to create — a shared board where you and I will track features, bugs, and decisions across sessions. Default: `<repo-name>`."*

If the user hasn't heard of GitHub Projects before, add: *"Think of it as a lightweight issue tracker built into GitHub. Once set up, I'll use it to record what we've decided, what's deferred, and what's in flight — so nothing gets lost between sessions or machines."*

**Q2 — What this project is**
Say: *"Give me one paragraph describing what this project is — who uses it, what shape it takes (web app / CLI / library / service), and the most important constraint I should know about on turn 1. I'll use this to get up to speed at the start of every future session, so the more specific you are, the less you'll have to re-explain."*

A vague answer here produces vague context in every future session. If the user gives a one-liner, gently ask for more.

**Q3 — Main working branch**
Say: *"What branch does finished work land on? This is usually `main` or `develop` — the branch you merge pull requests into. Default: `<default-branch>`."*

If the user asks why it matters: *"I use this to know where to target pull requests, and to handle the edge case where GitHub's auto-close keyword only fires on merges into this branch."*

Capture as `<integration-branch>`. If the user names a branch other than the repo's default, note it explicitly — it will appear throughout the working agreements.

**Q4 — Subdirectories that need their own context file**
Show the top-level directory list (minus build artefacts). Say: *"Claude automatically loads a `CLAUDE.md` file from whichever directory you're working in. This lets different parts of the codebase have their own conventions without cluttering the root. Of these directories — `<list>` — which have their own patterns, gotchas, or constraints worth capturing separately? It's fine to say none."*

If the repo is flat or the user says none, skip Step 6 entirely. Don't force the pattern onto a repo that doesn't need it.

**Q5 — Any unusually large files?**
Say: *"Are there any files in this repo that are very long — hundreds or thousands of lines — where I should read only the relevant section rather than the whole thing? If so, name 1–2. If not, just say no."*

If the user names files, these become concrete examples in the token-efficiency guidelines. If they say no or the repo has no large files yet, drop the bullet entirely rather than leaving a placeholder.

**Q6 — Release planning style**
Say: *"How do you ship? Two options:*
- *Milestone-based — you plan discrete releases (Alpha, Beta, GA or similar). I'll create GitHub milestones, a roadmap file, and tracking issues that show what needs to land before each release.*
- *Continuous flow — you ship whenever something is ready, no fixed release boundaries. Simpler board, no milestone overhead.*

*Which fits how you work?"*

If milestones: ask for names + a one-line description of what "done" means for each. This drives whether Step 3 creates milestones and whether `.claude/rules/roadmap.md` is written.

**Q7 — Any existing to-do list to import?**
Say: *"Do you have an existing list of planned work — a TODO.md, ROADMAP.md, deferred.md, or similar — that you'd like converted into GitHub issues? If yes, I'll turn each item into a tracked issue on the board. If no, we start with an empty board."*

If yes, capture the file path. If no, move on.

**Q8 — Are there files or commands Claude should never touch?**
Say: *"Some projects have files that are easy to accidentally break — CI config, deployment scripts, infrastructure definitions. Are there any files I should never edit without you explicitly asking? Also, is there a specific command you use to run or deploy this project locally that I should always use instead of improvising?"*

Default: no — skip this entirely if the user says no or doesn't know yet. They can add it later by editing `working-agreements.md`. If yes, ask:
- *Which files are off-limits?* (e.g. `docker-compose.yml`, `.github/workflows/*.yml`, `terraform/*.tf`)
- *What's the canonical run/deploy command?* (e.g. `./run.sh`, `docker compose up`)
- *How do changes ship to production?* (e.g. "CI/CD on merge to main", "manual deploy")

If the user skips, drop the entire "Infrastructure boundaries" section — don't write it with `TBD`s.

**Q9 — Solo or working with a team?**
Say: *"Will you be the only one pushing to this repo, or is there a team? This changes how I handle finished work:*
- *Solo — I commit, push, and merge automatically once we've agreed on an approach. Fast, low overhead.*
- *Team — I open a pull request and stop. Your teammates review and merge. Nothing lands without a human approving it.*"

Check `git log --format='%ae' | sort -u` — if multiple email addresses exist, suggest team as the default. Otherwise suggest solo.

Capture as `<collaboration-mode>` (`solo` or `team`).

**Q10 — How should branches be merged?**
Say: *"When a pull request is ready to merge, which strategy do you prefer?*
- *Squash (recommended for most projects) — all the commits from the branch collapse into one clean commit on `<integration-branch>`. Simple history, easy to read.*
- *Regular merge — each commit from the branch lands individually. Good if the step-by-step history matters for debugging later.*
- *Rebase — commits are replayed onto `<integration-branch>` one by one, no merge commit. Cleanest-looking history, slightly more complex.*"*

Suggest squash for solo, ask for team. Capture as `<merge-policy>` (`squash`, `regular`, or `rebase`).

**Q11 — Can small fixes go straight to `<integration-branch>`?**
Say: *"For tiny changes — a typo fix, a one-line config tweak — should I commit directly to `<integration-branch>`, or does everything go through a branch and pull request?*
- *Direct commits allowed — fine for genuine trivia, saves overhead on small things.*
- *Always use a branch — every change goes through a PR, no exceptions. Common when `<integration-branch>` is protected.*"*

Default: allowed for solo, never for team. Capture as `<direct-to-main>` (`allowed` or `never`).

---

**Confirmation table** — after all 11 answers, echo back before proceeding:

| Question | Answer |
|---|---|
| Project name | `<value>` |
| What it is | `<first sentence of paragraph>` |
| Integration branch | `<value>` |
| CLAUDE.md spokes | `<list or "none">` |
| Large files | `<list or "skipped">` |
| Milestones | `<list or "continuous-flow">` |
| Planning doc | `<path or "none">` |
| Deploy constraints | `<summary or "skipped">` |
| Mode | `<solo or team>` |
| Merge policy | `<squash / regular / rebase>` |
| Direct commits to `<integration-branch>` | `<allowed or never>` |

When `<collaboration-mode>` = `team`, add explicitly:
> **Mode: Team** — merge policy: `<merge-policy>`, direct commits to `<integration-branch>`: `<direct-to-main>`, auto-merge: off — Claude opens PRs and stops.

Wait for explicit confirmation before proceeding to Step 3.

---

## Step 3 — Run github-project-setup

Invoke `/github-project-setup` (or the equivalent in this plugin: `/claude-project-bootstrap:github-project-setup`).

Pass through the answers from Step 2 so it doesn't re-ask: project name, milestone list, doc-to-migrate path. That skill handles:
- Creating the GitHub Project (or extending an existing one)
- Tier / Area / Priority / Effort custom fields with project-specific options
- Standard labels (`frontend`, `backend`, `infra`, `feature`, `bug`, `tech-debt`)
- Issue templates at `.github/ISSUE_TEMPLATE/feature.yml` and `bug.yml`
- `.claude/rules/roadmap.md` populated from its template (if milestones enabled)
- Tracking issue per milestone
- Optional planning-doc migration into auto-added issues

Wait for it to complete. Capture: project URL, project number, milestone names, field names actually created (Tier/Area defaults may have been customised), **`<project-scope>`** (`single-repo` or `multi-repo`), and **`<strategic-field>`** (the strategic axis chosen — `Tier` for single-repo, `Initiative` for multi-repo).

---

## Step 4 — Write `.claude/rules/working-agreements.md`

Read the bundled `templates/working-agreements.md`. Substitute these placeholders before writing:

| Placeholder | Replace with |
|---|---|
| `<integration-branch>` | The branch from Step 2 question 3. Multiple occurrences. |
| `<example-large-file-1>` and `<example-large-file-2>` | The two file names from Step 2 question 5. If the user named only one, drop the second from the bullet so it doesn't read as a placeholder. |
| `<owner>` | The repo's owner from Step 1's `gh repo view`. Used in cross-repo refs and in the "Setting Issue type" subsection. |
| `<strategic-field>` | From Step 3 — `Tier` (single-repo) or `Initiative` (multi-repo). Multiple occurrences across the lifecycle row, "Cross-repo Project contract" section, and the report-back template. |
| `<configured-issue-types>` | The comma-separated set of org issue type names (e.g. `Bug, Feature, Task`). Resolve via Step 4a below — or strip type-related clauses entirely if the org has none configured. |
| `<deploy-flow>` | From Step 2 question 8, sub-q 1. |
| `<local-deploy-command>` | From Step 2 question 8, sub-q 2. If the user said there's no canonical command, drop the entire "Canonical local dev/deploy command" paragraph rather than leaving a placeholder. |
| `<hands-off-file-1>`, `<hands-off-file-2>`, … | From Step 2 question 8, sub-q 3. Add or remove bullet rows to match the user's actual list. If zero files, drop both bullets and the surrounding paragraph. |
| `<mode-line>` | One-liner at the top of "Commits and merging" reflecting the selected mode. Compose from `<collaboration-mode>`, `<merge-policy>`, and `<direct-to-main>` — see the mode-line table below. |
| `<shipping-row>` | The lifecycle table's shipping row. Solo: include `gh pr merge` command per `<merge-policy>`. Team: `PR body ends with \`Closes #N\`. Open the PR and stop — do not merge.` |
| `<trivia-rule>` | The direct-commit paragraph in "Branch and PR strategy". If `<direct-to-main>` = `allowed`: keep the current "Trivia → direct commits" paragraph. If `never`: replace with `All changes go through a branch + PR — no direct commits to \`<integration-branch>\`, regardless of size.` |

**Mode-line compositions:**

| `<collaboration-mode>` | `<merge-policy>` | `<direct-to-main>` | `<mode-line>` |
|---|---|---|---|
| solo | squash | allowed | `**Mode: Solo — Claude squash-merges automatically. Direct commits to \`<integration-branch>\` allowed for trivia.**` |
| solo | regular | allowed | `**Mode: Solo — Claude regular-merges automatically. Direct commits to \`<integration-branch>\` allowed for trivia.**` |
| solo | rebase | allowed | `**Mode: Solo — Claude rebase-merges automatically. Direct commits to \`<integration-branch>\` allowed for trivia.**` |
| solo | any | never | Same as above but append: `All changes via PR.` |
| team | squash | never | `**Mode: Team — Claude opens PRs and stops; humans squash-merge. All changes via PR.**` |
| team | regular | never | `**Mode: Team — Claude opens PRs and stops; humans regular-merge. All changes via PR.**` |
| team | rebase | never | `**Mode: Team — Claude opens PRs and stops; humans rebase-merge. All changes via PR.**` |
| team | any | allowed | Same team line but append: `Direct commits to \`<integration-branch>\` allowed for trivia.` |

**Conditional sections — strip per project shape:**

- **If `<project-scope>` = `single-repo`**, strip the entire `## Cross-repo Project contract` section (heading through trailing `---`). It's a multi-repo concept; including it on a single-repo project just adds noise.
- **If the user had no answers to any sub-question of Step 2 question 8**, strip the entire `## Infrastructure boundaries` section. Half-filled placeholders are worse than no section.
- **If the org has no GitHub issue types configured** (Step 4a returns no types), strip the entire `### Setting Issue type` subsection **and** strip the bolded "*then immediately set the GitHub issue type…*" clause from the lifecycle table's filing row (leave the rest of the row intact).

**Do not substitute** the example branch names (`feat/4-zitadel-auth`, `fix/22-rate-limit`, etc.) — they are illustrative of the *shape* of the convention, not project-specific. Leave them.

Write the file. Then `mkdir -p .claude/rules/` first if needed (it usually already exists from `github-project-setup`).

### Step 4a — Discover the org's configured GitHub issue types

GitHub Issue types are an **org-level** feature, configured in **Org Settings → Repository policies → Issue types**. The template's lifecycle row + "Setting Issue type" subsection use the type names directly via REST PATCH (no node-ID lookup needed). Discover the configured set:

```bash
gh api orgs/<owner>/issue-types --jq '[.[].name] | join(", ")'
```

Three outcomes:

1. **Names returned** (e.g. `Bug, Feature, Task` — the GitHub defaults): substitute the comma-separated list into `<configured-issue-types>`. Done.
2. **403 "resource not accessible by personal access token"**: fine-grained PATs commonly lack org admin scope for list endpoints while still allowing per-issue reads. **Fall back to sampling existing issues**:

   ```bash
   gh issue list -R <owner>/<repo> --limit 5 --json number --jq '.[].number' \
     | xargs -I{} gh api repos/<owner>/<repo>/issues/{} --jq '.type.name' \
     | sort -u | grep -v null
   ```

   If the sample returns concrete type names, treat it as outcome 1 (substitute and proceed). If everything is `null`, treat it as outcome 3.

3. **Empty / all null**: types aren't enabled for this org, **or** the repo is user-owned (personal repos don't get this feature). Strip the type-related clauses per the conditional rule in Step 4's substitution table. Tell the user: *"GitHub Issue types unavailable for `<owner>` — skipped the `Setting Issue type` subsection and the related clause in the lifecycle table. Enable in Org Settings → Repository policies → Issue types if you want it later."*

If the org uses non-standard type names (e.g. renamed `Feature` to `Story`), the substituted `<configured-issue-types>` will reflect the actual set — no manual mapping needed because the template's PATCH command uses names verbatim, not labels.

---

## Step 4b — Write `.claude/rules/decisions.md` starter

`decisions.md` records *why* — separate from `working-agreements.md` (the *what*) and the GitHub Project (the *current state*). The format and "when to log" rules live in `working-agreements.md`; `decisions.md` itself is just the running log.

Read the bundled `templates/decisions.md` and `Write` it to `.claude/rules/decisions.md` **with no substitutions** — it's a static starter (header + one HTML-comment-wrapped example entry). The user populates it as they make decisions worth logging.

If `.claude/rules/decisions.md` already exists, **do not overwrite**. One-line confirmation: *"decisions.md exists — leaving it alone"*.

Brief note to the user after writing: *"decisions.md is empty except for the format example. The first real entry should usually capture a decision that prompted this bootstrap (e.g. choosing this project's tier/area taxonomy, or rejecting an alternative tooling approach). I'll prompt you to log decisions as we work."*

---

## Step 5 — Write or update root `CLAUDE.md`

Two paths:

### 5a. No existing `CLAUDE.md`
Read `templates/CLAUDE.md.root`. Substitute:

| Placeholder | Replace with |
|---|---|
| `<project-name>` | From Step 2 question 1. Multiple occurrences. |
| `<one paragraph: what this project does …>` | From Step 2 question 2. |
| `<owner>` and `<N>` | From `gh project view` output captured in Step 3. |
| `<project-url>` | The Project URL from Step 3. |
| `<integration-branch>` | From Step 2 question 3. |
| `<subdir-1>`, `<subdir-2>`, … | From Step 2 question 4. Drop unused rows. |
| `<concrete release criterion>` | Ask: *"What has to be true before `<integration-branch>` merges to `main`?"* — one-liner. If user says "not yet decided", write `TBD — set this when defined`. |

Leave the "What's built vs pending" status table empty with one example row commented out — the user populates it as features ship.

Write to `CLAUDE.md`. Run `wc -l CLAUDE.md` and confirm it's <150 lines (well under Anthropic's 200-line cap).

### 5b. Existing `CLAUDE.md` to merge into
Don't overwrite. Use Edit to:
- Add the "Detailed guidance" list with pointers to `working-agreements.md` and `roadmap.md` if missing.
- Add the "Working agreements" section pointing to `.claude/rules/working-agreements.md`.
- Leave the rest alone.

If the existing file is >150 lines, recommend running `/split-claudemd` after this skill completes.

---

## Step 6 — Write spoke `CLAUDE.md` files (optional)

For each subdir confirmed in Step 2 question 4 that doesn't already have a `CLAUDE.md`:

Read `templates/CLAUDE.md.spoke`. Substitute:

| Placeholder | Replace with |
|---|---|
| `<subdir-name>` | This subdir's name. |
| `<other-subdir>` | The other subdir(s) — use the most-coupled one. |
| `<topic>` | A relevant topic file name if any was created (often "" — leave the line as a hint). |
| `<project>` and `<project-url>` | From Step 3. |
| `<this-area>` | The Area field option that maps to this subdir (e.g. `Frontend`, `Backend`). |

The body sections (`<Topic 1>`, `<Topic 2>`, etc.) stay as placeholders — these get filled as the user works in that subdir and discovers conventions worth recording. **Don't try to invent gotchas the user hasn't surfaced yet.**

Write each spoke. Confirm: *"Wrote `<subdir>/CLAUDE.md` as a starter — it has placeholders for topic-specific gotchas which you fill in as you discover them."*

---

## Step 7 — Sanity check + handoff

Run in parallel:

```bash
wc -l CLAUDE.md .claude/rules/working-agreements.md .claude/rules/roadmap.md .claude/rules/decisions.md
ls .github/ISSUE_TEMPLATE/
gh project view <N> --owner <owner> --format json --jq '{title, items: .items.totalCount, fields: [.fields[].name]}'
```

Report back to the user as a single block:
- Files created (with line counts)
- Project URL
- Number of issues created (if a doc was migrated)
- Milestones created (if any)
- Three things to verify in the GitHub UI: auto-add-to-project workflow, item-closed → Status:Done workflow, auto-archive after 2 weeks

Do not commit. The user reviews the diff and commits.

---

## Common failure modes

- **Step 3 fails because `gh auth status` lacks `project` scope** — easy to miss because most repos don't need it. Halt and instruct `gh auth refresh -s project` before continuing.
- **Step 4's `working-agreements.md` lands with an unfilled `<integration-branch>`** — the user said `main` but the substitution missed an occurrence. Grep the written file for `<` and report any that survived.
- **Existing `CLAUDE.md` is already a hub-and-spokes** — don't double-add the "Working agreements" section. Grep for `working-agreements.md` in the file before appending.
- **No subdirs deserve their own CLAUDE.md** (single-package repo, library) — skip Step 6 entirely. Don't force the spoke pattern onto a flat repo.
- **User answered Step 2 question 5 with "no large files yet"** — drop the `<example-large-file-*>` bullet entirely instead of leaving it as a placeholder. The token-efficiency rule still works without that one bullet.

---

## What this skill does NOT do

- Doesn't create the GitHub repo itself — assumes you've already run `gh repo create` or pushed to one.
- Doesn't push commits — the user reviews and commits.
- Doesn't enable Project workflows in the UI — those are manual (Step 7 handoff lists them).
- Doesn't add language-specific tooling (lint configs, test setup, CI) — out of scope; this is the *collaboration framework* setup.
