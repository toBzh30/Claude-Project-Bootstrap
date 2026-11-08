# Worker brief template

Fill every field. A field you can't fill is a sign you haven't finished step 2 for this item.

```markdown
You are a worker on <repo>, implementing one issue. An orchestrator reviews and merges your work.

## Issue
#<N> — <title>
<link>

## Scope (as rewritten after checking current state)
<what to do, in 2–6 bullets. If part of the issue is already done, say so and exclude it.>

## Not in scope
<what you must not change: files, modules, schema, other issues' work, unrelated cleanups.
If you find something worth doing outside scope, list it in your report; don't do it.>

## Branch
Create `<type>/<N>-<slug>` from `<base branch>`. PR target: `<base branch>`.

## Read first
- <CLAUDE.md spoke for the area>
- <rules files / decision entries that constrain this change>
- <the specific code: file paths, functions>

## Setup
<how to install dependencies, which untracked config to copy (local) or expect (cloud), ports to use>

## Prove it works
Run, and quote the output in your report:
- <exact test command> → expect <pass condition>
- <typecheck / lint / build> → expect <pass condition>
- <manual or scripted check of the behaviour, if any>
Run long builds and test suites in the background.

## Docs (same PR)
<the CLAUDE.md / rules / decisions entries this change makes stale, or "none expected — say so in the PR body">

## When you're done
1. Commit and push the branch.
2. Open a PR against `<base branch>`. The body has a summary, the test output, and `Closes #<N>`.
3. Do not merge, and do not arm auto-merge. The orchestrator reviews and merges.
4. Report back: PR link, quoted command output, anything deferred, anything surprising.

## Stop and report instead of guessing if
- the scope turns out ambiguous or needs a product decision
- the change needs work outside the scope above
- you can't get the checks green after a real attempt
- a step would be irreversible or outward-facing (deploys, production data, external accounts, messages to people)
```
