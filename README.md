# claude-project-bootstrap

A private Claude Code plugin: lay down the working-agreements + GitHub Project + `CLAUDE.md` hub-and-spokes setup on a new repo, in one command.

## What's in it

Three skills, individually invocable:

| Skill | What it does |
|---|---|
| `/claude-project-bootstrap:bootstrap-working-agreements` | Orchestrator. Calls the other two, then writes `.claude/rules/working-agreements.md` and a starter root `CLAUDE.md` from templates with project-specific placeholders filled in. |
| `/claude-project-bootstrap:github-project-setup` | Bootstrap a GitHub Project (v2) with Status / Tier / Area / Priority / Effort fields, standard labels, issue templates, optional milestones + tracking issues. Optionally migrates an existing planning doc into auto-added issues. |
| `/claude-project-bootstrap:split-claudemd` | Refactor a long root `CLAUDE.md` into a short hub + per-subdir spokes + `.claude/rules/<topic>.md` topic files. Enforces the 200-line root cap. |

## Install (private repo)

```bash
# In any Claude Code session:
/plugin marketplace add blumenau1001011/claude-project-bootstrap
/plugin install claude-project-bootstrap
```

The repo is private — only collaborators with read access on `blumenau1001011/claude-project-bootstrap` can install it.

## Usage in a fresh repo

```bash
cd <new-repo>
/claude-project-bootstrap:bootstrap-working-agreements
```

The skill prompts for the bits it can't infer (project name, integration branch, milestones), confirms before creating issues / fields / files, and leaves you with a working setup in one pass.

## Updating the plugin

Edit files in this repo, push to GitHub, then in any Claude Code session:

```
/plugin marketplace update claude-project-bootstrap
/plugin install claude-project-bootstrap  # picks up the new version
```
