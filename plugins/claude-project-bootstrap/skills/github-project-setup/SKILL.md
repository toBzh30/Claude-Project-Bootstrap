---
name: github-project-setup
description: Set up a GitHub Project (v2) for a single repo or a multi-repo platform. Standardized statuses, custom fields (Tier or Initiative + Area/Priority/Effort), labels, and issue templates. Single-repo flow uses GitHub milestones; multi-repo flow uses a Project Initiative field for cross-repo coordination and surfaces the built-in Repository column. Optionally migrate an existing planning doc (deferred.md / TODO.md / ROADMAP.md / etc.) into auto-added issues. Use when the user wants to start tracking features/bugs/tech-debt in a structured project board, or asks how to coordinate across multiple repos under one org.
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

# /github-project-setup — Bootstrap a GitHub Project for a repo or multi-repo platform

The goal: a single project board that holds *all* in-flight work (features, bugs, tech-debt) with consistent custom fields so you can group, filter, and prioritise across types. **The skill handles two project shapes**:

- **Single-repo** — one Project tracks one repo. GitHub milestones for releases. Tier/Area/Priority/Effort custom fields.
- **Multi-repo** — one Project tracks several repos under the same org (typical for platforms with split frontend/backend/infra/runtime repos). Initiative custom field replaces Tier as the strategic axis; built-in Repository column added to default views; per-repo milestones de-emphasized in favor of cross-repo Initiatives.

Step 1 detects which case applies and the rest of the flow branches accordingly.

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

Identify the repo, its owner, and your gh user:

```bash
gh repo view --json nameWithOwner,owner -q '{repo: .nameWithOwner, ownerType: .owner.__typename}'
gh api user --jq .login
```

Capture three values for use in Step 2:
- `<owner>/<repo>` from `nameWithOwner` (e.g., `acme/widget`)
- `<owner-type>` from `ownerType` — `User` or `Organization`
- `<gh-user>` from `gh api user` — your authenticated GitHub login

Note: GitHub Projects (v2) live under a **user or org namespace**, not under a repo. The repo links to projects via its sidebar but does not own them. Step 2 decides which namespace this project will live under.

**Detect whether the org has GitHub issue types configured.** Try the org-level list first:

```bash
gh api orgs/<owner>/issue-types --jq '[.[].name]'
```

Fine-grained PATs often 403 here even when per-issue type reads succeed. **Fallback** — sample the type field on existing issues:

```bash
gh issue list -R <owner>/<repo> --limit 5 --json number --jq '.[].number' \
  | xargs -I{} gh api repos/<owner>/<repo>/issues/{} --jq '.type.name' \
  | sort -u
```

Sample at least 3–5 issues across the repo to capture the full configured set. Outcomes:

- **Concrete type names returned** → org has issue types. Capture the set as `<configured-issue-types>` (and any title-prefix → type mapping observed, e.g. `[bug]` → Bug, `[feature]` → Feature) for downstream use in `bootstrap-working-agreements`'s template substitution.
- **Every sample returns `null`** → types aren't enabled. Surface this and recommend enabling them at **Organization → Settings → Issue types** before continuing, or proceed without — issue templates' `type:` lines become silent no-ops, and CLI-filed issues skip the PATCH step.

This detection is org-wide and shared across every repo under `<owner>` — if the org has types configured, *every* repo can use them.

**Detect project scope (single-repo vs multi-repo).** A multi-repo platform (several services / packages / clients under one org sharing strategic milestones) needs different field shape than a single-repo project. List repos under the owner:

```bash
gh repo list <owner> --limit 100 --json name --jq '.[].name'
```

Surface the choice explicitly — don't auto-pick:

> The owner `<owner>` has `<N>` repo(s): `<list, truncated to 10>`.
>
> Will this Project track:
> 1. **Just `<repo>`** — single-repo Project. Per-repo GitHub milestones, repo-scoped tracking issues, templates land in this repo only. **Default for solo packages, libraries, single-product webapps.**
> 2. **Multiple repos under `<owner>`** — multi-repo platform Project. Strategic coordination via a Project-level **Initiative** field; per-repo GitHub milestones de-emphasized (only used if the user does per-repo release tagging); tracking issues live in whichever repo has the most weight per Initiative. **Default for platforms / multi-service projects sharing a roadmap across 2+ repos.**
>
> Default: option 1 if only one repo. Option 2 if 3+ repos likely share initiatives.

Wait for the user's choice. Capture as `<project-scope>` (`single-repo` or `multi-repo`).

