# Python contract

Extends General. Each section is the concrete mechanism for a general principle.

______________________________________________________________________

## Language version

Concrete form of *General → Language version*.

- Floor is Python 3.14. `pyproject.toml` declares `requires-python = ">=3.14"`.
- No compatibility code below the floor: no `sys.version_info` branches, no
    backport imports, no `typing_extensions` for anything the standard library
    provides.
- Write current Python:
    - `list[str]`, `dict[str, int]`, `X | None` - never `typing.List`,
        `typing.Dict`, `typing.Optional`, `typing.Union`
    - PEP 695 syntax: `def first[T](items: Sequence[T]) -> T`, `class Repo[T]:`,
        `type UserId = int`
    - `Self`, `override`, `Protocol`, `TypedDict`, `Literal`, `Final`, `Never`
    - no `from __future__ import annotations`; annotation evaluation is already
        deferred
    - `pathlib` over `os.path`; `datetime.now(UTC)`, never a naive datetime;
        `StrEnum` / `IntEnum` over string and int constants
    - `match` where it is clearer than an `if` chain, not as decoration

______________________________________________________________________

## Aesthetics

**Overrides *General → Core principles*.** Readability sits directly below
correctness and scope control, above consistency with existing patterns. Python
is expected to be beautiful; a working but ugly implementation is not finished.

The override does not license scope creep. Ugly code inside the task's code path
gets fixed; ugly code outside it is reported, not refactored.

- If the finished function is ugly, the model is wrong. Fix the model, not the
    formatting.
- If following a neighboring file's pattern would produce ugly code, say so and
    propose the better shape instead of copying it.
- Expressive names. No abbreviations that are not domain terms.
- Early return over nesting. Maximum nesting depth of three inside a function.
- A comprehension where it reads as one thought; a loop where it does not. Never
    a nested comprehension.
- No dictionaries as ad-hoc records, no tuples as ad-hoc structs, no strings as
    ad-hoc enums.
- Nothing that costs a reader a second pass: no walrus inside a comprehension
    condition, no single-use lambda, no metaclass without a stated reason, no
    monkeypatching outside tests.

______________________________________________________________________

## Typing

Concrete form of *General → Type discipline*.

- Fully typed: every parameter, return value, attribute and module-level
    constant.
- `pyright` in strict mode reports zero errors.
- `Any` is a defect except at a genuine boundary - deserialized external input, a
    third-party API with no stubs. Narrow it at that boundary and never propagate
    it inward.
- Suppression syntax is `# type: ignore[rule-code]` and `# noqa: RULE`, each with
    a comment stating why. Limits are in *General → Toolchain conformance*.
- Use generics where they remove a cast, and `@overload` where the return type
    depends on the argument types. A caller must never need `cast` to use your API.
- `Protocol` over an abstract base class for a dependency's interface.
    `Sequence` / `Mapping` / `Iterable` in parameter positions; concrete types in
    return positions.

______________________________________________________________________

## API design

Concrete form of *General → Public surface over internals*.

- Prefer monadic and dyadic functions. Three required parameters is a smell; four
    is a missing data model - model the inputs and take one argument. Keyword-only
    options with defaults do not count toward this.
- Anchor the calling convention: `/` for positional-only, `*` for keyword-only.
    Every boolean, every optional tuning value, and anything unidentifiable at the
    call site is keyword-only.

    ```python
    def render(frame: Frame, /, *, gain: float = 1.0, dither: bool = False) -> Image: ...
    ```

- Never a mutable default, and never a mutable module-level default callers can
    reach.
- The public surface of a module is what `__all__` lists. Everything else is
    `_private`.
- Raise a domain exception derived from one project base exception. Never raise or
    catch bare `Exception`. Never swallow an exception without logging it.

______________________________________________________________________

## Async

- Async for HTTP APIs and for work that is inherently concurrent I/O: many
    independent network calls, queue consumers, anything awaiting remote
    operations.
- Sync where async buys no measurable throughput: CLIs, single-shot scripts,
    CPU-bound work, and code whose I/O is one call deep. Async complexity must be
    paid for in throughput.
