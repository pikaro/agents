# AWS OpenTofu contract

Extends OpenTofu. Applies to AWS infrastructure.

- Follow the AWS Security Reference Architecture and the Well-Architected
    Framework. A deviation within the task's scope is a defect. Fix it, even by
    replacement, unless the resource is protected, and name the user action
    each replacement needs in the handoff. On a protected resource, mark the
    deviation with a `FIXME` at the resource and report it. Report a deviation
    outside the task's scope instead of fixing it.
- KMS CMK must be used as the default encryption type where suitable.
- `aws_iam_role_policy` and similar inline policy types are forbidden. Policies
    must be created as separate resources and attached.
- Take ARNs, endpoints, URLs and service principals from resource attributes or
    shared library symbols, never from a string template. This includes the
    constructed values in a computed context. Where no symbol provides the
    format, propose one for the shared library instead of writing the template.
- Test a policy by its effective grant. Select every statement concerning the
    principal, action or resource under test by those fields, and compare them
    without `Sid`. This fails on a wrong grant and on an extra one.

## Monitoring

Monitoring ships with the infrastructure it watches. Add monitoring to the
resources a change adds or modifies.

Each alert falls into one of three cases:

- Added and switched on, when all three hold:
    - The signal reliably shows a failure. Examples: a VPN tunnel reports that
        it is down, a NAT gateway fails to allocate ports.
    - The failure needs someone to act in every deployment of the module.
    - One threshold fits every deployment.
- Added but switched off, when the first two hold but the right threshold
    differs between deployments. The user switches it on and sets the
    threshold.
- Proposed: any other alert that might be useful. Describe it in chat with its
    signal, threshold and reason. Add it only once the user agrees.

Every alert can be switched off. Use the source that states the failure most
directly: a service metric, the service's state or health events, or an error
pattern in its logs, including log groups that AWS creates for the service.

- Grade each alert's severity by the impact of the condition it detects: lost
    service ranks above lost redundancy, which ranks above degradation or an
    approaching limit.
- Set how each metric alarm treats missing data for that alert. Comment the
    choice where the reason is not obvious.
- A log group takes at most five subscription filters.
- When an alert can be tested with little effort, say so in chat and suggest
    how to test it. An alert on a metric that already moves visibly needs no
    test.