**If `<project-scope>` = `multi-repo`**: strongly recommend placing the Project at the org namespace in Step 2 (cross-repo issues are easiest to add when the Project sits at org level). Surface this explicitly when Step 2's namespace prompt fires.

---

## Step 2 — Discover existing planning state and choose project namespace

Read in parallel:
- Root `CLAUDE.md` if present — gives you the project's vocabulary (product tiers, area names, current priorities).
- Any `deferred.md`, `TODO.md`, `ROADMAP.md`, `BACKLOG.md` under `.claude/rules/` or repo root.
- Existing labels: `gh label list -R <owner>/<repo>`.

**List existing projects across candidate namespaces.** Cross-namespace duplicates are a real failure mode — don't silently create a second board if one already exists somewhere relevant. Run:

```bash
gh project list --owner <owner> --format json --jq '.projects[] | "\(.number)\t\(.title)"'
# Skip the next call if <gh-user> == <owner>
gh project list --owner <gh-user> --format json --jq '.projects[] | "\(.number)\t\(.title)"'
```

Surface anything that looks like it might already track this repo (title contains the repo or project name, or anything else recognizable).

**Decide the project namespace.** Surface the choice explicitly — don't auto-pick.

> The project board lives under a user or org **namespace**, not under the repo itself. The repo can link to a project, but doesn't own it. The repo's owner is **`<owner>`** (a `<owner-type>`).
>
> Options:
> 1. **Place under `<owner>`** (repo owner, `<owner-type>`) — the board lives next to the repo and appears in `<owner>/<repo>`'s Projects tab automatically. If `<owner>` is an **Organization**, the board is in **org context** — visible and editable to org members with appropriate permissions. If `<owner>` is a **User**, the board is private to that user unless they grant collaborators. **Recommended unless you have a reason not to.**
> 2. **Place under `<gh-user>`** (your personal namespace) — only you see it unless you add collaborators. Useful for solo planning on an org repo, or when you want to track work without org-wide visibility.
> 3. **Place under a different user or org** — name a namespace where you have project-create permission. Requires `project` scope on a token with write access to that namespace.
>
> Existing projects under `<owner>`: `<list from step above, or "none">`
> Existing projects under `<gh-user>`: `<list, or "none">`  (omit line if same as `<owner>`)
>
> Which do you want? (default: 1)

Wait for the user's choice. Capture as `<project-owner>`. **All `gh project ...` calls in later steps use `--owner <project-owner>`.** Repo-scoped calls (`gh issue ...`, `gh label ...`, `gh repo ...`) keep using `<owner>/<repo>`.

**If the user wants to extend an existing project** — capture its number as `<N>` and skip Step 4's project-creation block. Still run the field-creation block to add any missing Tier/Area/Priority/Effort fields.

**If `<project-owner>` ≠ `<owner>`** — surface the implication explicitly so the user knows what they're choosing:

