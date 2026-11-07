# FastAPI contract

Domain extension to Python. Load for HTTP APIs using FastAPI, not ordinary CLIs.

- HTTP APIs use FastAPI and async handlers. Handlers parse, delegate and return;
  business logic lives in an injected service.
- Declare response_model explicitly. Services raise domain errors; only the HTTP
  boundary maps them to HTTPException/status codes.
- FastAPI Depends is the explicit exception to constructor-only injection.
  Keep framework-specific injection at the API boundary.
- Do not perform blocking I/O in an async handler without an explicit bridge.
- Test request validation, responses and error mapping through the public API.
  Keep external services isolated using the applicable service-testing mechanism.
- Apply Python typing/data-model rules and General verification cadence.
