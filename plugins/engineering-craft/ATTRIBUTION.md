# Attribution

**Scope: this file covers the `engineering-craft` plugin only.** The sibling `claude-project-bootstrap` plugin — the working-agreements templates, `github-project-setup`, `split-claudemd`, `update-conventions`, and the git/PR hooks — is entirely original work © 2026 toBzh30 with no upstream; it appears below only because the vendored skills were *adapted to integrate with it*.

**Most** skills in this plugin are vendored and adapted from **[mattpocock/skills](https://github.com/mattpocock/skills)** — © 2026 Matt Pocock, MIT-licensed (see [`LICENSE-mattpocock`](./LICENSE-mattpocock)). A few are **homegrown** and not derived from upstream (see *Homegrown* below). The plugin's own original work is © 2026 toBzh30, MIT-licensed (see [`LICENSE`](./LICENSE)).

- **Source:** `mattpocock/skills` at pinned commit `733d312884b3878a9a9cff693c5886943753a741`, `skills/engineering/`.
- **Nature:** fork-and-**adapt**, not redistribution-unchanged. The skills are modified to fit this marketplace's conventions and the AFK/HITL execution model. Divergence from upstream is intentional.

## Adaptations applied

- ADR references (`docs/adr/`) → `.claude/rules/decisions.md`.
- Domain glossary / `CONTEXT.md` → the `CLAUDE.md` hub (and its linked spoke docs).
- Matt's "proceed if the user is AFK" absence-detection → **removed**; craft-loop checkpoints proceed only inside an explicitly-initiated AFK sweep, otherwise they wait (silence is not approval — see the consuming repo's `working-agreements.md` → *AFK vs HITL issues*).
- Issue / PR creation → the `github-project-setup` Project contract (labels, Area/Priority/Mode, auto-add to Project).
- Matt's per-slice `Type: HITL / AFK` classification (`to-issues`) and AFK-ready triage label → the Project `Mode` field, governed by the authorize-≠-initiate model (see *Original work*).

## Not vendored

- `triage` — superseded by this marketplace's Status/label workflow.
- `setup-matt-pocock-skills` — superseded by `bootstrap-working-agreements` + `github-project-setup`.

## Original work (not derived from upstream)

The adaptations above and the **integration wiring** into the `claude-project-bootstrap` plugin are original work © 2026 toBzh30, layered on Matt's MIT base. Matt's skills are the *basis*, not a 1:1 copy; the integration is ours.

On **AFK/HITL** specifically, the line runs through the middle: the *terminology* and the idea of classifying work as AFK-able vs human-in-the-loop are upstream (Matt's `to-issues` slices carry `Type: HITL / AFK`; his `triage` has an AFK-ready label; his skills proceed on detected user absence). Original here is the **governance layer** built on that vocabulary — `Mode` as a Project field, authorize ≠ initiate (only an explicit human instruction starts a sweep; silence never does), the sequential sweep with park-and-continue and downgrade triggers, and the config-driven merge gate — which deliberately *inverts* upstream's "prefer AFK / proceed on absence" default.

## Homegrown

Skills written from scratch for this marketplace, **not** derived from `mattpocock/skills` (Matt's MIT license does not cover them):

- `checkpoint` — session-handover skill; writes a resumable handover to `~/.claude/handovers/` before a context reset. Claude-coding craft, not an upstream engineering skill.

The **vendored** skills are written as **tool-agnostic discipline, never infrastructure** — they teach test-first / mock-at-boundary / contract-at-seam, and never prescribe a test framework or CI shape, so they land additively in repos that already have their own test setup.
