# CLAUDE.md

## What Claude-Project-Bootstrap is

The source repo for the `claude-project-bootstrap` Claude Code plugin. Contains the three skills (`bootstrap-working-agreements`, `github-project-setup`, `split-claudemd`), their templates, and the marketplace metadata. Work here means changes to the plugin itself — new skill steps, template improvements, bug fixes. The GitHub Project tracks that work; the working agreements here are also the bundled template that gets installed in target repos.

## What's built vs pending

| Skill / Area | Status |
|---|---|
| `github-project-setup` | Done |
| `bootstrap-working-agreements` | Done |
| `split-claudemd` | Done |
| Issue templates (`.github/ISSUE_TEMPLATE/`) | Done |
| Dogfooding (bootstrap applied to this repo) | In progress |
| Make repo public | Pending |

This table is a snapshot. **Live planning source is the [Claude-Project-Bootstrap GitHub Project](https://github.com/users/toBzh30/projects/2)** — query it via `gh project item-list 2 --owner toBzh30` for current state before answering "what's next" or proposing work.

---

## Detailed guidance

- `plugins/CLAUDE.md` — plugin structure, skill layout, what lives where
- `.claude/rules/working-agreements.md` — issue/PR/branch lifecycle, scope discipline, lifecycle ownership. **Read at session start.**
- `.claude/rules/decisions.md` — *why* things are the way they are. Read when a rule looks arbitrary or a path you'd suggest was already considered and rejected.
- [Claude-Project-Bootstrap GitHub Project](https://github.com/users/toBzh30/projects/2) — all planned features, bugs, and tech-debt (Area × Priority)

---

## Working agreements

All sessions on this repo follow `.claude/rules/working-agreements.md` — issue/PR/branch lifecycle, when to file vs not, scope discipline, lifecycle ownership. **Read it at session start before answering "what's next" or proposing work.** The user drives product intent through conversation; Claude maintains the project board state automatically.

---

## Branch strategy

`main` is the integration branch and the default branch. Merge to `main` when the change is stable and the PR has been reviewed. Feature branches follow `<type>/<issue-num>-<slug>` — see working-agreements.md for the full lifecycle.

## Keeping these files current

| When (concrete trigger) | What to update |
|---|---|
| A skill's behaviour changes | Update the relevant `SKILL.md` in the same commit |
| A "Pending" row above ships | Move to "Done" in the snapshot table |
| Issue ships via PR | Close via `Closes #N` in PR body |
| New gotcha / constraint found | Append to `plugins/CLAUDE.md` or relevant `.claude/rules/<topic>.md` |
| Stale fact found | Correct it in place — same commit as the rename if possible |

## Git

Always push immediately after each commit.
