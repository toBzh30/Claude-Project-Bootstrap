---
name: update-conventions
description: Pull later improvements from the claude-project-bootstrap plugin templates down into this repo's copied convention files — .claude/rules/working-agreements.md and the .github/ISSUE_TEMPLATE issue templates — and retrofit plugin enablement in .claude/settings.json (turning on plugins like engineering-craft that were added after this repo was bootstrapped). A one-way (template → repo) reconcile that surfaces what the bundled templates grew since this repo was bootstrapped and lets you merge in what you want, preserving local customizations. Use when you've updated the plugin and want an already-bootstrapped repo to catch up. Does NOT push repo changes back to the plugin.
user-invocable: true
allowed-tools:
  - Read
  - Edit
  - Bash(ls *)
  - Bash(test *)
  - Bash(echo *)
  - Bash(diff *)
  - Bash(grep *)
  - Bash(git *)
---

# /update-conventions — Pull plugin-template improvements into this repo

The plugin's **hooks, skills, and commands** auto-trickle when you update the marketplace — they run *from* the plugin install. But two things don't reach an already-bootstrapped repo on their own: (1) the files this plugin **copied into** the repo at bootstrap (`working-agreements.md`, the issue templates) are owned by the repo from that moment on, so template improvements never reach them; and (2) a **plugin added to the marketplace after this repo was bootstrapped** (e.g. `engineering-craft`) is never switched on here — and a plugin's skills only trickle in once it's in `enabledPlugins`. This skill closes both gaps on demand.

**Direction: one-way, template → repo (pull-down only).** It surfaces what the bundled template grew and offers to merge it in. It never overwrites your local customizations, and it never pushes repo changes back up to the plugin — a repo that has improved its own conventions and wants to contribute that upstream does so via a normal PR to the plugin repo, not through this skill.

**Scope — only the shared-convention files:**

| File (in this repo) | Bundled template | Reconciled? |
|---|---|---|
| `.claude/rules/working-agreements.md` | `bootstrap-working-agreements/templates/working-agreements.md` | **Yes — primary** |
| `.github/ISSUE_TEMPLATE/feature.yml` | `github-project-setup/templates/feature.yml` | Yes |
| `.github/ISSUE_TEMPLATE/bug.yml` | `github-project-setup/templates/bug.yml` | Yes |
| `.claude/settings.json` (`enabledPlugins`) | `bootstrap-working-agreements` Step 6.5 | Yes — retrofit missing plugin enablements (e.g. `engineering-craft`) |

**Deliberately out of scope** (a diff would be all noise — these are per-repo content, not shared convention): the root/spoke `CLAUDE.md` scaffolds, `.claude/rules/roadmap.md`, and the *body* of `.claude/rules/decisions.md`.

---

## Step 0 — Locate the bundled templates and the repo's files

The bundled templates live under the plugin install, addressed via `${CLAUDE_PLUGIN_ROOT}`:

```bash
echo "plugin root: ${CLAUDE_PLUGIN_ROOT:-UNSET}"
ls "${CLAUDE_PLUGIN_ROOT}/skills/bootstrap-working-agreements/templates/working-agreements.md" \
   "${CLAUDE_PLUGIN_ROOT}/skills/github-project-setup/templates/feature.yml" \
   "${CLAUDE_PLUGIN_ROOT}/skills/github-project-setup/templates/bug.yml" 2>&1
```

If `${CLAUDE_PLUGIN_ROOT}` is unset (skill invoked outside a plugin context), ask the user for the path to a local checkout of the `claude-project-bootstrap` plugin and use `<path>/plugins/claude-project-bootstrap` in its place.

Check which of the repo's files exist — reconcile only the ones present:

```bash
ls .claude/rules/working-agreements.md .github/ISSUE_TEMPLATE/feature.yml .github/ISSUE_TEMPLATE/bug.yml 2>&1
```

If `.claude/rules/working-agreements.md` doesn't exist, this repo was never bootstrapped — recommend `/bootstrap-working-agreements` instead and stop.

**Working-tree note:** this skill edits files in place. If `git status --short` shows the target files already dirty, say so and ask whether to continue (the user wants a clean baseline to `git diff` the reconcile against).

---

## Step 1 — Reconcile `working-agreements.md` (the primary file)

This is **not a textual diff.** The bundled template carries raw placeholders (`<integration-branch>`, `<mode-line>`, `<strategic-field>`, the conditional `Cross-repo Project contract` / `Infrastructure boundaries` sections, the `<owner>` refs); the repo's copy has those **substituted or stripped** at bootstrap. A line-level diff would drown the real signal in substitution noise. Compare at the level of **sections and rules**.

### 1a — Read both files in full

`Read` the bundled template and the repo's `.claude/rules/working-agreements.md`. (A raw `diff` can be a hint, but treat it as a starting signal, not the answer.)

### 1b — Discount what is NOT drift

Before classifying anything, mentally normalize away the bootstrap substitutions — these are **expected**, not drift, and must never be offered as changes:

- Placeholder fills: `<integration-branch>` → the repo's branch, `<owner>` → the repo's owner, `<example-large-file-*>` → real file names, `<mode-line>`/`<shipping-row>`/`<trivia-rule>` → the chosen mode variant.
- Conditional sections the template tells the bootstrap skill to **strip per project shape** (`Cross-repo Project contract` for single-repo; `Infrastructure boundaries` when the user had no hands-off files; the `Setting Issue type` subsection when the org has no issue types). Their *absence* from the repo is intentional — do not flag it as "only-in-template / pull down."
- Genuine local edits the repo's maintainers made on purpose.

### 1c — Classify each template section/rule

Walk the bundled template's sections and rules and bin each:

- **only-in-template** → a section, rule, bullet, or table row that exists in the template but has **no equivalent** in the repo's file, and isn't an intentionally-stripped conditional section (per 1b). *This is the main pull-down signal — e.g. a new lifecycle phase, a new "when to file" bullet, a new gotcha.*
- **differs** → present in both, but the template's wording has **substantively evolved** (a rule tightened, an example added, a clarification) — ignoring pure placeholder substitution.
- **only-in-repo** *(informational)* → sections/rules the repo has that the template doesn't. Local customizations. **Never modified, never "pushed up."** List them only so the user knows they're seen and left intact.

### 1d — Present a grouped summary

Show one compact summary, grouped by the three bins, each item one line with a **recommendation + one-line why**:

```
Pull-down candidates for .claude/rules/working-agreements.md:

ONLY IN TEMPLATE (offer to add):
  [1] Phase 6 "Reconcile docs" in "How we work through issues"
      → recommend ADD — your flow stops at five phases; the doc-gate hook expects six.
  [2] "Don't file" bullet: bug-fix-on-a-line-just-written
      → recommend ADD — small, no conflict with your local rules.

DIFFERS (offer to update toward template):
  [3] "Token efficiency" intro gained an override caveat
      → recommend REVIEW — you've customized this section; show diff before changing.

ONLY IN REPO (left untouched — FYI):
  - "Deployment constraints" section (your local addition)
```

Then let the user **approve all / pick a subset / drill into one** (show the full before/after for any item on request). Default to **not** applying anything without an explicit pick.

### 1e — Apply approved items

For each approved item, use `Edit` to merge it into the repo's file:

- **Insert it at the matching structural location** (same section / adjacent rule), not appended at the end.
- **Substitute the repo's known values** when pulling template prose in — e.g. render `<integration-branch>` as the repo's actual branch (read it from the existing file or `gh repo view`), so you don't introduce a fresh placeholder.
- **Preserve surrounding local customizations** — never replace a whole section when only a rule changed.
- For **differs** items the user approved, edit only the drifted span, keeping any local wording the user added around it.

After applying, run `git diff --stat .claude/rules/working-agreements.md` and report what changed.

---

## Step 2 — Reconcile the issue templates (`feature.yml`, `bug.yml`)

These are near-verbatim copies, so a textual `diff` is meaningful here — with one expected, non-drift difference: the bundled templates carry a `type:` line (`type: Bug` / `type: Feature`) that **`github-project-setup` strips for user-owned repos** (where GitHub issue types don't exist). Treat a missing `type:` line as intentional, not drift, **unless** the repo is org-owned and uses issue types.

For each template present in the repo:

```bash
diff "${CLAUDE_PLUGIN_ROOT}/skills/github-project-setup/templates/feature.yml" .github/ISSUE_TEMPLATE/feature.yml
```

- **Identical** → report "matches bundled template" and skip.
- **Differs** → summarize the difference (added/removed fields, changed labels), discount the `type:` line per above, and offer to update toward the template. On approval, `Edit` in the template's improvements while keeping any repo-local fields the maintainer added.

---

## Step 2.5 — Retrofit plugin enablement (`.claude/settings.json`)

A plugin's skills only load once it's in `enabledPlugins`. A repo bootstrapped before a plugin existed (e.g. `engineering-craft`) has that plugin's skills sitting in the marketplace but switched **off**. This step turns on any plugin the current bootstrap would enable that this repo is missing.

Read the repo's `.claude/settings.json` (if absent, the repo never ran Step 6.5 — recommend running `bootstrap-working-agreements` Step 6.5, and skip this step). List what's enabled:

```bash
jq -r '.enabledPlugins // {} | keys[]' .claude/settings.json 2>/dev/null
```

The current `bootstrap-working-agreements` Step 6.5 enables both:

- `claude-project-bootstrap@claude-project-bootstrap` (setup hooks)
- `engineering-craft@claude-project-bootstrap` (ongoing craft skills)

For any **missing** key, offer to add it — and ensure `extraKnownMarketplaces` has the `claude-project-bootstrap` entry so the marketplace resolves. Merge the key in with `Edit`; **don't clobber** other settings, and never touch `.claude/settings.local.json` (per-user, gitignored). A repo that deliberately wants setup-only can decline `engineering-craft` (it'll simply be re-offered on the next run — harmless). The newly-enabled plugin's skills load on the **next** Claude session.

---

## Step 3 — Summary

Report as one block:
- Per file: items pulled in, items the user skipped, "matches template" / "no changes".
- Local-only sections that were left untouched (so the user knows they were considered).

**Honor the repo's collaboration `Mode`** (from `working-agreements.md` → "Commits and merging") — this skill runs on an already-bootstrapped repo, so a `Mode` is established:

- **Solo / `afk.merge: auto-merge`** — proceed: commit the reconcile, and if you're on an issue branch, open the PR and merge per the repo's policy after a `/code-review` self-review. A Solo repo expects you to land it, not hand back a diff.
- **Team / `review-required`** — present the `git diff` summary and **stop**; the user reviews and commits.

---

## What this skill does NOT do

- **No push-up.** It never sends repo changes back to the plugin. Improvements worth sharing upstream go via a normal PR to the `claude-project-bootstrap` repo.
- **No scaffolds.** It doesn't touch root/spoke `CLAUDE.md`, `roadmap.md`, or the `decisions.md` body — those are per-repo content, not shared convention.
- **No blind overwrite.** It never replaces a file wholesale; every change is a targeted, reviewed merge that preserves local customizations.
- **No version stamp.** There's no tracked "template version" — working-agreements legitimately diverge per repo, so reconcile is an on-demand judgment call, not a sync that drives toward identity.