- A module is async or sync, not both. Do not offer both forms of the same
    operation. Cross the boundary at one explicit place - `asyncio.run`,
    `asyncio.to_thread`.
- Never call blocking code from an async function without `to_thread`.

______________________________________________________________________

## Complexity

- McCabe limit of 8, enforced by `ruff` (`C901`, `lint.mccabe.max-complexity = 8`).
- The limit is a detector, not a target. A function at 8 usually wants splitting
    or a data model, not a refactor that games the metric.

______________________________________________________________________

## Performance

Concrete form of *General → Performance*.

- Hot paths are the exception in Python. Assume non-critical and prefer clarity
    until a measurement says otherwise.
- Do not import mechanisms from other languages. Stack-versus-heap, copy elision
    and allocation counting have no Python analogue.
- Where a path is measured as hot: one pass instead of intermediate lists
    (generators, `itertools`), attribute and global lookups hoisted out of loops,
    one library-level call instead of a Python loop around it, batched I/O and
    network round-trips, `__slots__` or a frozen model for objects created in bulk,
    `functools.cache` where the input space is bounded.
- Measure before and after, and state the numbers. An unmeasured optimization is
    speculative behavior; see *General → Never*.

### Assumed scale

- Design for the count the domain actually produces, and justify the count before
    designing for it. A function over S3 objects will see thousands; a function
    over Terraform environments will not.
- Do not add batching, concurrency, or pagination machinery for volumes the domain
    cannot reach.
- Where the plausible count is unclear, ask rather than assuming the large case.

______________________________________________________________________

## Composition and dependency injection

- Dependencies are constructor parameters, typed as `Protocol`s, stored as
    attributes, used by methods. This is the DI mechanism.
- No service locator, no global registry, no import-time singleton, no
    framework-magic injection outside FastAPI's `Depends`.
- Free functions for pure transformations; classes where there is state or an
    injected collaborator. Not classes as namespaces for functions.
- Inheritance is for a genuine substitutable subtype. Anything else is a
    collaborator - inject it. Never inherit to share helper methods; never inherit
    from a concrete class you also instantiate.
- Name the pattern in a comment per *General → Name the patterns*.

______________________________________________________________________

## Data and settings modeling

- Data to model → Pydantic v2 `BaseModel`, defaulting to
    `model_config = ConfigDict(frozen=True, extra="forbid")`. Relax deliberately,
    with a reason.
- Validate at the boundary, then trust the model inward. Do not re-validate
    modeled data, and do not pass raw `dict`s past the boundary.
- Settings → `pydantic-settings` `BaseSettings`. This is the concrete form of
    *General → Configuration visibility*: a typed settings class keeps the active
    configuration visible to pyright and the IDE, where scattered
    `os.environ.get(...)` does not.
- Never read `os.environ` outside a settings class. Never branch imports on an
    environment variable.
- `Field` for constraints and descriptions. Validators for cross-field
    invariants, not for defaults.

______________________________________________________________________

## Web APIs and Lambda

- HTTP APIs → FastAPI, async. Route handlers parse, delegate, return. Business
    logic lives in an injected service.
- Declare `response_model` explicitly. `HTTPException` is raised in the boundary
    layer only; a service raises a domain error and the boundary maps it.
- AWS Lambda → `aws-lambda-powertools`:
    - `Logger` with `@logger.inject_lambda_context`
    - `Tracer` with `@tracer.capture_lambda_handler`, and `@tracer.capture_method`
        on calls worth seeing in a trace
    - `Metrics` for anything an operator alarms on
    - powertools parser and event source models for event parsing, not dictionary
        indexing
    - powertools idempotency where the handler is not naturally idempotent
- Tracing instrumentation in Lambda code is required, not optional.

______________________________________________________________________

## Logging

Concrete form of *General → Logging and metrics*.

- JSON logging. Structured fields in `extra`; the message is a short, stable
    event name.

    ```python
    logger.info("frame_dropped", extra={"node": node_id, "seq": seq, "reason": reason})
    ```

