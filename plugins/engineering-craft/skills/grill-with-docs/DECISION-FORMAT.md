# Decision-log format

Decisions are appended to a single `.claude/rules/decisions.md` file (**not** one numbered file per decision). Each entry:

```md
## YYYY-MM-DD — {one-line decision title}
**Decision:** {one sentence}
**Why:** {one or two sentences — the load-bearing reason, not the obvious context}
**Status:** Active / Superseded by {YYYY-MM-DD entry} / Reversed
```

This mirrors the repo's `working-agreements.md` → "When to log a decision". **Never delete or rewrite an entry.** When a decision is overturned, mark the old one `Superseded by {date}` and add a new entry.

## When to log one

All three must be true:

1. **Hard to reverse** — the cost of changing your mind later is meaningful.
2. **Surprising without context** — a future reader will look at the code and wonder "why on earth did they do it this way?"
3. **The result of a real trade-off** — there were genuine alternatives and you picked one for specific reasons.

If a decision is easy to reverse, skip it. If it's not surprising, nobody will wonder why. If there was no real alternative, there's nothing to record beyond "we did the obvious thing."

### What qualifies

- **Architectural shape.** "The write model is event-sourced, the read model is projected into Postgres."
- **Integration patterns between contexts.** "Ordering and Billing communicate via domain events, not synchronous HTTP."
- **Technology choices that carry lock-in.** Database, message bus, auth provider, deployment target — the ones that would take a quarter to swap out.
- **Boundary and scope decisions.** The explicit no-s are as valuable as the yes-s.
- **Deliberate deviations from the obvious path.** Anything where a reasonable reader would assume the opposite.
- **Constraints not visible in the code.** Compliance, latency budgets, partner-API contracts.
- **Rejected alternatives when the rejection is non-obvious** — otherwise someone re-proposes them in six months.