> Note: the project will live under `<project-owner>`, not `<owner>` (the repo's owner). It will **not** appear in `<owner>/<repo>`'s Projects tab automatically. To link them, either:
> - Add `<owner>/<repo>` as a "linked repository" in the project's settings (Project → ⋯ → Settings → Manage access → Add repository), so issues from this repo can be added to the project; OR
> - Just reference the project URL from the repo's `CLAUDE.md` or `README.md` and skip the GitHub-side linking.

Use what you read (CLAUDE.md, planning docs) to **propose** the field values in Step 3. Don't ask the user to invent them from scratch.

---

## Step 3 — Propose Tier / Initiative and Area values

The dimension fields are the most project-specific. Don't hardcode.

**Pick the strategic dimension based on `<project-scope>`:**

- **Single-repo (`<project-scope>` = `single-repo`)** → use **Tier** (which user surface / product layer this serves)
- **Multi-repo (`<project-scope>` = `multi-repo`)** → use **Initiative** (which cross-repo strategic milestone this gates) and **skip Tier** unless the platform also has a tier dimension worth tracking

Most projects have one or the other, not both. Tier is for "which audience": `Novice/Amateur/Pro` or `Free/Paid/Premium`. Initiative is for "which roadmap milestone": `M1/M2/M3` or `Alpha/Beta/GA`. Don't conflate.

**Tier** — the dimension users want to see in the Roadmap view (single-repo case). Common patterns:

| Project type | Tier values |
|---|---|
| Multi-tier consumer product (Free/Paid/Premium) | Product tiers, e.g. `Novice / Amateur / Pro / Infra / Tech-debt` |
| Internal tool / B2B | `Now / Next / Later / Tech-debt` |
| Library or SDK | (skip Tier entirely; use Priority alone) |
| Single-developer side project | `Core / Polish / Stretch / Tech-debt` |

**Initiative** — the cross-repo strategic milestone (multi-repo case). Almost always project-specific; read the user's planning docs to draft. Common patterns:

| Project shape | Initiative values |
|---|---|
| Phased platform launch | `M1 / M2 / M3 / M4 / Phase-2 / Backlog` |
| Quarter-driven roadmap | `Q1-2026 / Q2-2026 / Q3-2026 / Backlog` |
| Theme-driven (capability-based) | e.g. `Auth / Billing / Observability / Backlog` |

Surface 2–3 candidate option lists to the user; wait for their pick. Initiatives are easier to rename later than to invent on the fly — bias toward fewer, broader values rather than many narrow ones.

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

User-friendlier path: ask the user to create the empty project in the GitHub UI (`github.com/<project-owner>?tab=projects` → New project → Board template → name it). They click through once to see the UI; takes 30 seconds. Then they paste the URL or project number back, and you do the rest via gh.

CLI alternative if the user prefers automation:

```bash
gh project create --owner <project-owner> --title "<Project name>"
```

Once you have the project number, fetch the existing fields:

```bash
gh project field-list <N> --owner <project-owner> --format json > /tmp/fields.json
```

For each missing custom field, create it. Single-select fields use comma-separated options:

```bash
# Single-repo case: Tier
gh project field-create <N> --owner <project-owner> \
  --name Tier --data-type SINGLE_SELECT \
  --single-select-options "Novice,Amateur,Pro,Infra,Tech-debt"

# Multi-repo case: Initiative (instead of Tier)
gh project field-create <N> --owner <project-owner> \
  --name Initiative --data-type SINGLE_SELECT \
  --single-select-options "M1,M2,M3,M4,Phase-2,Backlog"
```

Create only the strategic-dimension field that matches `<project-scope>` (Tier xor Initiative — not both unless the user explicitly wants both axes). Then create Area, Priority, Effort regardless of scope. The default Status field already exists and is editable via the UI (or `gh project field-update`) — add `Blocked` if it's not there.

**Multi-repo only — surface the built-in Repository field in default views.** GitHub auto-tracks the repo for every Project item but hides the column by default. To make `Repository` visible (essential for cross-repo group/filter):

> The built-in **Repository** column is the cleanest way to see "which repo did this come from" — no custom field needed. It can't be added via `gh project field-create` (it already exists, just hidden). Add it manually:
>
> 1. Open the Project in browser → pick a view (Board / Table / Roadmap)
> 2. Click `+` next to the column headers, or ⋯ on the view → Fields
> 3. Toggle **Repository** on
> 4. Repeat for every default view (Board, Table, Roadmap)
>
> The user does this once after Step 4 completes — it's a 30-second UI step.

After all fields exist, re-fetch `gh project field-list ... --format json` and **save the field IDs and option IDs** to a JSON file (`/tmp/fields.json`). You'll need them in Step 4b and Step 7.

---

## Step 4b — Write `.claude/gh-project.json` (plugin hook config)

The bundled plugin ships three git/PR hooks (`preflight-branch`, `claim-branch`, `doc-gate`). One of them — `claim-branch` — flips an issue's Project Status to **In Progress** when its `<type>/<N>-<slug>` branch is created. It needs this Project's coordinates, which you just discovered. Persist them to a small committed config so the hook can read them; **without this file the hook no-ops** and the board is never touched (so this step is what activates the auto-claim).

Pull the five coordinates from the project and the saved field-list JSON:

```bash
gh project view <N> --owner <project-owner> --format json --jq '.id'   # id (PVT_...)
jq -r '.fields[] | select(.name=="Status") | .id' /tmp/fields.json                                              # statusFieldId
jq -r '.fields[] | select(.name=="Status") | .options[] | select(.name=="In Progress") | .id' /tmp/fields.json  # inProgressOptionId
```

Write `.claude/gh-project.json` (create `.claude/` if needed):

```json
{
  "project": {
    "owner": "<project-owner>",
    "number": <N>,
    "id": "<PVT_...>",
    "statusFieldId": "<PVTSSF_...>",
    "inProgressOptionId": "<opt-id>"
  }
}
```

**Ensure it's committed, not ignored.** A `.claude/` directory-ignore — or a `.claude/*` carve-out that only re-includes `rules/` (the pattern `bootstrap-working-agreements` lays down) — silently excludes this file. Verify:

```bash
git check-ignore -v .claude/gh-project.json   # no output / exit 1 = NOT ignored (good)
```

If it reports a match (ignored), extend the carve-out in `.gitignore` so the file is tracked, alongside any existing `!.claude/rules/` re-include:

```
.claude/*
!.claude/rules/
!.claude/gh-project.json
```

Wait for user confirmation before editing `.gitignore` (it changes what the team commits). Re-run `git check-ignore` to confirm it now reports NOT IGNORED.

**Multi-repo note:** `claim-branch` resolves the issue's Project item by matching the *current repo* against `content.repository`, so one `.claude/gh-project.json` per tracked repo — all pointing at the same Project — is correct. Write it in each repo where the plugin is enabled.

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

**Types vs labels are orthogonal.** If the org has GitHub issue types configured (see Step 1's preflight), the org type set is the cross-repo "what kind of work is this" signal — `Bug` / `Feature` / `Task` carry across all repos in the org. Labels remain useful for finer-grained per-repo taxonomy (`tech-debt`, `infra`, `docs`) and don't replace types — keep both.

---

## Step 5b — (Optional) Cross-repo initiatives or per-repo milestones

This step branches by `<project-scope>`:

- **Single-repo (`<project-scope>` = `single-repo`)** → use **GitHub milestones** as below. Tracking issues live in this repo and auto-progress works.
- **Multi-repo (`<project-scope>` = `multi-repo`)** → skip GitHub milestones for strategic phases (they're repo-scoped and don't span repos cleanly). Use the **Project Initiative field** created in Step 4 as the cross-repo source of truth. Jump to the **Multi-repo variant** at the end of this section.

Ask: **"Do you want milestone-based release planning (Alpha/Beta/GA pattern), or continuous-flow shipping?"**

Skip this step entirely for libraries, side projects, or any product without discrete release boundaries. For products shipping to real users in stages, this is the accountability mechanism — without it, scope drift is the default.

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

### Multi-repo variant — Initiative field instead of GitHub milestones

If `<project-scope>` = `multi-repo`, the cross-repo coordination unit is the Project's `Initiative` field (created in Step 4). GitHub milestones are repo-scoped and would have to be replicated across N repos, which drifts. Skip GitHub milestone creation entirely.

**Tier ≠ Initiative ≠ per-repo Milestone.** State this in the roadmap doc explicitly:
- **Tier** (single-repo concept; usually skipped in multi-repo) = which user surface this serves.
- **Initiative** (multi-repo strategic unit) = which cross-repo phase this gates. Set on every issue in the Project regardless of which repo it lives in.
- **Per-repo Milestone** (orthogonal, optional) = which release tag closes it within its own repo. Use only if the user does per-repo release tagging; otherwise skip.

#### Procedure

1. **Propose initiative names + bars.** Read existing planning docs (CLAUDE.md, README, plan docs, equivalent) to draft. Show a table to the user:

   | Initiative | Bar (one paragraph) | Out of scope (bullets) |

   Wait for confirmation/edits.

2. **Skip GitHub milestone creation.** The Initiative field already exists from Step 4. There is nothing to create at the GitHub-milestone level for strategic phases.

3. **Write `.claude/rules/roadmap.md`** from `templates/roadmap.md`. Adapt the template's "GitHub Milestones" header to "Project Initiatives" and reflect the multi-repo doctrine — one section per Initiative with Bar / Tracking / In scope / Out of scope. The cross-repo aspect should be explicit ("issues from any of these repos: `<repo1>, <repo2>, ...` can be tagged with this Initiative").

4. **Add cross-repo issues to the Project, set Initiative field.** For each existing issue across all involved repos that should land in an Initiative:

   ```bash
   gh project item-add <N> --owner <project-owner> --url <issue-url>
   gh project item-edit --id <item-id> --project-id <PVT_...> \
     --field-id <F_INITIATIVE> --single-select-option-id <opt-id>
   ```

   Show the mapping as a table for user confirmation before applying. Same `<F_INITIATIVE>` and option IDs come from Step 4's saved JSON.

5. **Identify gaps and open new issues** in whichever repo each gap belongs to. They auto-add to the Project (if the Project's "Auto-add to project" workflow is configured for each repo — see "Project workflows" below). Set their Initiative on add.

6. **Create one tracking issue per Initiative**, in whichever repo carries the most weight for that Initiative (most sub-issues, most-coupled subsystem, or just the user's preference). Body lists sub-issues across all repos as a markdown checklist:

   ```bash
   gh issue create -R <most-weighted-repo> \
     -t "[initiative] M1 — private end-to-end beta" \
     -b "$(cat <<'EOF'
   **Closing this issue = we shipped M1.**

   ## Bar
   <one paragraph from the table>

   ## Out of scope
   - …

   ## Sub-issues across the platform
   - [ ] <owner>/<repo-A>#4 …
   - [ ] <owner>/<repo-B>#12 …
   - [ ] <owner>/<repo-C>#3 …

   See \`.claude/rules/roadmap.md\` for the framework.
   EOF
   )"
   ```

   **Important caveat:** GitHub only auto-ticks the checklist when a referenced issue is in the **same repo** as the tracking issue (`#N` syntax). Cross-repo refs (`<owner>/<other-repo>#N`) **don't auto-tick** — they need manual checkmarks when those issues close. The tracking issue itself has no `feature`/`bug` label — it's a meta-issue.

7. **Expose Repository + Initiative in the Project's Roadmap view.** UI step: open the project → Roadmap view → ⋯ → Fields → enable `Repository` and `Initiative`. Group by Initiative for cross-repo phase progress; group by Repository to see "what's left in repo X across all initiatives".

8. **Issue templates per repo.** Step 6 only writes templates to `<owner>/<repo>` (the current repo). For multi-repo Projects, run this skill once per tracked repo OR copy `feature.yml` / `bug.yml` from this skill's `templates/` into each repo's `.github/ISSUE_TEMPLATE/` manually.

#### Working-agreement contract for multi-repo

Add a row to `.claude/rules/working-agreements.md` (the bootstrap-working-agreements skill writes this file): when an issue is filed in *any* tracked repo under `<project-owner>`, the filer (human or Claude) **must** add it to the Project and set its `Initiative` value at creation time. Without this contract, the Project misses signals from sibling repos and the cross-repo dimension breaks.

#### Per-repo release milestones (optional, orthogonal)

If the user has a per-repo release-tagging workflow (e.g., `v1.30` of repo A, `v0.5` of repo B), GitHub milestones can still be created **per repo, scoped to that repo's release semantics** — independent of the strategic Initiative. This is rare for continuously-deployed platforms and worth asking only if the user surfaces release tagging explicitly.

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

**Multi-repo case**: this step writes templates to `<owner>/<repo>` only — the repo where the skill was invoked. Other tracked repos under `<project-owner>` get nothing here. To install templates everywhere, either:
- Re-run this skill in each tracked repo (works, repetitive)
- Manually copy `feature.yml` / `bug.yml` from this skill's `templates/` into each repo's `.github/ISSUE_TEMPLATE/`

Surface this to the user explicitly: *"Templates landed in `<repo>` only. Multi-repo Project — sibling repos don't get them automatically. Want me to walk you through adding them to the others?"*

**On the `type:` field**: both bundled templates carry `type: Bug` / `type: Feature` so UI-filed issues get the GitHub-native Issue type (Bug / Feature / Task) on creation. This requires Issue types to be **enabled at the org level** (Org Settings → Repository policies → Issue types). If they're not, the `type:` line is a silent no-op — issues file fine, just without a type. The companion `bootstrap-working-agreements` skill handles the CLI-filed path (`gh issue create` has no `--type` flag) by writing a GraphQL recipe into the project's `working-agreements.md`. Personal (user-owned) repos don't get Issue types at all — strip both lines before copying if `<owner-type>` is `User`.

---

## Step 7 — (Optional) Migrate an existing planning doc to issues

If the user has a `deferred.md` (or similar) full of pending work, this is the highest-value step. Skip if no such doc exists or the user wants to start with an empty board.

The bundled `scripts/migrate_doc.py` is a starting point. Adapt it per project:

1. Read the source doc in full.
2. Parse each entry into an issue spec. Single-repo: `{title, body, labels, tier, area, priority, milestone}`. Multi-repo: `{title, body, labels, initiative, area, priority, repo}` — `repo` selects which `<owner>/<repo>` the issue is filed in; replace the `tier` key with `initiative`. `milestone`/`initiative` are optional.
3. **Show the user the planned issue list as a table** (title, repo if multi-repo, labels, tier/initiative, area, priority, milestone) — *wait for confirmation before creating anything*.
4. Edit `scripts/migrate_doc.py` (copy to `/tmp/`) with:
   - **Single-repo**: `REPO` = `<owner>/<repo>`. All issues land here.
   - **Multi-repo**: `REPO` is unused at the constants level — instead, each entry in `ISSUES` carries its own `"repo": "<owner>/<other-repo>"` key, and the script's `gh issue create -R …` reads from per-issue. Keep `OWNER` = `<project-owner>`.
   - `OWNER` = `<project-owner>` (the *project's* namespace, from Step 2 — may differ from the repo owner)
   - `PROJECT_NUMBER`, `PROJECT_ID`
   - Field IDs and option IDs from Step 4 (rename `F_TIER` → `F_INITIATIVE` and `TIER` → `INITIATIVE` for the multi-repo case)
   - The `ISSUES = [...]` array (each entry can include an optional `"milestone": "Alpha"` key for single-repo, or `"initiative": "M1"` for multi-repo)
5. Run it. The script: creates each issue, adds it to the project, sets Tier-or-Initiative/Area/Priority, optionally sets the milestone via `gh issue edit -m`. Effort is left blank (user sizes during triage).
6. Verify: `gh project item-list <N> --owner <project-owner> --limit 50` should show all the new items. Single-repo + milestones: also check `gh issue list -R <owner>/<repo> --milestone "<name>" --limit 50`. Multi-repo: filter the Project by Initiative=`<value>` in the UI to confirm cross-repo aggregation.

**Multi-repo migration tip**: if the source doc spans many repos, batch by destination repo rather than running one mega-migration. Less to undo if a repo's mapping turns out wrong.

After the migration runs successfully, **delete the source doc** and update CLAUDE.md cross-references (Step 8).

---

## Step 8 — Cleanup hygiene

After issues are created, the repo's planning text needs to point at the project, not at a file that no longer exists.

Search for stale references:

```bash
grep -rn "deferred\.md\|TODO\.md\|ROADMAP\.md" --include="*.md" --include="*.py" --include="*.tsx" --include="*.ts" .
```

For each match, replace the file reference with a link to the GitHub Project. The URL format depends on whether `<project-owner>` is a user or org:
- User-owned: `https://github.com/users/<project-owner>/projects/<N>`
- Org-owned: `https://github.com/orgs/<project-owner>/projects/<N>`

Capture the canonical URL from `gh project view <N> --owner <project-owner> --format json --jq .url` if unsure.

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

**Multi-repo case**: the "Auto-add to project" workflow is **per-repo** — it has to be enabled separately for each tracked repo. Walk the user through the Workflows panel once and have them add every repo under `<project-owner>` that should auto-add issues. Without this, sibling-repo issues won't land on the board automatically.

---

## Common failure modes

- **`error: your authentication token is missing required scopes [project]`** — Step 1 was skipped or the user didn't run `gh auth refresh -s project`.
- **`Could not resolve to a Project with the number X`** — wrong owner. User-scoped projects need `--owner <username>`; org-scoped need `--owner <orgname>`.
- **Multi-repo: cross-repo sub-issue closes don't tick the tracking-issue checklist** — expected. GitHub only auto-ticks `#N` (same-repo) refs. `<owner>/<other-repo>#N` refs require manual checkmarks. If this becomes painful, write a small webhook/Action to reflect cross-repo closes onto the tracking issue body.
- **Multi-repo: new issues in sibling repos don't appear in the Project** — "Auto-add to project" is per-repo; the workflow needs enabling on each tracked repo's Project Settings → Workflows. Easy to miss when adding a 4th or 5th repo months later.
- **Field IDs / option IDs go stale** — if the user edits the project's field options in the UI between Step 4 and Step 7, re-fetch the field list. IDs change when options are deleted and re-added.
- **`gh project item-add` succeeds but item doesn't appear in views** — views may have filters hiding it (e.g. "Status: In Progress" view won't show new items in Status: Todo). Ask the user to check the All Items view.
- **`gh api orgs/<owner>/<resource>` returns 403 "resource not accessible by personal access token"** — fine-grained PATs commonly lack scope for *list/admin* endpoints while still allowing reads on individual items. Before reporting it as a hard limitation, sample individual resources to discover the configured set. Same shape for many org-level taxonomies:
  - **Org issue types blocked** → read `repos/<owner>/<repo>/issues/<N> --jq .type.name` on existing issues across the repo (or a sibling repo) to discover which types are in use.
  - **Org Project field options blocked** → read the project's `field-list` directly (often allowed at the project level even when the org-list endpoint isn't).
  - **Org-level label config blocked** → label *use* on issues is readable per-issue; sample to discover the in-use set.
