---
name: tdd
description: Test-driven development with red-green-refactor loop. Use when user wants to build features or fix bugs using TDD, mentions "red-green-refactor", wants integration tests, or asks for test-first development.
---

# Test-Driven Development

## Philosophy

**Core principle**: Tests should verify behavior through public interfaces, not implementation details. Code can change entirely; tests shouldn't.

**Good tests** are integration-style: they exercise real code paths through public APIs. They describe _what_ the system does, not _how_ it does it. A good test reads like a specification - "user can checkout with valid cart" tells you exactly what capability exists. These tests survive refactors because they don't care about internal structure.

**Bad tests** are coupled to implementation. They mock internal collaborators, test private methods, or verify through external means (like querying a database directly instead of using the interface). The warning sign: your test breaks when you refactor, but behavior hasn't changed. If you rename an internal function and tests fail, those tests were testing implementation, not behavior.

See [tests.md](tests.md) for examples and [mocking.md](mocking.md) for mocking guidelines.

## Anti-Pattern: Horizontal Slices

**DO NOT write all tests first, then all implementation.** This is "horizontal slicing" - treating RED as "write all tests" and GREEN as "write all code."

This produces **crap tests**:

- Tests written in bulk test _imagined_ behavior, not _actual_ behavior
- You end up testing the _shape_ of things (data structures, function signatures) rather than user-facing behavior
- Tests become insensitive to real changes - they pass when behavior breaks, fail when behavior is fine
- You outrun your headlights, committing to test structure before understanding the implementation

**Correct approach**: Vertical slices via tracer bullets. One test → one implementation → repeat. Each test responds to what you learned from the previous cycle. Because you just wrote the code, you know exactly what behavior matters and how to verify it.

```
WRONG (horizontal):
  RED:   test1, test2, test3, test4, test5
  GREEN: impl1, impl2, impl3, impl4, impl5

RIGHT (vertical):
  RED→GREEN: test1→impl1
  RED→GREEN: test2→impl2
  RED→GREEN: test3→impl3
  ...
```

## Workflow

### 1. Planning

When exploring the codebase, use the project's domain vocabulary from `CLAUDE.md` (and its linked spoke docs) so that test names and interface vocabulary match the project's language, and respect `.claude/rules/decisions.md` for decisions in the area you're touching.

Before writing any code:

- [ ] Confirm with user what interface changes are needed
- [ ] Confirm with user which behaviors to test (prioritize)
- [ ] Identify opportunities for [deep modules](deep-modules.md) (small interface, deep implementation)
- [ ] Design interfaces for [testability](interface-design.md)
- [ ] List the behaviors to test (not implementation steps)
- [ ] Get user approval on the plan

Ask: "What should the public interface look like? Which behaviors are most important to test?"

**You can't test everything.** Confirm with the user exactly which behaviors matter most. Focus testing effort on critical paths and complex logic, not every possible edge case.

> **AFK note.** "Get user approval on the plan" is a human checkpoint. Inside an explicitly-initiated AFK sweep, an `AFK`-tagged issue pre-authorizes it — proceed. Otherwise it's a real gate: get explicit approval before writing tests; never proceed on silence.

### 2. Tracer Bullet

Write ONE test that confirms ONE thing about the system:

```
RED:   Write test for first behavior → test fails
GREEN: Write minimal code to pass → test passes
```

This is your tracer bullet - proves the path works end-to-end.

### 3. Incremental Loop

For each remaining behavior:

```
RED:   Write next test → fails
GREEN: Minimal code to pass → passes
```

Rules:

- One test at a time
- Only enough code to pass current test
- Don't anticipate future tests
- Keep tests focused on observable behavior

### 4. Refactor

After all tests pass, look for [refactor candidates](refactoring.md):

- [ ] Extract duplication
- [ ] Deepen modules (move complexity behind simple interfaces)
- [ ] Apply SOLID principles where natural
- [ ] Consider what new code reveals about existing code
- [ ] Run tests after each refactor step

**Never refactor while RED.** Get to GREEN first.

## Cross-repo slices (when the slice spans repos)

The tracer bullet assumes "end-to-end" lives in one codebase. When a slice genuinely spans repos (e.g. a frontend repo + a backend repo joined by an API/event contract), the other repo is a **system boundary** — and [mocking.md](mocking.md)'s rule applies: mock at boundaries, never what you control. So:

1. **Agree the contract first.** The seam is a shared SDK-style interface (specific functions per operation — see [mocking.md](mocking.md)). Designing it is the explicit artifact of the Planning step above; get sign-off on the contract.
2. **Tracer-bullet each side against the contract** — normal single-repo red→green per side:
   - _Provider_ repo: RED = a test asserting it serves the contract shape for this behavior → GREEN.
   - _Consumer_ repo: RED = a test asserting it consumes the contract, mocking the provider **at the contract** (not at internal collaborators) → GREEN.
3. **One real cross-repo e2e proof per slice.** A mock can drift from reality; this is the only place the two real sides meet. Build it with the feedback-loop techniques from the `diagnose` skill (boot both, or run against shared dev/staging; assert the real round-trip).

Tool-agnostic: the contract check can be Pact, a shared schema + snapshot, or a scripted harness — the discipline is "prove each side against the contract, prove the integration once," not a specific tool. **Single-repo slices skip this section entirely.**

## Checklist Per Cycle

```
[ ] Test describes behavior, not implementation
[ ] Test uses public interface only
[ ] Test would survive internal refactor
[ ] Code is minimal for this test
[ ] No speculative features added
```
