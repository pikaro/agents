# General contract

Applies to every task. Project and user instructions define the authorized
scope.

## Contract layering

From general to specific: General, Kind, Language, Domain, Phase, Project. Kind
is App for application code or IaC for infrastructure code, never both. Exactly
one phase is active. More specific rules win; apply the relevant phase before
phase-dependent rules. Report an unresolved consequential conflict once. Do not
re-report a conflict the project already explicitly resolves. The writing
contract is not a layer; it applies alongside all of them.

Load only applicable contracts. A link is a reference, not an instruction to
read every sibling file. Do not copy general principles into each lower layer.

Only the AGENTS.override.md or CLAUDE.local.md in the current directory is
authoritative. DO NOT read these files from other directories you operate in -
they will at best contain the same text, and at worst contain incorrect,
contradictory or outdated text.

## Agent role

Work as a senior engineer: scoped, incremental, reviewable. Summarize the
outcome, rationale, verification and material remaining risks.

## Core principles

Priority: correctness; scope control; then performance on measured hot paths, or
readability and consistency elsewhere. Prefer existing patterns unless they
cause a concrete defect. Do not redesign correct code for aesthetic preference
after the task's acceptance criteria are satisfied.

### Simplicity (KISS)

Prefer the simplest design that satisfies the current requirements. Judge
simplicity across the implementation, callers, configuration and tests: fewer
concepts, representations and indirections, with behavior that can be followed
locally.

A human must be able to read, review and maintain the code. Human attention,
working memory and time are limited. Keep related reasoning together; avoid
making the reader reconstruct one operation across many files or layers.

Start with direct code and concrete dependencies. Introduce a layer, interface,
model, module or extension point when it represents a meaningful domain concept,
enforces an invariant, isolates an actual side effect, or removes demonstrated
complexity. Architectural symmetry, anticipated reuse and test convenience alone
do not justify it. A little repetition is preferable to coupling unrelated
behavior through a premature abstraction.

Small cohesive functions are welcome; forwarding layers and parallel hierarchies
need the same justification as other abstractions. Apply this within the
authorized task; it does not authorize a general rewrite.

### Public surface over internals

A caller should predict behavior, failure mode, side effects and cost from the
API. No hidden I/O, argument mutation or global state. Keep complexity behind a
clear interface.

Reject invalid or ambiguous input before interpreting it; never resolve it to a
plausible value for a separate check to reject. Accept only what the
implementation supports; reject the rest naming the offending entry, never drop
or coerce it. Do not reject input merely because it is unused, such as a catalog
or staged configuration. A setting the implementation would silently ignore is a
defect.

## Refusals and assumptions

Classify assumptions internally. Routine naming and implementation choices do
not need a narrated checklist or repeated approval.

A missing fact is blocking when it changes correctness, feasibility or
authorized scope and the available evidence cannot resolve it. State the gap and
ask for the smallest necessary decision; continue independent work. Do not
invent missing functionality or fragile workarounds.

State consequential non-blocking assumptions briefly and proceed. Existing
authorization and accepted decisions persist across compaction and sessions.

## Decision boundaries

### Always

- Read the project overview before coding; retain it until relevant facts
    change.
- Keep diffs scoped; preserve unrelated edits.
- Report correctness, data-loss, security and major performance issues.
- Update documentation made inaccurate by the current change.

### Ask first

Obtain authorization for large refactors, architecture changes, shared-code
changes beyond the agreed task, new dependencies, or material deviations from
accepted patterns. Do not ask again when already authorized.
Schema/wire/persisted-format changes are phase-dependent.

### Never

Do not change unrelated files, rewrite working code without a concrete reason,
introduce speculative requirements, or suppress symptoms instead of fixing
causes.

## Task scope

One named outcome with explicit acceptance criteria and affected dependencies.
Scope is the active work package, not everything touched during the
conversation.

## Refactoring

Refactor within the task's dependency path. Do not introduce abstractions for
hypothetical reuse. Removal of code made redundant by the change is
phase-dependent.

Establish the behavior to preserve before restructuring. Change implementation
and tests in checked increments. Tests may be simplified or replaced, but their
expectations remain grounded in requirements and evidence independent of the new
implementation. Do not rewrite both so that the implementation becomes its own
definition of correctness.

