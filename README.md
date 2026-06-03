# claude-project-bootstrap

Work with Claude on a complex project the way you'd work with a great collaborator: shared context that persists across sessions, machines, and the natural limits of any single conversation. What you've already figured out doesn't need to be re-explained.

The foundation is a GitHub Project board Claude keeps current as you work — decisions recorded, deferred work visible, in-flight issues tracked. Claude files the issues and updates the board. You just pick what to work on next. No PM overhead, no `CLAUDE.md` that grows until it breaks.

And because it's GitHub, the whole team benefits. Anyone contributing to the repo sees the same board — what's in flight, what's been decided, what's parked. Claude working with one teammate doesn't create a private context that others are locked out of.

This plugin bootstraps that setup on any repo in one command.

## What's in it

Three skills, individually invocable:

| Skill | What it does |
|---|---|
| `/claude-project-bootstrap:bootstrap-working-agreements` | Orchestrator. Calls the other two, then writes `.claude/rules/working-agreements.md` and a starter root `CLAUDE.md` from templates with project-specific placeholders filled in. |
| `/claude-project-bootstrap:github-project-setup` | Bootstrap a GitHub Project (v2) with Status / Tier / Area / Priority / Effort fields, standard labels, issue templates, optional milestones + tracking issues. Optionally migrates an existing planning doc into auto-added issues. |
| `/claude-project-bootstrap:split-claudemd` | Refactor a long root `CLAUDE.md` into a short hub + per-subdir spokes + `.claude/rules/<topic>.md` topic files. Enforces the 200-line root cap. |

## Install

```bash
# In any Claude Code session:
/plugin marketplace add toBzh30/Claude-Project-Bootstrap
/plugin install claude-project-bootstrap
```

If you've forked this repo, replace `toBzh30` with your own GitHub user or org. If the host is private, only collaborators with read access can install it.

## Usage

**Fresh repo:**

```bash
cd <new-repo>
/claude-project-bootstrap:bootstrap-working-agreements
```

The skill prompts for the bits it can't infer (project name, integration branch, milestones), confirms before creating issues / fields / files, and leaves you with a working setup in one pass.

**Existing repo:**

Run the same command. The skill detects existing `.claude/rules/` files, a pre-existing GitHub Project, and any current issue templates — and prompts before touching anything. You can refresh templates while keeping local decisions, add fields to an existing board, or skip steps you've already done.

## Forking

To run a customized copy under your own user or org:

1. Fork or clone this repo to `<your-owner>/Claude-Project-Bootstrap`.
2. Update two metadata files:
   - `.claude-plugin/marketplace.json` → `owner.name`
   - `plugins/claude-project-bootstrap/.claude-plugin/plugin.json` → `author.name`
3. Push, then in Claude Code: `/plugin marketplace add <your-owner>/Claude-Project-Bootstrap`.

Templates under `plugins/claude-project-bootstrap/skills/*/templates/` are designed to be edited — your team's working-agreements, roadmap shape, and issue templates probably aren't identical to the defaults.

## Updating the plugin

Edit files in this repo, push to GitHub, then in any Claude Code session:

```
/plugin marketplace update claude-project-bootstrap
/plugin install claude-project-bootstrap  # picks up the new version
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). The contribution contract is the bundled working-agreements template.

## License

Licensed under the [MIT License](LICENSE).

This is an independent community project, not affiliated with or endorsed by Anthropic. "Claude" is a trademark of Anthropic, PBC.
