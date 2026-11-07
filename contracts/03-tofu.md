# OpenTofu contract

Extends General and IaC. OpenTofu, not Terraform.

## Not Terraform

- The CLI is `tofu`. The registry is `registry.opentofu.org`. For language and
    CLI behavior HashiCorp documentation describes a different product; do not
    cite it. Provider documentation remains authoritative for its provider.
- No HCP Terraform or Terraform Enterprise: no `cloud` block, no Sentinel, no
    run tasks, no no-code modules.
- Before using a language feature, check that OpenTofu implements it and not
    only Terraform. Where new code needs one of these, use the OpenTofu
    mechanism: state encryption, early variable evaluation, provider `for_each`,
    ephemeral resources and write-only attributes, symbol libraries. Do not
    convert existing code to them unless that is the task.
- Terraform-era tooling is acceptable where it parses OpenTofu correctly. Judge
    it by behavior, not by name.

## Boundary

- Validate through `prek run --group agent --files <paths>`. Do not run `test`,
    `validate` or `fmt` directly. The hooks modify files, so run them at the end
    of a task, never between dependent edits. Needing them repeatedly mid-task
    means the task is too broad.
- Prefer a JSON rendering of a supplied plan or state over its text rendering.
- Express renames and removals as `moved` and `removed` blocks. Every `removed`
    block declares `lifecycle { destroy = ... }`; say which was chosen.
    Module-local moves go in the module's `moved.tf`, caller moves in the
    deployment root.

## Versions

- `.terraform.lock.hcl` carries hashes for every platform deployed to.
    Refreshing it needs the toolchain, so a constraint change is reported as a
    handoff action naming the platforms, not left as a silent gap.

## Typing

- Every variable declares an explicit `type`. `any` is a defect wherever the
    value has a knowable shape. It is not a shortcut for a long type, nor a
    placeholder for one not yet written.
- `any` is correct where the value is genuinely untypable: an opaque passthrough
    the module never reads, a container whose entries differ in shape, a
    structure the type system cannot express such as a recursive document, or a
    parameter that operates on structure rather than content - a merge, a key
    projection, a conformance check. Say which at the declaration.
- Type the part that is knowable: `object({ id = string, payload = any })` beats
    `any`.
- `map(any)` does not mean heterogeneous - every element converges to one type.
    Where entries differ in shape the opacity belongs at the top, not inside a
    collection type.
- A parameter typed `any` gives up its diagnostics. A typed parameter fails with
    a named error at the call; `any` fails later and somewhere else. Weigh that
    rather than treating it as a prohibition, and validate the structure you do
    rely on.
- Constrain object types. Use `optional()` with a default rather than a loose
    map. Use `nullable = false` where null is not a value.
- Each check per *IaC → Validation* is one `validation` or `precondition` block:
    - Use `variable` -> `validation` for a self-contained check.
    - Use `terraform_data` -> `lifecycle { precondition }` for a cross-variable
        invariant or evaluation against locals. Cross-variable `validation`
        blocks are forbidden: they can crash OpenTofu itself catastrophically,
        even though the language accepts them. Do not introduce them or convert
        preconditions into them.
    - Use `precondition` on an output where the check belongs to the published
        contract.
    - In a symbol library function, use `validation` on a `parameter`, including
        for a cross-parameter invariant. A function has no resource and no output,
        so the three mechanisms above do not exist there. Parameter validation is
        separate from the forbidden cross-variable validation on module inputs.
- A function has no postcondition. Assert a produced value by declaring the type
    on both the parameter and the return and passing the value through.
- Never weaken a type to satisfy tooling.
- `try()` and `can()` turn a failure into a value and hide which expression
    failed. Inside a `validation` or `precondition` condition they are allowed
    where they let the check evaluate and report its own message, e.g.
    `can(regex(...))` or a guarded index into an unvalidated reference. They are
    also the guard *IaC → Validation* allows on a failing intermediate: wrap
    only the failing expression, and name at the call site the check that
    reports it. Elsewhere use one only with express permission, and state the
    reason at the call site.

## Documentation

- Every variable and output has a `description`. One line is a plain string;
    anything longer is a heredoc.
- A variable's description mirrors its type field by field. Name every field of
    an object and the meaning of a map's key. Where the type comes from a shared
    typedef, the description points at it instead; restating the fields per
    module is what produces drift.
- Document what the type cannot express: units, sentinels, what `null` disables,
    the schema an opaque string must satisfy.

```hcl
variable "permitted_principals" {
  type = map(object({
    principals = map(list(string))
    actions    = optional(list(string), [])
    read       = optional(bool, true)
    network = optional(object({
      endpoint_ids = list(string)
      cidrs        = optional(list(string))
    }))
  }))
  default     = null
  description = <<EOT
    A map of principals permitted to access the repository.

    Set to `null` to disable the resource policy.

    - The map key is an identifier.
    - `principals` maps a principal type to its values.
    - `actions` is a list of actions the `principals` may perform.
    - `read` is an `actions` alias for common read actions.
    - `network` restricts the statement to requests reaching the registry by a
      given path. Omit it to accept any origin.
        - `endpoint_ids` admits requests arriving through these VPC endpoints.
        - `cidrs` admits these ranges as well, in CIDR notation.

    If both `read` and `actions` are set, the values are merged.
  EOT
}
```

- Do **not** document a value's properties if they are already explicit - "read
    is a bool" or "(default: true)" only create drift potential without
    increasing clarity.

## Toggles and iteration

- A new toggle uses `lifecycle { enabled }`, never `count`. It does not combine
    with `for_each`; toggle an iterated resource by filtering its collection.
