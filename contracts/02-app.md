# App contract

Kind contract for application code. Extends General; mutually exclusive with
IaC. Language contracts give the concrete mechanisms.

## Performance

Use predictable low-overhead mechanisms on hot/latency-critical paths. Elsewhere
prefer clarity. Apply language/domain-appropriate mechanisms. Without a domain
rule or measurement, assume a path is non-critical.

## Component structure

Keep components cohesive with explicit public entry points. Separate interfaces
and implementation where actual dependency, ownership or optional-loading
constraints warrant it. Keep interface/configuration/data types importable
without optional subsystems. Dependencies are acyclic; optional parts live
separately. Language rules map these boundaries to modules/packages.

## Logging and metrics

Instrument meaningful failures, critical paths and outcomes that need
operational diagnosis. Do not log trivial code or add telemetry for speculative
needs. Use stable event names plus structured fields, never interpolated data.
Never log secrets, credentials, tokens or personal data.

## Name the patterns

Name a recognized pattern only when it helps explain non-obvious control flow or
ownership at the relevant seam. Do not add a ceremonial pattern label to obvious
code. A short explanation of the mechanism is sufficient.
