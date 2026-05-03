# claude-project-bootstrap

A Claude Code plugin: lay down the working-agreements + GitHub Project + `CLAUDE.md` hub-and-spokes setup on a new repo, in one command.

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

## Usage in a fresh repo

```bash
cd <new-repo>
/claude-project-bootstrap:bootstrap-working-agreements
```

The skill prompts for the bits it can't infer (project name, integration branch, milestones), confirms before creating issues / fields / files, and leaves you with a working setup in one pass.

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

## Migration — repos bootstrapped before recent template changes

Repos bootstrapped on older versions of this plugin won't retroactively pick up later template improvements (typed issue templates, new working-agreements sections, gitignore carve-outs, etc.). Two options after a plugin update lands:

1. **Re-run `bootstrap-working-agreements`** in the affected repo. The skill detects existing `.claude/rules/` files and prompts before overwriting — pick "refresh templates only" to update content while keeping decisions/local additions.
2. **One-shot type backfill for past untyped issues** (only relevant if the org has GitHub issue types and earlier issues were filed without them):

   ```bash
   for n in $(gh issue list -R <owner>/<repo> --json number,title -L 100 \
              --jq '.[] | select(.type==null) | .number'); do
     # title prefix → type mapping per org convention
     # e.g. [bug] → Bug, [feature] → Feature, otherwise → Task
     gh api -X PATCH repos/<owner>/<repo>/issues/$n -f type=<type-name>
   done
   ```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). The contribution contract is the bundled working-agreements template.

## License

Licensed under the [MIT License](LICENSE).

This is an independent community project, not affiliated with or endorsed by Anthropic. "Claude" is a trademark of Anthropic, PBC.
