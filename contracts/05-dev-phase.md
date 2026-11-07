# Dev phase contract

Active phase. Extends General; overrides the rules marked **phase-dependent**
there. Exactly one phase contract is active; the project contract declares
which.

Premise: the project is in active development. API compatibility is not a
requirement. Preserving deployed resources is: an API change must not replace or
rekey existing resources unless that is its purpose.

## Breaking changes

- Break internal APIs, on-wire formats, schemas, persisted formats and file
    layouts where the change improves the project.
- The condition is that **both sides are fixed**: update every producer and
    consumer in the authorized repositories in the same change.
- A consumer you find outside that scope, such as a deployment root, is not a
    reason to keep a faulty interface. Flag it in the handoff, summarize what
    must change and why, and offer to provide the change set.
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
- No transition or progress notes in code: no "until phase 2", migration
    checklists or deployment inventories. Coordination belongs in the handoff.

## Simplification

- Do *not* remove commented-out code. Assume that commented-out code represents
    a feature toggle, draft or experiment that is currently unused.
- Where a change makes existing code redundant, remove it. Dead code left behind
    is an incomplete change.
- Where a change elsewhere has made a construct unnecessary - a parameter now
    always the same, a branch now unreachable, an abstraction now with one
    implementation, a conversion now between identical types - simplify it.
- Overrides *General → Refactoring* and *General → Never* to this extent: the
    simplification must be *enabled by* a change in the active work package and
    traceable to it. Opportunistic cleanup that is not is out of scope - report
    it instead.
- Where the enabled simplification is large or crosses into shared code, report
    it and ask rather than performing it.

## Coordinated deployment

- A break in a format shared between separately deployed units requires all
    affected units to be updated together. Name them in the summary.

## Always

- Update every call site, test, and document affected by a break, in the same
    change.
- Hand off every API change: module, old → new input/output or default,
    affected callers, edits made, edits the owner must still make, expected
    resource effects.
