# claude-project-bootstrap

Work with Claude on a complex project the way you'd work with a great collaborator: shared context that persists across sessions, machines, and the natural limits of any single conversation. What you've already figured out doesn't need to be re-explained.

The foundation is a GitHub Project board Claude keeps current as you work — decisions recorded, deferred work visible, in-flight issues tracked. Claude files the issues and updates the board. You just pick what to work on next. No PM overhead, no `CLAUDE.md` that grows until it breaks.

And because it's GitHub, the whole team benefits. Anyone contributing to the repo sees the same board — what's in flight, what's been decided, what's parked. Claude working with one teammate doesn't create a private context that others are locked out of.

This plugin bootstraps that setup on any repo in one command.

## What's in it

Two plugins ship from this marketplace.

**`claude-project-bootstrap`** — one-time project *setup*. Four skills, individually invocable:

| Skill | What it does |
|---|---|
| `/claude-project-bootstrap:bootstrap-working-agreements` | Orchestrator. Calls the others, then writes `.claude/rules/working-agreements.md` and a starter root `CLAUDE.md` from templates with project-specific placeholders filled in. |
| `/claude-project-bootstrap:github-project-setup` | Bootstrap a GitHub Project (v2) with Status / Tier / Area / Priority / Effort / Mode fields, standard labels, issue templates, optional milestones + tracking issues. Optionally migrates an existing planning doc into auto-added issues. |
| `/claude-project-bootstrap:split-claudemd` | Refactor a long root `CLAUDE.md` into a short hub + per-subdir spokes + `.claude/rules/<topic>.md` topic files. Enforces the 200-line root cap. |
| `/claude-project-bootstrap:update-conventions` | Pull later template improvements (working-agreements, issue templates) into an already-bootstrapped repo and retrofit newly-added plugins. A one-way template → repo reconcile. |

It also installs git/PR hooks (`preflight-branch`, `claim-branch`, `doc-gate`, `sibling-status`) that enforce the lifecycle at the git boundary — claim an issue when you branch, block a code PR that skips its docs, surface cross-repo drift at session start.

**`engineering-craft`** — ongoing engineering & Claude-coding *craft*. Discipline skills you reach for as the work calls for them:

| Skill | What it does |
|---|---|
| `/engineering-craft:diagnose` | Disciplined bug/perf diagnosis loop: reproduce → minimise → hypothesise → instrument → fix → regression-test. |
| `/engineering-craft:tdd` | Test-driven development with a red-green-refactor loop. |
| `/engineering-craft:prototype` | Throwaway prototype to flush out a design before committing — a runnable terminal app or several toggleable UI variations. |
| `/engineering-craft:grill-with-docs` | Stress-test a plan against your domain model; sharpen terminology and update the glossary + decisions log inline. |
| `/engineering-craft:improve-codebase-architecture` | Find deepening / refactoring opportunities, informed by the glossary and decisions. |
| `/engineering-craft:to-issues` | Break a plan, spec, or PRD into independently-grabbable issues via tracer-bullet vertical slices. |
| `/engineering-craft:to-prd` | Turn a conversation into a PRD for an initiative-scale effort and publish it as a tracking issue with sub-issues. |
| `/engineering-craft:checkpoint` | Write a session-handover doc so work resumes cleanly after `/clear` or on another machine. |
| `/engineering-craft:zoom-out` | Step back to a higher-level perspective on a section of code and how it fits the bigger picture. (Slash-invoke only.) |

## Install

```bash
# In any Claude Code session:
/plugin marketplace add toBzh30/Claude-Project-Bootstrap
/plugin install claude-project-bootstrap     # project setup
/plugin install engineering-craft            # optional craft companion
```

If you've forked this repo, replace `toBzh30` with your own GitHub user or org. If the host is private, only collaborators with read access can install it.

## Usage

**Fresh repo:**

```bash
cd <new-repo>
/claude-project-bootstrap:bootstrap-working-agreements
```

The skill reads the repo, proposes a setup, and walks through each item conversationally — the only thing it can't infer is what the project actually does. Confirms before creating anything, and leaves you with a working setup in one pass.

**Existing repo:**

Run the same command. The skill detects existing `.claude/rules/` files, a pre-existing GitHub Project, and any current issue templates — and prompts before touching anything. You can refresh templates while keeping local decisions, add fields to an existing board, or skip steps you've already done.

## Onboarding a team or a new machine

Once a repo is bootstrapped, its `.claude/settings.json` commits the marketplace source and the enabled plugins — so the setup travels with the repo. How a contributor activates it depends on whether Claude Code already trusts the folder.

**Fresh clone (folder not yet trusted):** clone, open Claude Code in the repo, and **trust the folder** when prompted. Claude Code then auto-prompts to register the marketplace and install the enabled plugins. No plugin commands needed.

**Folder already trusted** (you'd worked in the repo before the plugin block landed, so the trust prompt won't re-fire): realize the committed block manually, once per repo —

```bash
/plugin marketplace add toBzh30/Claude-Project-Bootstrap
/plugin install claude-project-bootstrap@claude-project-bootstrap --scope project
/plugin install engineering-craft@claude-project-bootstrap --scope project
```

Both installs are idempotent against the committed block. Project state — issues, PRs, board status — lives on GitHub, so a teammate or a different machine picks up where things stand without re-briefing.

## Forking

To run a customized copy under your own user or org:

1. Fork or clone this repo to `<your-owner>/Claude-Project-Bootstrap`.
2. Update two metadata files:
   - `.claude-plugin/marketplace.json` → `owner.name`
   - `plugins/claude-project-bootstrap/.claude-plugin/plugin.json` → `author.name`
3. Push, then in Claude Code: `/plugin marketplace add <your-owner>/Claude-Project-Bootstrap`.

Templates under `plugins/claude-project-bootstrap/skills/*/templates/` are designed to be edited — your team's working-agreements, roadmap shape, and issue templates probably aren't identical to the defaults.

## Updating the plugin

Add `"autoUpdate": true` to a repo's committed marketplace entry and its installed plugins re-pin to the marketplace's `main` on each session start — push to the marketplace repo and consumers converge automatically, no per-repo reinstall. Bootstrap registers the marketplace source but leaves `autoUpdate` off; turn it on when you want hands-off updates.

Two things stay manual:

- **Template files** (working-agreements, issue templates) are *copied* into each repo at bootstrap, so autoUpdate doesn't touch them. Pull later improvements with `/claude-project-bootstrap:update-conventions` — a per-hunk reconcile.
- **Forcing an update** without waiting for a restart, or when autoUpdate is off:

  ```
  /plugin marketplace update claude-project-bootstrap
  /plugin install claude-project-bootstrap  # picks up the new version
  ```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). The contribution contract is the bundled working-agreements template.

## License

Licensed under the [MIT License](LICENSE).

This is an independent community project, not affiliated with or endorsed by Anthropic. "Claude" is a trademark of Anthropic, PBC.