- Never an f-string, `%`, or `.format()` in a log call. Enforced by `ruff` (`G`).
- One module-level `logger = logging.getLogger(__name__)`, or the powertools
    `Logger` in Lambda code. No `print` outside a CLI's own output.
- Log at the boundary where the outcome is known. Do not log and re-raise at
    every level.

______________________________________________________________________

## Environment and dependencies

### Environment

- Work inside the project virtualenv. **Never install globally.**
- In a directory whose project uses a virtualenv that is not currently active,
    assume user error: stop and ask for activation. Do not create a second
    environment, and do not proceed against the interpreter's global packages.
- With no virtualenv, use only what the active interpreter already provides.
    Adding a dependency in that state is a blocking assumption.
- `uv` manages the environment and the lockfile: `uv sync` to install, `uv run` to
    execute. `pyproject.toml` is the single source of project and tool
    configuration; no `setup.py`, no `requirements.txt`.

### Adding libraries

Inside the project virtualenv, add a library where it is sound engineering. Do
not hand-roll what a good library does. Add type stubs where the library ships
none and stubs exist.

Preference order, applied as a guideline rather than a checklist:

1. **Modern and narrowly scoped** - debt-free, high-performance, fully typed, a
    clean expressive API, low mental load.
2. **Classic and established** - industry standard, boring engineering, some tech
    debt acceptable. Pydantic and FastAPI sit here by mandate despite their
    breadth.
3. **Little-known but well-engineered** - clean, current, well-maintained.

- Below roughly 100 stars, ask before adding.
- Do not add a library that is unmaintained, untyped with no stubs available, or
    that pulls a large transitive tree for a small feature.
- Adding a dependency remains ask-first per *General → Ask first* where it enters
    the project's declared dependencies. A dev-only or test-only tool that follows
    the preference order above does not need a separate ask.

______________________________________________________________________

## Imports

Concrete form of *General → Dependency and surface hygiene*.

- Import exactly what the module uses. A name imported for re-export goes in
    `__all__`.
- Absolute imports within the project. No wildcard imports. No conditional or
    function-local import except to break a genuine cycle or defer a heavy
    optional dependency, with a comment saying which.
- Every third-party name used is a declared dependency. Never rely on a transitive
    one.
- Remove a dependency when its last use goes away.

______________________________________________________________________

## Project layout

Concrete form of *General → Component structure*.

- `src/` layout, one distribution package, subpackages as components.
- Per component: `component/__init__.py` is the facade, re-exporting the public
    core API via `__all__` and nothing optional. Implementation in
    `component/_internal/`. Interface types - `Protocol`s, Pydantic models, config,
    wire messages - in `component/interfaces.py`, importable without pulling in the
    core.
- Optional, pluggable parts live in their own subpackage and are not imported by
    the component's `__init__.py`.
- The underscore prefix is the private-directory mechanism. Never import another
    component's `_internal`.
- No circular imports. No import-time side effects: importing a module does not
    read configuration, open a connection, or start a thread.

______________________________________________________________________

## Docstrings

Concrete form of *General → Comments and documentation*.

- Docstrings on every public module, class and function. `_private` helpers get
    one where the intent is not obvious from the signature.
- Document what the types do not express: units, ranges, side effects, raised
    exceptions, event-loop or thread expectations, and a surprising cost class.
- Do not restate the signature in prose.

______________________________________________________________________

## Tooling

- `ruff` for lint and format, with broad rule selection including `S`
    (flake8-bandit), `G` (logging format), `C901`, `ANN`, `RUF`. Fix findings
    rather than narrowing the selection.
- `pyright` strict for type checking.
- `pytest` with `pytest-cov`. Test behavior through the public surface; do not
    test `_internal` directly.
- `moto` for AWS service mocking. Never a hand-written AWS stub, and never a test
    against a real account.
- `bandit` in CI alongside ruff's `S` rules.
- Add a test with every behavior change. A bug fix gets a regression test that
    fails before the fix.
