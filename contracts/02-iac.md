# IaC contract

Kind contract for infrastructure code. Extends General; mutually exclusive with
App. Language contracts give the tool-specific mechanisms.

## Boundary

The repository is the desired state. The agent never reaches a live environment:
no apply, no plan, no state, no provider API, no credentials.

- You **must never** attempt to access or modify live resources, and you will
    not receive the access required to do so.
- A request to change infrastructure means edit the configuration. It never
    means running the deployment tool.
- Expect plan or state files as evidence only if user-supplied. Extract
    machine-readable data from them where possible. Both are secret material:
    read the addresses you need rather than dumping the file.
- Flag in the summary any edit you expect to destroy, replace or move an object,
    and state the expected plan delta by address: created, updated, replaced,
    moved, destroyed. Without a plan that is the user's only warning.
- State is unreachable. When an edit renames or removes a resource that is
    already deployed, record the rename or removal in the configuration so the
    tool can act on the existing object. Record nothing for resources that were
    never deployed.

## Identity

- Choose resource keys and identifying values, such as an allocated subnet
    index, so they change only when the object they identify changes. Never
    derive one from list position or from content that changes on its own, such
    as a route table's current routes.
- This governs keys you introduce. Changing the key of a deployed resource moves
    or replaces it, so do not rekey existing resources to meet this rule unless
    that is the task. Report an unstable existing key instead.

## Validation

- Within a module, implement each rule once. A check on a derived value
    references the intermediate value that resource construction uses; it does
    not compute that value a second time.
- Where a later step loses information a check needs, such as deduplicating,
    merging or projecting keys, check the value before that step. This never
    justifies loosening an input's declared type.
- Where an intermediate fails on invalid input, accept the native error if it
    identifies the offending input and problem. Otherwise guard only the failing
    expression so the relevant check runs and reports it. The guard's fallback,
    such as `null`, only lets that check fail; it is never a plausible value
    for resource construction to use. Never rebuild the intermediate in a
    tolerant form solely for validation.
- Add custom validation for module semantics, unsafe combinations, silently
    ignored inputs and errors that would otherwise surface only at apply. Do not
    add a check that merely rewords an adequate language or provider error.
- Write one check per problem the user can fix on its own. If offending keys are
    already known, name them, but do not repeat the failure condition only to
    compute them again. Combine conditions only when they form one rule, such as
    "exactly one of". Never gather checks into a function or value that returns
    a list of problems. Check a rule about a whole collection once, not per
    resource instance.
- Never make resource construction pick among, repair or skip invalid input:
    taking the first of conflicting claimants, substituting a value for an
    unknown reference, dropping an unresolvable entry. Documented defaults and
    optional values are not affected.

## Dependencies and lifecycle

- Add an explicit dependency only where a resource must wait for another to be
    ready and no reference already says so. Never add one to order, gate or
    deduplicate checks. Depend on the specific resource or output a step needs,
    never a whole component.
- An output that other configurations consume depends on everything they need to
    use it - shares, grants, policies - not only on the resource that yields the
    ID. Otherwise a consumer can receive the ID before it has access.
- When the provider requires one resource to exist before another, express it as
    a reference or explicit dependency, not only in a comment or description.
    Check that destroy then runs in a working order as well.
- When your edit changes an argument that forces replacement, check whether the
    provider can actually destroy and recreate that object while other resources
    still use it. It typically cannot when other resources reference it,
    something is attached to or associated with it, or it holds a fixed address
    or name the new object needs.
- If the replacement cannot succeed, find a change that does not force
    replacement. If there is none, report it and ask. Never restructure
    dependents or other resources so that they tolerate the replacement.
- Destruction protection does not solve this. It makes the plan fail instead of
    replacing the object.

## Versions

- Version constraints for the tool and each provider state the version the
    configuration actually requires. Raise one when a change uses newer
    functionality. Never lower one to make a check pass.

## Secrets

- No secret value in the repository, in a variable file, or in a default. State
    and plan files hold secrets in cleartext and are never committed.
- Where possible, do not generate secret values such as passwords or private
    keys through the deployment tool; they end up in state. Pass a reference
    such as a parameter ARN and let the consumer resolve the value.
- Redacting an output is not storage security.

## Structure and tests

- Do not write a module for hypothetical reuse. Do not create a module that has
    one caller and only passes its variables through; report an existing one.
- Mocks do not enforce provider prerequisites, ordering, replacement or
    authorization. Establish those by reading the configuration and the
    provider's documentation or source; report what remains unverified rather
    than adding mock cases.
- Never add a dependency, variable, output or resource to production
    configuration only to work around a test-runner limitation.
