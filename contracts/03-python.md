# Python contract

Extends General and App with Python-specific requirements.

## Language version

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

## Aesthetics

**Overrides *General → Core principles*.** Readability sits directly below
correctness and scope control, above consistency with existing patterns. Improve
readability where a concrete issue makes behavior harder to understand.

Keep improvements within the active package. Once its acceptance checks pass,
aesthetic preference alone does not justify another model or API redesign.

- Name the concrete issue: hidden state, misleading names, repeated branching or
    a confusing interface. Use the formatter for mechanical style.
- Expressive names. No abbreviations that are not domain terms.
- Early return over nesting. Maximum nesting depth of three inside a function.
- A comprehension where it reads as one thought; a loop where it does not. Never
    a nested comprehension.
- No dictionaries as ad-hoc records, no tuples as ad-hoc structs, no strings as
    ad-hoc enums.
- Nothing that costs a reader a second pass: no walrus inside a comprehension
    condition, no single-use lambda, no metaclass without a stated reason, no
    monkeypatching outside tests.

## Typing

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

## API design

- Group parameters in a model when they form a coherent domain concept or share
    invariants. Argument count alone does not justify a model.
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

## Complexity

- Use `ruff`'s `C901` with `lint.mccabe.max-complexity = 8` as a review signal.
- Simplify the decisions or extract cohesive behavior where that improves
    comprehension across the function and its callers. Do not introduce helpers
    or models merely to lower the score. Where the cohesive routine is clearer,
    use a narrow suppression with the reason per *General → Toolchain
    conformance*.

## Performance

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

## Composition and dependency injection

- Pass collaborators explicitly where substitution, state or ownership requires
    it. Use constructor parameters for collaborators an object retains.
    `Protocol`s describe meaningful substitution or I/O boundaries; ordinary
    public function calls need no injected object or protocol.
- No service locator, no global registry, no import-time singleton, no
    framework-magic injection unless an applicable framework contract specifies it.
- Free functions for stateless operations, including those taking explicit
    collaborators. Classes own state or collaborator lifetimes; never use them
    as namespaces for functions.
- Inheritance is for a genuine substitutable subtype. Anything else is a
    collaborator - inject it. Never inherit to share helper methods; never inherit
    from a concrete class you also instantiate.

## Data and settings modeling

- Data models, including internal ones, use Pydantic v2 `BaseModel`, defaulting to
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

## Logging

- JSON logging. Structured fields in `extra`; the message is a short, stable
    event name.

    ```python
    logger.info("frame_dropped", extra={"node": node_id, "seq": seq, "reason": reason})
    ```

- Never an f-string, `%`, or `.format()` in a log call. Enforced by `ruff` (`G`).
- One module-level `logger = logging.getLogger(__name__)`; an applicable domain
    contract may specify a different logger. No `print` outside a CLI's own output.
- Log at the boundary where the outcome is known. Do not log and re-raise at
    every level.

## Environment and dependencies

### Environment

- Work inside the project virtualenv. **Never install globally.**
- Use the existing project virtualenv through `uv run` or its explicit executable;
    shell activation is not required. Prefer `uv run --no-sync` when verifying an
    already provisioned environment. Do not create a second environment or fall
    back to global packages. Report an actually missing environment/dependency.
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
    debt acceptable.
3. **Little-known but well-engineered** - clean, current, well-maintained.

- Below roughly 100 stars, ask before adding.
- Do not add a library that is unmaintained, untyped with no stubs available, or
    that pulls a large transitive tree for a small feature.
- Adding a dependency remains ask-first per *General → Ask first* where it enters
    the project's declared dependencies. A dev-only or test-only tool that follows
    the preference order above does not need a separate ask.

## Imports

- Import exactly what the module uses. A name imported for re-export goes in
    `__all__`.
- Absolute imports within the project. No wildcard imports. No conditional or
    function-local import except to break a genuine cycle or defer a heavy
    optional dependency, with a comment saying which.
- Every third-party name used is a declared dependency. Never rely on a transitive
    one.
- Remove a dependency when its last use goes away.

## Project layout

- `src/` layout, one distribution package. Start a component as a cohesive module;
    use a subpackage when its responsibilities need separate modules.
- Where a package needs a facade, `__init__.py` re-exports its public API via
    `__all__`. Use `_internal/` when private implementation needs separate
    modules. Put boundary types in `interfaces.py` when consumers need them
    without importing the implementation. These are conditional boundaries,
    not a required scaffold for every component.
- Optional, pluggable parts live in separate modules or subpackages and are not
    imported by the component's `__init__.py`.
- The underscore prefix is the private-directory mechanism. Never import another
    component's `_internal`.
- No circular imports. No import-time side effects: importing a module does not
    read configuration, open a connection, or start a thread.

## Docstrings

- Docstrings on every public module, class and function. `_private` helpers get
    one where the intent is not obvious from the signature.
- Document what the types do not express: units, ranges, side effects, raised
    exceptions, event-loop or thread expectations, and a surprising cost class.
- Do not restate the signature in prose.

## Tooling

- `ruff` for lint and format, with broad rule selection including `S`
    (flake8-bandit), `G` (logging format), `C901`, `ANN`, `RUF`. Fix findings
    rather than narrowing the selection.
- `pyright` strict for type checking.
- `pytest` with `pytest-cov`. Test behavior through the public surface; do not
    test `_internal` directly.
- `bandit` in CI alongside ruff's `S` rules.
- Add or update tests where existing coverage does not establish the changed
    behavior. A behavior bug fix gets a regression test that fails before the
    fix. Prose-only changes use review and relevant existing tests; do not write
    tests of agent-rule wording.

## Optional domains

Read the matching file under ~/.config/agents/contracts once before relevant
work; do not load all domains for every Python task.

- HTTP API handlers/services: fastapi.md.
- AWS SDK integrations and their tests: aws-python.md.
- Lambda handlers/runtime behavior: aws-lambda.md (also requires aws-python.md).

Project settings and exact installed versions remain authoritative. Follow the
General formatting/verification cadence; do not duplicate it in each component.