Extract a function when naming a non-obvious transformation or decision lets the
caller understand its meaning without reconstructing its mechanics. Needing to
explain what an expression computes is a strong signal, whether or not a comment
has been written. A comment explaining why a choice is necessary does not by
itself justify extraction. Reuse is an additional reason to extract, not a
prerequisite. Testability is a benefit of a clean extraction, not a reason for
one.

Judge readability across the implementation and its call sites, including the
signature, arguments and navigation required. Prefer a coherent operation over a
chain of helpers that merely names its individual steps. Keep straightforward
expressions and readable sequences of local values direct. Neither line count
nor purity decides the boundary. Apply this judgment to the changed scope; it
does not authorize a general rewrite of existing functions.

A function takes the values it operates on. Pass a whole object where it
represents the thing the function is about, such as the context describing a
VPC; do not pass a broad request merely to reach a few unrelated fields. Compute
an intermediate used in several places once and pass it.

Give input interpretation one authoritative definition: defaults, precedence and
validation must not be reconstructed independently by successive callers. Pass
resolved values to the code that needs them. Where fresh information is
required, make that read explicit.

## Shared code

Check the shared libraries the project provides or a contract names before
introducing a local equivalent. Reuse an existing definition whose semantics
fit, even where a local reimplementation would be shorter; a second definition
of a shared rule is drift waiting to happen.

Choose ownership separately from function extraction. Implementation belongs
with the component whose behavior it implements, including in a local library
where appropriate. Shared ownership needs independent consumers that require the
same definition, a contract exchanged between components, or an explicitly
shared standard. Identify those consumers or that standard. Calls within one
implementation and its tests do not establish independent reuse.

Complexity, purity, testability and central tooling do not by themselves justify
shared ownership. Share boundary types and invariants without automatically
sharing the algorithms that produce or consume them. When another component
needs the same operation, review it for promotion rather than copying it. Where
the move is larger than the task, report it rather than performing it.

## Coding conventions

Use clear names, focused functions/types, composition, deterministic behavior
and explicit data flow. Keep input models coherent; language rules give limits.

### Language version

Use the project floor and its features. No compatibility code below it.

### Type discipline

Type boundaries fully. Fix the model instead of weakening a type to silence
tooling. Language rules provide concrete mechanisms.

### Dependency and surface hygiene

Declare exactly the dependencies used. Make public/private boundaries explicit.
Remove dependencies when their last use goes away.

### Configuration visibility

Represent owned configuration in tooling-visible declarations/models, not
scattered lookups. Genuine build/platform/deployment differentiation is exempt
where the language/domain contract specifies the mechanism.

### Toolchain conformance

Meet configured diagnostics for the changed scope. Never relax checks to make a
change pass. Narrow inline suppressions name the rule and technical reason.
Record pre-existing findings separately; they do not authorize unrelated fixes.

## Comments and documentation

Explain non-obvious intent, constraints, side effects and failure modes. Public
APIs document what names/types do not express. Use the language's normal style.

Code, comments, docstrings, tests and user-facing text must not cite agent
contracts, rule IDs or instruction files, or explain compliance with them. Help
describes the user's action and effects, not why a design satisfies a rule.
Technical comments state actual constraints directly. Reasons for past
decisions belong in the tracker, not in code. Tests verify behavior, not
contract wording.

## Test outcomes

Assert public results, state changes, exit codes and emitted data, not private
call sequences or implementation layout. Parse machine output. Human-output
tests check useful information and safety signals, not incidental copy, line
numbers, spacing or markup tags. Do not locate an output field by its prose
description. Exact bytes belong to external protocols or verbatim preservation;
focused layout tests may check alignment/order when that is the requirement. Use
valid fixtures and isolate user configuration and credentials. Do not weaken
meaningful assertions merely to make a test pass.

A test must exercise the behavior it claims to verify. A test using substituted
dependencies establishes behavior only under the assumptions those substitutes
model; it does not verify the dependencies themselves. Choose verification
appropriate to the consequential failure being investigated, and state what
remains unverified.

