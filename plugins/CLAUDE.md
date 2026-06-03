# `plugins/` — Claude guidance

**If touching root-level files (README, CONTRIBUTING, marketplace.json), refer to:** root `CLAUDE.md` · `.claude/rules/working-agreements.md` for lifecycle · [Claude-Project-Bootstrap GitHub Project](https://github.com/users/toBzh30/projects/2) (filter `Area` for pending work) — not auto-loaded outside this subtree.

This directory contains the plugin source. All substantive work happens here.

## Structure

```
plugins/
└── claude-project-bootstrap/
    ├── .claude-plugin/
    │   └── plugin.json          # plugin metadata (name, author)
    └── skills/
        ├── bootstrap-working-agreements/
        │   ├── SKILL.md         # orchestrator skill — calls the other two
        │   └── templates/       # files written into target repos at bootstrap time
        ├── github-project-setup/
        │   ├── SKILL.md         # GitHub Project v2 setup skill
        │   ├── scripts/         # migrate_doc.py — planning doc → issues migration
        │   └── templates/       # issue templates (feature.yml, bug.yml, roadmap.md)
        └── split-claudemd/
            └── SKILL.md         # CLAUDE.md hub-and-spokes refactor skill
```

## Key constraint: templates are copied, not linked

Files under `skills/*/templates/` are copied into target repos at bootstrap time. Changes here don't retroactively update already-bootstrapped repos — each target repo owns its copy from the moment it's written. When improving a template, assume no migration path exists for existing installs unless explicitly designed.

## Skill files (SKILL.md)

Each `SKILL.md` is both the skill definition and the executable instructions Claude follows when the skill is invoked. They are long by design — the steps are meant to be followed precisely, not summarised. When editing a skill:

- Use `Read` with `offset`/`limit` when you know which step you need — files range from ~300 to ~590 lines.
- The frontmatter (`allowed-tools`, `user-invocable`) is load-bearing — don't reformat it.
- Steps are numbered and sequential; inserting a step mid-skill shifts downstream references. Update any cross-references in the same commit.

## What each skill does

| Skill | Area tag | Notes |
|---|---|---|
| `bootstrap-working-agreements` | `bootstrap-working-agreements` | Orchestrator. Calls `github-project-setup` and `split-claudemd` as sub-steps. The template files here are the ones that land in target repos. |
| `github-project-setup` | `github-project-setup` | Heaviest skill (~590 lines). Handles single-repo and multi-repo project shapes. `migrate_doc.py` is a starting-point script — adapted per target project, not run as-is. |
| `split-claudemd` | `split-claudemd` | Lightest skill. Enforces the 200-line root CLAUDE.md cap. |

## Deferred / pending work

See the [Claude-Project-Bootstrap GitHub Project](https://github.com/users/toBzh30/projects/2) filtered by the relevant `Area` value for all pending work in this subtree.
