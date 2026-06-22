# `plugins/` — Claude guidance

**If touching root-level files (README, CONTRIBUTING, marketplace.json), refer to:** root `CLAUDE.md` · `.claude/rules/working-agreements.md` for lifecycle · [Claude-Project-Bootstrap GitHub Project](https://github.com/users/toBzh30/projects/2) (filter `Area` for pending work) — not auto-loaded outside this subtree.

This directory contains the plugin source. All substantive work happens here.

## Structure

```
plugins/
├── claude-project-bootstrap/       # one-time project SETUP (run per new repo)
│   ├── .claude-plugin/
│   │   └── plugin.json          # plugin metadata (name, author)
│   ├── LICENSE                  # our MIT license (© toBzh30)
│   ├── hooks/                   # git/PR lifecycle hooks — auto-loaded in any repo where the plugin is enabled
│   │   ├── hooks.json           # registers the hooks on SessionStart + Bash Pre/PostToolUse
│   │   ├── preflight-branch.sh  # PreToolUse: collision guard before <type>/<N>- branch creation
│   │   ├── claim-branch.sh      # PostToolUse: assign @me + Status → In Progress (reads .claude/gh-project.json)
│   │   ├── doc-gate.sh          # PreToolUse: deny + direct Claude to update docs when a PR ships code but no docs
│   │   └── sibling-status.sh    # SessionStart: report-only cross-repo freshness + in-flight (opt-in: siblings.sync/.inflight)
│   └── skills/
│       ├── bootstrap-working-agreements/
│       │   ├── SKILL.md         # orchestrator skill — calls the other two
│       │   └── templates/       # files written into target repos at bootstrap time
│       ├── github-project-setup/
│       │   ├── SKILL.md         # GitHub Project v2 setup skill
│       │   ├── scripts/         # migrate_doc.py — planning doc → issues migration
│       │   └── templates/       # issue templates (feature.yml, bug.yml, roadmap.md)
│       ├── split-claudemd/
│       │   └── SKILL.md         # CLAUDE.md hub-and-spokes refactor skill
│       └── update-conventions/
│           └── SKILL.md         # pull plugin-template improvements into an already-bootstrapped repo
└── engineering-craft/              # ongoing CRAFT skills (enabled permanently) — mostly vendored from mattpocock/skills (MIT), plus homegrown skills
    ├── .claude-plugin/
    │   └── plugin.json
    ├── LICENSE                  # our MIT license (© toBzh30) — the plugin's original work
    ├── LICENSE-mattpocock       # Matt Pocock's MIT license (vendored skills)
    ├── ATTRIBUTION.md           # source pinned commit + adaptations + vendored-vs-original
    └── skills/                  # vendored: zoom-out, diagnose, tdd, prototype, grill-with-docs, improve-codebase-architecture, to-issues, to-prd · homegrown: checkpoint
        ├── zoom-out/
        │   └── SKILL.md
        └── checkpoint/          # homegrown (not from mattpocock) — session-handover skill
            └── SKILL.md
```

Two plugins, one marketplace, **different lifecycles**: `claude-project-bootstrap` is one-time *setup* (run once per repo); `engineering-craft` is ongoing *craft* (enabled permanently, used on every task). Separate plugins so a craft-skill fix doesn't re-pull setup tooling, and setup-only users aren't forced to take the craft skills. Most `engineering-craft` skills are **fork-and-adapt** from `mattpocock/skills` — see its `ATTRIBUTION.md` for the source commit and the adaptations (ADR/glossary paths, stripped AFK absence-detection, Project-contract issue creation); a few (e.g. `checkpoint`) are **homegrown** Claude-coding craft, not upstream. The **vendored** skills are **tool-agnostic discipline, never infrastructure**, so they land additively in repos with their own test setup.

## Hooks ship from the plugin (unlike templates)

The four `hooks/` scripts are **not** copied into target repos — they run *from* the plugin install, so improvements trickle down on marketplace update (the opposite of templates). They activate in any repo whose committed settings enable this plugin. All four **fail open / no-op** when their tooling (`gh`, `jq`, `git`) or config is missing, so an enabled-but-unconfigured repo is never blocked. Two need per-repo config in `.claude/gh-project.json` (written by `github-project-setup`): `claim-branch` reads the Project coordinates and no-ops when absent; `sibling-status` is doubly gated — it no-ops unless `siblings.sync == true`, so it's silent for every repo that hasn't explicitly opted in (the multi-repo, side-by-side case). `sibling-status` is **report-only** — it fetches but never merges/pulls/checks-out; it derives the siblings root from the session cwd's git toplevel (it runs from `${CLAUDE_PLUGIN_ROOT}`, outside any repo tree). `preflight-branch` and `doc-gate` need no config.

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
| `update-conventions` | `Templates` | Post-bootstrap maintenance. One-way pull-down: reconciles a repo's copied `working-agreements.md` + issue templates against the bundled templates. Not part of the bootstrap flow. |

## Deferred / pending work

See the [Claude-Project-Bootstrap GitHub Project](https://github.com/users/toBzh30/projects/2) filtered by the relevant `Area` value for all pending work in this subtree.
