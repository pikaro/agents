# AWS Python contract

Domain extension to Python. Load for AWS client integrations and their tests.

- Use maintained SDK clients for service data and typed boundary models. Do not
    invoke the AWS CLI to parse its output when an SDK operation is available.
- Construct clients with explicit credentials/region/session dependencies.
    Importing a module must not contact AWS or resolve application
    configuration.
- Use moto for AWS service mocking. Never a hand-written AWS service stub or an
    automated test against a real account.
- Keep secret material out of logs, errors and representations. Reveal it only
    at the specific operation that needs it.
- Verify access-denied, missing-resource and malformed-response behavior where
    relevant. Project contracts define the actual account/access model.
- CLI handover for a human session is distinct from SDK data access; preserve
    the child's terminal and exit semantics through a typed wrapper.