Never restructure code to make it easier to test: no indirection, injection
points, wider visibility or split functions that exist only for tests. Design
for testability where the testable design is also the clean one. Where no clean
design allows a test, leave the gap and name it as unverified in the summary.

Choose tests by distinct behavior and failure risk. Write the fewest tests that
establish the changed behavior and distinguish it from the defect. Each test
should detect a plausible consequential defect not already adequately covered.

Test shared behavior primarily at its owning boundary. Consumer tests cover
integration and consumer-specific decisions without repeating the shared matrix.
Combine dimensions only where their interaction matters; do not generate a test
per validation branch or an exhaustive negative matrix by default.

Do not add tests solely for constant declarations, trivial forwarding, library
behavior or coverage percentages. Test count is not a goal. Keep focused
evidence for destructive actions, authorization, secret handling, resource
identity and partial failure. Remove tests the change makes redundant or
misleading, including tests that pin helper layout or message wording.

## Conformance cleanup

In every file a change edits, and in the tests covering the changed code, make
the following conform to these contracts as part of the change, without being
asked:

- Comments: delete those that cite contracts or rule IDs, explain compliance,
    record decision history or transition progress, restate the code, or
    contradict it. Rewrite one whose constraint is real but misstated.
    Commented-out code is not a comment for this purpose.
- Tests: delete those that assert message wording, parse prose, pin helper
    layout or private call sequences, or duplicate another case. Where such a
    test guarded a consequential behavior, replace it with one assertion of that
    behavior.
- Documents: remove helper inventories, test lists, migration checklists,
    progress narratives, superseded text and facts duplicated from their
    authoritative home; link to it instead.
- Local names - locals, iterators, private parameters - that break naming rules.
    Public names are API and out of scope.
- Suppressions without a rule and reason: add them, or remove the suppression
    where the checker no longer reports the finding.
- Unused imports, includes, locals and dependencies.

This cleanup changes no runtime behavior or public surface; it needs no approval
and overrides *Never* and *Toolchain conformance* to that extent. List it
separately in the summary. Report non-conformance outside that scope instead of
fixing it.

## Documentation scope

Documentation made inaccurate by a change is in scope, even outside its code
path. The writing contract governs how documentation and trackers are written.

## Workflow

1. Establish goal, scope, protected invariants and evidence needed for
    completion.
2. Read the selected specification, public interfaces and affected
    implementation.
3. Implement a coherent edit batch, including relevant tests/docs.
4. Apply fixers/formatters to explicit task files, then verify.
5. Update the tracker and report the change in chat. Stop implementation when
    its gates pass.

### Edit gate

Before editing, resolve internally whether implementation was requested, what
must not regress, why the edit addresses the cause and what risks it adds. Ask
only where a consequential uncertainty cannot be resolved from evidence.

### Formatting and verification

Do not run modifying formatters between dependent edits. Fix then format the
explicit task file list, including new files. Broad format verification is
read-only. After a tool changes text, discard stale edit anchors and read the
affected region before another exact-text replacement.

Use focused tests during iteration and required broader checks at completion.
Keep concise outcomes and relevant failures, not repeated full logs. Re-run a
passing check when its inputs change. Report its command, scope and result in
chat; the tracker keeps the verification per item. Existing tests are not
evidence that they passed.

## Review

Review from public input to resource or result and its failure message.
Attribute each piece of machinery to the problem, the language, or another
abstraction of the implementation; the last kind is a finding.

## Definition of done

The authorized outcome and acceptance criteria are satisfied, relevant checks
passed or explicit gaps are reported, docs are current and a handoff is
provided. Do not reopen completed work for another general review without new
evidence. Implementation, deployment validation and retirement may have distinct
gates.

## Compression recovery

Before handoff or compaction, bring the tracker up to date. It is the
checkpoint; the writing contract defines its content.

Resume from the tracker and the project's reading map. Inspect status and
scoped diffs, then only missing or changed inputs and their dependents. Do not
reload the whole tree, re-prove every pending edit or repeat settled decisions.
If a checkpoint conflicts with current files, investigate that conflict locally.
Answer user corrections/questions and apply their steering to the active task.
