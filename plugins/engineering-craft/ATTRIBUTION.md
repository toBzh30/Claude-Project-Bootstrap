# Attribution

The skills in this plugin are vendored and adapted from **[mattpocock/skills](https://github.com/mattpocock/skills)** — © 2026 Matt Pocock, MIT-licensed (see [`LICENSE`](./LICENSE)).

- **Source:** `mattpocock/skills` at pinned commit `733d312884b3878a9a9cff693c5886943753a741`, `skills/engineering/`.
- **Nature:** fork-and-**adapt**, not redistribution-unchanged. The skills are modified to fit this marketplace's conventions and the AFK/HITL execution model. Divergence from upstream is intentional.

## Adaptations applied

- ADR references (`docs/adr/`) → `.claude/rules/decisions.md`.
- Domain glossary / `CONTEXT.md` → the `CLAUDE.md` hub (and its linked spoke docs).
- Matt's "proceed if the user is AFK" absence-detection → **removed**; craft-loop checkpoints proceed only inside an explicitly-initiated AFK sweep, otherwise they wait (silence is not approval — see the consuming repo's `working-agreements.md` → *AFK vs HITL issues*).
- Issue / PR creation → the `github-project-setup` Project contract (labels, Area/Priority/Mode, auto-add to Project).

## Not vendored

- `triage` — superseded by this marketplace's Status/label workflow.
- `setup-matt-pocock-skills` — superseded by `bootstrap-working-agreements` + `github-project-setup`.

The skills are written as **tool-agnostic discipline, never infrastructure** — they teach test-first / mock-at-boundary / contract-at-seam, and never prescribe a test framework or CI shape, so they land additively in repos that already have their own test setup.