- Converting an existing `count` toggle changes the resource's address (`x[0]`
    becomes `x`) and needs a `moved` block. Do it only when that is the task.
- Referencing a disabled resource is an error. A context field whose component
    can be disabled is conditional:
    `kms = var.use_kms ? local.kms_context : null`.
- `for_each` keys must be known at plan time. Prefer caller-defined keys;
    composite keys from parent relationships, such as `<parent>.<child>`, are
    natural. A resource attribute known at plan time may form a key where it
    expresses a real dependency. Stability follows *IaC → Identity*.
- A `dynamic` block with a conditional collection is the mechanism for an
    optional nested block.

## Naming

- Do not name a variable, local, output, key or iterator after a type or a
    language keyword - `string`, `number`, `bool`, `list`, `set`, `map`,
    `object`, `any`, `count`, `each`, `self`, `path`, `module`. They read as
    language constructs and some shadow one. Name the thing instead:
    `tag_filter`, `allowed_cidrs`, `subnet_ids`. A field that mirrors a provider
    argument assigned straight across is the exception; say so at the
    declaration.
- `path.module` is a filesystem path shared by every call of a module. Never
    derive a module's identity from it.

## Comprehensions

- A single-level `for` uses `v`, or `k, v` over a map. Where an index is needed,
    it is `i`.
- A simple two-level `for` may use short names: `sk, sv` for the outer pair and
    `v` for the inner value.
- Anything more complex names what it iterates.
- Short names are only for cases that take no thought to tell apart. Where one
    iterator needs a descriptive name, every iterator in that expression takes
    one. Never mix the two.
- A `dynamic` block's iterator defaults to its label. Where that is long, set
    `iterator` to a short name.

```hcl
pull_arns = { for k, v in var.permitted_principals : k => v.iam_policy_arns.pull }

statements = flatten([
  for sk, sv in var.statements : [
    for v in sv.principals : { sid = sk, principal = v }
  ]
])

dynamic "image_tag_mutability_exclusion_filter" {
  for_each = var.mutability_exclusions
  iterator = v
  content {
    filter      = v.value
    filter_type = "WILDCARD"
  }
}
```

## Module interface

A module's outputs are defined once, as a context object.

```hcl
locals {
  output_context = {
    arn = local.repo_arn
    kms = module.kms.context
  }
}

output "context" { value = local.output_context }
output "arn"     { value = local.output_context.arn }

locals {
  computed_output_context = {
    arn = local.computed_repo_arn
    kms = module.kms.computed_context
  }
}

output "computed_context" { value = local.computed_output_context }
```

NOTE: The example omits descriptions and validations for brevity. Real
implementations **must** contain descriptions, and should perform validation if
it adds value.

- `local.output_context` is the single definition. `output "context"` publishes
    it whole and one flat output mirrors each top-level field. No output
    computes a value of its own.
- `local.computed_output_context` mirrors the subset whose values are known
    without creating the resources - constructed ARNs, URLs, names. It is
    published as `output "computed_context"` and gets no flat outputs.
- The computed context exists to break a dependency edge, such as naming an ARN
    in a policy before the resource exists. Compute and expose such values if
    they can be precomputed, otherwise they must be absent from the computed
    context.
- Embed a child module's context whole: `kms = module.kms.context`. Do **not**
    embed the whole module, as in `kms = module.kms` - this is a defect.
- Pass a whole context into a consuming module when the consumer uses that
    component as one of its parts, such as a service module taking the KMS
    context it encrypts with. Otherwise pass the values it needs.
- Contexts received as input pass through to child modules unchanged. Modify one
    only for a stated reason, such as adding a tag for every child.

## Dependencies

- `depends_on` follows *IaC → Dependencies and lifecycle*. Never
    `depends_on = [module.x]`: it waits on every object in the module and can
    defer dependent data sources to apply. In IaC terms, a module's context is
    its published output and `prevent_destroy` is destruction protection.

## Structure

- Input declarations live in `variables.tf`, or `variables.<concern>.tf` when
    large, each beside its validations and the cross-input preconditions that
    check it. Resources and their locals live in files named for their concern;
    checks of a resource's or output's own values stay with it. `outputs.tf`
    holds only the context locals, the outputs and output validations. Template
    seeds that colocate variables with resources are outdated; do not copy them.
- Keep each cohesive concern together. Split files when separation improves
    navigation or ownership, not merely to make files short. For example,
    `iam.execution.tf` and `iam.task.tf` could contain the execution and task
    roles of an AWS ECS module. Use well-known abbreviations where they exist,
    such as `dns.tgw.tf` instead of `transit-gateway-dns.tf`.
- Keep `outputs.tf` short: compute complex values as locals in the file defining
    their concern, then only reference these locals in the output context.
- Child modules configure no providers.
- A local module that exists to iterate a group of resources together is
    legitimate, but use it sparingly and say why.

## Secrets

- Where a secret value must be read, use an ephemeral resource and a write-only
    attribute - a plain data source on a SecureString writes the cleartext into
    state.
- Use `nonsensitive()` on values OpenTofu marks sensitive that are not secret
    where they are used, such as non-secret values read from an external KV
    store.
- `sensitive = true` redacts output. It is not storage security.

## Toolchain

- Module tests are `.tftest.hcl` files. They assert outputs and planned values,
    not resource layout. Use `mock_provider` so a test needs no account.
- Assert a rejection by the failing check's address in `expect_failures`. Never
    assert or parse error-message text.
- *General → Conformance cleanup* also covers descriptions that restate type
    properties or do not mirror the type's fields, and input declarations the
    change touches that sit outside `variables*.tf`.
- A suppression names the rule and the technical reason. Never widen an
    exclusion to make a change pass.
