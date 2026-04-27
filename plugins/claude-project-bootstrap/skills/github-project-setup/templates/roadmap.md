# Roadmap

We ship by **milestone**, not by feature. Each milestone has a defined "done bar" and an explicit out-of-scope list. Hold each other accountable to "is this in scope for the current milestone?" — if it's not on the bar or the out-of-scope list, we don't add it without updating this doc.

**Tier ≠ Milestone.** Tier is *which user surface this serves*. Milestone is *which release ships this*. Some issues with the same tier land in different milestones (some gate the early release, others are polish for later). Don't conflate the two axes.

## How tracking works

- **GitHub Milestones** (<list yours: e.g. Alpha, Beta, GA>): source of truth for issue assignment + progress %.
- **This doc**: the bar + out-of-scope rationale for each milestone. Auto-loaded in Claude sessions so neither of us has to re-derive scope.
- **Project board**: day-to-day work, with the built-in Milestone field mirroring the GitHub milestone.
- **Tracking issue per milestone** (`[milestone] X` etc.): markdown checklist of sub-issues, auto-checked when sub-issues close. Closing the tracking issue = "we shipped this milestone".

When tempted to add a thing to the current milestone:
1. Open this doc.
2. If it isn't in the bar or the out-of-scope list, edit this doc *first* to add it (with rationale), then proceed.
3. If it crosses milestones, defer — we ship the current bar, not a moving target.

---

## <Milestone 1 name, e.g. Alpha>

**Bar**: <one paragraph describing concretely what shipping this milestone means — who uses it, what they do, where it runs. Avoid feature lists; describe the experience.>

**Tracking**: `[milestone] <name>`

**In scope**:
- #N <issue title>
- #N <issue title>
- (gap) <thing that needs an issue but doesn't have one yet>

**Out of scope** (do not build for <milestone>):
- <explicit list of things that would be tempting to add but should wait>
- <especially things that map to *later* milestones — calling them out here protects scope>

---

## <Milestone 2>

**Bar**: …

**Tracking**: `[milestone] …`

**In scope**:
- …

**Out of scope**:
- …

---

<repeat per milestone>

---

## Notes

- `(gap)` markers indicate scope items that don't have an issue yet — open them when you start that milestone, or sooner if planning depends on them.
- Out-of-scope lists exist to be edited as we learn. If something keeps coming up, it probably belongs *in* scope — but the cost of adding it should be visible (this doc grows).
- A milestone with "TBD" in its bar is unbaked. Bake it before you start working sub-issues for it; otherwise the bar drifts to whatever feels natural mid-flight.
