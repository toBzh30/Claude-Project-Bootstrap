---
name: github-project-setup
description: Set up a GitHub Project (v2) for a repo with standardized statuses, custom fields (Tier/Area/Priority/Effort), labels, and issue templates. Optionally migrate an existing planning doc (deferred.md / TODO.md / ROADMAP.md / etc.) into auto-added issues. Use when the user wants to start tracking features/bugs/tech-debt in a structured project board, or asks how to convert a markdown todo list into one.
user-invocable: true
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash(gh *)
  - Bash(ls *)
  - Bash(find *)
  - Bash(grep *)
  - Bash(test *)
  - Bash(mkdir *)
  - Bash(rm *)
  - Bash(python3 *)
  - Bash(git *)
---

# /github-project-setup — Bootstrap a GitHub Project for a repo

The goal: a single project board that holds *all* in-flight work (features, bugs, tech-debt) with consistent custom fields so you can group, filter, and prioritise across types. The defaults below are battle-tested; the per-project work is choosing the right Tier/Area values and (optionally) migrating an existing planning doc.

**This skill proposes and waits for confirmation before creating issues or fields.** Names are project-specific — never auto-generate without a check.

---

## Step 0 — Working tree check

This skill writes files (issue templates, `roadmap.md`). Before any changes, give the user a clean baseline to `git diff` against if something goes wrong:

```bash
git status --short
```

**If the output is non-empty**, halt and report:

> Uncommitted changes in `<N>` files:
> ```
> <git status --short output, truncated to 10 lines if longer>
> ```
> This skill writes new and modified files. If anything goes wrong you'll want a clean baseline. Commit/stash first, or continue anyway?

Wait for explicit *"continue"* before proceeding. Don't proceed silently.

**If `git status --short` errors** (not a git repo), warn the user and ask whether to proceed without a revert baseline. Recommend `git init` first.

---

## Step 1 — Preflight

Verify gh auth and scope:

```bash
gh auth status 2>&1 | grep -i scope
```

If `project` is missing from token scopes, ask the user to run:

```bash
gh auth refresh -s project
```

`project` covers both read and write. Without it, every `gh project` call will 403.

Identify the repo and owner:

```bash
gh repo view --json nameWithOwner -q .nameWithOwner
```

This is `owner/repo`. The Project lives under the owner (user or org), not the repo.

---

## Step 2 — Discover existing planning state

Read in parallel:
- Root `CLAUDE.md` if present — gives you the project's vocabulary (product tiers, area names, current priorities).
- Any `deferred.md`, `TODO.md`, `ROADMAP.md`, `BACKLOG.md` under `.claude/rules/` or repo root.
- Existing labels: `gh label list -R <owner>/<repo>`.
- Existing project (the user may already have one): `gh project list --owner <owner>` — if yes, ask whether to extend it or create new.

Use what you read to **propose** the field values. Don't ask the user to invent them from scratch.

---

## Step 3 — Propose Tier and Area values

These two fields are the most project-specific. Don't hardcode.

**Tier** — the dimension users want to see in the Roadmap view. Common patterns:

| Project type | Tier values |
|---|---|
| Multi-tier consumer product (Free/Paid/Premium) | Product tiers, e.g. `Novice / Amateur / Pro / Infra / Tech-debt` |
| Internal tool / B2B | `Now / Next / Later / Tech-debt` |
| Library or SDK | (skip Tier entirely; use Priority alone) |
| Single-developer side project | `Core / Polish / Stretch / Tech-debt` |

**Area** — codebase split. Derive from the repo structure:

```bash
ls -d */ | grep -vE 'node_modules|\.git|__pycache__|\.venv|dist|build'
```

Top-level directories are usually the Area values (`Frontend`, `Backend`, `Infra`, `Design`, `Docs`).

Present the proposed values to the user as a table and ask for confirmation/edits before creating fields. Defaults that always apply:

- **Status**: `Todo / In Progress / Blocked / Done` (uses GitHub's default Status field; just add `Blocked` if missing).
- **Priority**: `P0 / P1 / P2`.
- **Effort**: `XS / S / M / L`.

---

## Step 4 — Create the project (if it doesn't exist) and fields

User-friendlier path: ask the user to create the empty project in the GitHub UI (`github.com/<owner>?tab=projects` → New project → Board template → name it). They click through once to see the UI; takes 30 seconds. Then they paste the URL or project number back, and you do the rest via gh.

CLI alternative if the user prefers automation:

```bash
gh project create --owner <owner> --title "<Project name>"
```

Once you have the project number, fetch the existing fields:

```bash
gh project field-list <N> --owner <owner> --format json > /tmp/fields.json
```

For each missing custom field, create it. Single-select fields use comma-separated options:

```bash
gh project field-create <N> --owner <owner> \
  --name Tier --data-type SINGLE_SELECT \
  --single-select-options "Novice,Amateur,Pro,Infra,Tech-debt"
```

Repeat for Area, Priority, Effort. The default Status field already exists and is editable via the UI (or `gh project field-update`) — add `Blocked` if it's not there.

After all fields exist, re-fetch `gh project field-list ... --format json` and **save the field IDs and option IDs** to a JSON file. You'll need them in Step 7.

---

## Step 5 — Create the standard label set

Default labels (skip any that already exist):

| Label | Color | Description |
|---|---|---|
| `frontend` | `1d76db` | Frontend work |
| `backend` | `0e8a16` | Backend work |
| `infra` | `5319e7` | Deployment, CI, ops |
| `feature` | `a2eeef` | New capability |
| `bug` | `d73a4a` | Something isn't working (usually pre-exists) |
| `tech-debt` | `fbca04` | Refactor / cleanup |

```bash
gh label create frontend --color 1d76db --description "Frontend work" -R <owner>/<repo>
# repeat for each
```

Adjust the set per project: a docs-heavy repo might add `docs`; a single-language library might drop `frontend`/`backend` and use module names instead. Ask the user before adding non-default labels.

---

## Step 5b — (Optional) Set up milestones

Ask: **"Do you want milestone-based release planning (Alpha/Beta/GA pattern), or continuous-flow shipping?"**

Skip this step for libraries, side projects, or any product without discrete release boundaries. For products shipping to real users in stages, this is the accountability mechanism — without it, scope drift is the default.

### What you build (when enabled)

Three artefacts that reinforce each other:

1. **GitHub Milestones** on the repo (title + one-line description). Source of truth for issue assignment + progress %.
2. **`.claude/rules/roadmap.md`** — the framework + per-milestone Bar / Out-of-scope / In-scope rationale. Auto-loaded so future sessions have scope in context.
3. **One tracking issue per milestone** (titled `[milestone] X — short bar`), assigned to that milestone, body containing the Bar + Out-of-scope + a checklist of sub-issue refs. Closing the tracking issue = "we shipped this milestone".

The Project's built-in `Milestone` field (no custom field needed) auto-mirrors the GitHub milestone — just add it to the Roadmap view.

### Tier ≠ Milestone

State this in the roadmap doc explicitly. Tier (e.g. Novice/Amateur/Pro) = which user surface this serves. Milestone (Alpha/Beta/GA) = which release we commit to ship it in. Some Amateur-tier issues land in Alpha (because they gate it); others in Beta. Don't auto-assign milestone from Tier.

### Procedure

1. **Propose milestone names + bars.** Read existing planning docs (CLAUDE.md, README, `consumer-product.md` or equivalent) to draft them. Show a table to user:

   | Milestone | Bar (one paragraph) | Out of scope (bullets) |

   Wait for confirmation/edits.

2. **Create the milestones**:

   ```bash
   gh api repos/<owner>/<repo>/milestones \
     -f title="Alpha" \
     -f description="Single-user end-to-end. See .claude/rules/roadmap.md for bar + out-of-scope." \
     -f state=open
   ```

   Repeat per milestone. Capture the milestone numbers — you need them in step 5 below.

3. **Write `.claude/rules/roadmap.md`** from `templates/roadmap.md` (bundled next to this skill). Fill in: framework header, Tier ≠ Milestone explainer, then one section per milestone with Bar / Tracking / In scope / Out of scope.

4. **Map existing issues to milestones.** Tier is a hint, not the answer — most Tier=Foundation issues belong to Alpha because they gate it; Tier=polish issues belong to GA. Show the mapping as a table for user confirmation, then apply:

   ```bash
   gh issue edit <N> -R <owner>/<repo> --milestone "Alpha"
   ```

5. **Identify gaps.** Things that need to ship for milestone X but don't have an issue yet (e.g. "E2E smoke test", "Test feedback channel", "Payment stub"). Open them as new issues — they auto-add to the project — and assign the milestone.

6. **Create the tracking issue per milestone**:

   ```bash
   gh issue create -R <owner>/<repo> \
     -t "[milestone] Alpha — single-user end-to-end" \
     -m "Alpha" \
     -b "$(cat <<'EOF'
   **Closing this issue = we shipped Alpha.**

   ## Bar
   <one paragraph from the table>

   ## Out of scope
   - …

   ## Sub-issues
   - [ ] #4 …
   - [ ] #5 …

   See `.claude/rules/roadmap.md` for the framework.
   EOF
   )"
   ```

   GitHub auto-checks the boxes when sub-issues close. The tracking issue itself has no `feature` / `bug` label — it's a meta-issue.

7. **Expose Milestone in the Project's Roadmap view.** UI step: open the project → Roadmap view → `+ Field` in the column headers → enable `Milestone`. Group by Milestone to see release-by-release progress.

### Doc cross-references

Add a row to root `CLAUDE.md`'s "Detailed guidance" list pointing at `roadmap.md`:

```
- `.claude/rules/roadmap.md` — release milestones (<list>), bars, out-of-scope. Source of truth for "is this in scope for the current milestone?"
```

---

## Step 6 — Add issue templates

Copy the bundled templates into the repo. They live next to this `SKILL.md`:

```
templates/feature.yml
templates/bug.yml
```

Destination:

```
<repo>/.github/ISSUE_TEMPLATE/feature.yml
<repo>/.github/ISSUE_TEMPLATE/bug.yml
```

For each template, **check before clobbering**:

1. `test -f <dest-path>` — does the destination already exist?
2. **If destination doesn't exist**: `Read` the bundled file, `Write` to the repo path. One-line confirmation: *"wrote feature.yml"*.
3. **If destination exists**: `Read` both source and destination.
   - If byte-identical, skip silently with a one-line note: *"feature.yml already matches bundled template — skipped"*.
   - If they differ, **do not overwrite**. Surface a short diff summary (line counts, top-level field names that differ) and ask: *"`.github/ISSUE_TEMPLATE/feature.yml` exists with different content. Overwrite, show full diff, or skip?"* — wait for explicit choice. Default-skip if the user is ambiguous.

Don't shell-copy — files might need path tweaks.

---

## Step 7 — (Optional) Migrate an existing planning doc to issues

If the user has a `deferred.md` (or similar) full of pending work, this is the highest-value step. Skip if no such doc exists or the user wants to start with an empty board.

The bundled `scripts/migrate_doc.py` is a starting point. Adapt it per project:

1. Read the source doc in full.
2. Parse each entry into an issue spec: `{title, body, labels, tier, area, priority, milestone}`. `milestone` is optional — only set if Step 5b ran.
3. **Show the user the planned issue list as a table** (title, labels, tier, area, priority, milestone) — *wait for confirmation before creating anything*.
4. Edit `scripts/migrate_doc.py` (copy to `/tmp/`) with:
   - `REPO`, `OWNER`, `PROJECT_NUMBER`, `PROJECT_ID`
   - Field IDs and option IDs from Step 4
   - The `ISSUES = [...]` array (each entry can include an optional `"milestone": "Alpha"` key)
5. Run it. The script: creates each issue, adds it to the project, sets Tier/Area/Priority, optionally sets the milestone via `gh issue edit -m`. Effort is left blank (user sizes during triage).
6. Verify: `gh project item-list <N> --owner <owner> --limit 50` should show all the new items. If milestones are in use, also check `gh issue list -R <owner>/<repo> --milestone "<name>" --limit 50`.

After the migration runs successfully, **delete the source doc** and update CLAUDE.md cross-references (Step 8).

---

## Step 8 — Cleanup hygiene

After issues are created, the repo's planning text needs to point at the project, not at a file that no longer exists.

Search for stale references:

```bash
grep -rn "deferred\.md\|TODO\.md\|ROADMAP\.md" --include="*.md" --include="*.py" --include="*.tsx" --include="*.ts" .
```

For each match, replace the file reference with a link to the GitHub Project:
`https://github.com/users/<owner>/projects/<N>` (user-scoped) or `https://github.com/<org>/<repo>/projects/<N>` (org/repo-scoped).

If the root `CLAUDE.md` has a "Keeping these files current" or similar table mentioning the deferred file, update those rows:

> | Deferred feature / bug / tech-debt is shipped | Close the linked GitHub issue (referenced in the PR via `Closes #N`) |
> | New feature, bug, or tech-debt surfaces | Open a GitHub issue (auto-added to the project) |

Delete the source planning doc.

---

## Step 9 — Commit and push

One commit covers the migration:

```
chore: migrate <doc>.md → GitHub Project + issue templates

The pending-work list now lives at <project URL> as N issues with
Tier × Area × Priority custom fields.

- Add .github/ISSUE_TEMPLATE/feature.yml and bug.yml
- Repo labels expanded: frontend, backend, infra, feature, tech-debt
- Delete <doc>.md
- Update CLAUDE.md cross-references to point at the Project
```

Push immediately (most projects' `CLAUDE.md` mandates push-after-commit).

---

## Project workflows (configured in the GitHub UI)

These can't be set via gh CLI. After the skill runs, point the user at:

> Project → `···` (top right) → **Settings** → **Workflows**

And recommend enabling:

- **Auto-add to project**: from the linked repo, status=Todo. New issues land on the board automatically.
- **Item closed → Status: Done**: closed issues / merged PRs flip to Done.
- **Auto-archive items**: Done items archive after 2 weeks. Keeps the board scannable.

These three together mean the user almost never has to manage the project manually — issues and PRs drive everything.

---

## Common failure modes

- **`error: your authentication token is missing required scopes [project]`** — Step 1 was skipped or the user didn't run `gh auth refresh -s project`.
- **`Could not resolve to a Project with the number X`** — wrong owner. User-scoped projects need `--owner <username>`; org-scoped need `--owner <orgname>`.
- **Field IDs / option IDs go stale** — if the user edits the project's field options in the UI between Step 4 and Step 7, re-fetch the field list. IDs change when options are deleted and re-added.
- **`gh project item-add` succeeds but item doesn't appear in views** — views may have filters hiding it (e.g. "Status: In Progress" view won't show new items in Status: Todo). Ask the user to check the All Items view.
