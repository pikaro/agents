# Dev phase contract

Active phase. Extends General; overrides the rules marked **phase-dependent**
there. Exactly one phase contract is active; the project contract declares which.

Premise: the project is in active development with no external consumers.
Backwards compatibility is not a requirement.

______________________________________________________________________

## Breaking changes

- Break internal APIs, on-wire formats, schemas, persisted formats and file
    layouts where the change improves the project.
- The condition is that **both sides can be fixed**: every producer and every
    consumer is in this repository and is updated in the same change. Fix them.
- Where a consumer cannot be found or cannot be updated in the same change, the
    break is a blocking assumption. Do not break and leave a caller stale.
- Overrides *General → Ask first* for schema, wire-format and persisted-format
    changes: breakage alone is not a reason to ask. Scope still is - a change
    touching many call sites, or shared code beyond the task's path, remains
    ask-first for its blast radius.

## What not to write

- No compatibility shims, adapter layers, or dual-path readers.
- No deprecation markers, deprecation periods, or forwarding stubs.
- No version negotiation, version fields, or tolerant readers added
    speculatively. Add a version field only where the runtime genuinely needs to
    distinguish versions.
- No migration code for a format that has no persisted data worth keeping.
- No configuration switch to select old and new behavior. Pick the new behavior.

## Simplification

- Where a change makes existing code redundant, remove it. Dead code left behind
    is an incomplete change.
- Where a change elsewhere has made a construct unnecessary - a parameter now
    always the same, a branch now unreachable, an abstraction now with one
    implementation, a conversion now between identical types - simplify it.
- Overrides *General → Refactoring* and *General → Never* to this extent: the
    simplification must be *enabled by* a change in the current session and
    traceable to it. Opportunistic cleanup that is not is out of scope - report it
    instead.
- Where the enabled simplification is large or crosses into shared code, report
    it and ask rather than performing it.

## Coordinated deployment

- A break in a format shared between separately deployed units requires all
    affected units to be updated together. Name them in the summary.
- On device, that means the affected environments are reflashed together; the
    affected set is determined as in *Embedded → Rebuilding*.

## Always

- Update every call site, test, and document affected by a break, in the same
    change.
- State in the summary what was broken and what was updated to match.
