# AWS Terraform contract

- The general Best Practices of the AWS Security Reference Architecture, Well
    Architected and similar principles must be followed.
- KMS CMK must be used as the default encryption type where suitable.
- `aws_iam_role_policy` and similar inline policy types are forbidden. Policies
    must be created as separate resources and attached.

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
