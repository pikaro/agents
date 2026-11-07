# AWS Lambda contract

Domain extension to Python and aws-python.md. Load only for Lambda handlers and
runtime behavior. Read aws-python.md as well.

Use aws-lambda-powertools:

- Logger with @logger.inject_lambda_context.
- Tracer with @tracer.capture_lambda_handler and capture_method on operations
  worth tracing. Tracing instrumentation is required.
- Metrics for outcomes operators alarm on.
- Powertools parser/event-source models instead of untyped event indexing.
- Powertools idempotency for handlers that are not naturally idempotent.

Keep application settings and AWS calls out of import-time shared-library code.
Test event parsing, domain outcomes and failures with isolated service fixtures.
Do not invoke deployed functions or real accounts from automated tests.
