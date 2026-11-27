# Landing zone module contract

Extends Landing zone. Applies to every change to a shared landing zone module,
including one made while working in a deployment root. It does not apply to a
deployment root's own configuration.

- `module_context`, `data_context`, `alerting_context`, `backup_context` and
    `archive_context` pass through to every child module. A child that does not
    use one still declares it. That is intended, not an unused variable.
- `use_*` names a feature flag, and `create_*` names the choice between
    creating a resource and accepting an existing one. A persistent resource
    you add honors `var.prevent_destroy`.
- Before adding a new input, feature or group of resources, find the matching
    template in `landing-zone-common-templates/conditional` and an existing
    consumer, and follow the pattern they establish, such as module-owned log
    groups or the KMS create-or-external-key choice. Adapt the service-specific
    details, and ask where the pattern is unclear. Fix a template defect at its
    source rather than copying it.
- Do not add, change or remove OpenTofu or provider version constraints,
    including `required_providers` blocks. The templates own them. Where a
    change needs a newer version, report it for the template instead. This
    overrides *IaC → Versions*.

## Monitoring

`alerting_context` defines where alerts go. Its `channels` are keyed by
severity, from `symbols.C.alerting.levels`. Never create an SNS topic,
subscription or EventBridge target of your own for an alert.

- Where the module README has no `## Monitoring and Alerting` section, a change
    also covers the module's existing resources and adds that section. Keep the
    section current: one brief note per alert saying what it detects, its
    severity and what an admin should check first.
- `use_alerting`, on by default, switches all of a module's alerts. The
    `alerting` object holds each alert's `level` and, for metric alarms, its
    threshold. Setting `level = null` switches that alert off. This works the
    same way for metric, event and log alerts. An alert that is added but
    switched off defaults to `level = null`.
- With `use_alerting` on, a module that creates alerts fails on a `null`
    `alerting_context`. A `null` context is for bootstrapping and for modules
    without alerts.
- Metric alarms: `cloudwatch-metric-alarms`, with `levels` naming the severity.
- Event alerts: `event-bridge-filter` rules with the `alerting` block, targeting
    `alerting_context.sns_topic_arn_event_bridge` with
    `sns_submission_role_arn`. `event-bridge-alerting` is the reference.
- Log alerts: the `alerting` key of a `local.log_groups` entry from the
    `log_group` template, which sends to `local.log_alert_arn` and names the
    filter `<severity> // <group> // <title>[ // <description>]`. `group` is a
    key of the group mappings in `lambda-log-alert`. Title and description are
    fixed text without `:` or `*`, which AWS rejects in filter names.
- Central alerting over OAM (`use_oam_alerting`, tagging with
    `alerting_context.oam_alerting_tags`, rules in `cloudwatch-oam-alerting`)
    suits only clear-cut failures that need no configuration and benefit from
    one central rule, such as a tagged Lambda failing. A new central alert
    changes `cloudwatch-oam-alerting`, so it is ask-first. If a resource
    carries `alerting_context.oam_alerting_tags`, the central OAM rule is
    responsible for alerting on it. Do not add a local alert for the same
    failure. If the resource does not carry the tags, add the local alert.
