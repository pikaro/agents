# Python contract

Extends General and App with Python-specific requirements.

## Language version

- Floor is Python 3.14. `pyproject.toml` declares `requires-python = ">=3.14"`.
- No compatibility code below the floor: no `sys.version_info` branches, no
    backport imports, no `typing_extensions` for anything the standard library
    provides.
- Write current Python:
    - `list[str]`, `dict[str, int]` and `X | None` instead of `typing.List`,
        `typing.Dict`, `typing.Optional` and `typing.Union`
    - PEP 695 syntax: `def first[T](items: Sequence[T]) -> T`, `class Repo[T]:`,
        `type UserId = int`
    - `Self`, `override`, `Protocol`, `TypedDict`, `Literal`, `Final`, `Never`
    - no `from __future__ import annotations` (annotation evaluation is already
        deferred)
    - `pathlib` over `os.path`
    - `datetime.now(UTC)`, never a naive datetime
    - `StrEnum` / `IntEnum` over string and int constants
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
- A comprehension where it reads as one thought, and a loop where it does not.
    Never a nested comprehension.
- No dictionaries as ad-hoc records, no tuples as ad-hoc structs, no strings as
    ad-hoc enums.
- Nothing that costs a reader a second pass: no walrus inside a comprehension
    condition, no single-use lambda, no metaclass without a stated reason, no
    monkeypatching outside tests.

## Typing

- Fully typed: every parameter, return value, attribute and module-level
    constant.
- `pyright` in strict mode reports zero errors.
- `Any` is a defect except at a genuine boundary, such as deserialized external
    input or a third-party API with no stubs. Narrow it at that boundary and
    never propagate it inward.
- Suppression syntax is `# type: ignore[rule-code]` and `# noqa: RULE`, each with
    a comment stating why. Limits are in *General → Toolchain conformance*.
- Use generics where they remove a cast, and `@overload` where the return type
    depends on the argument types. A caller must never need `cast` to use your API.
- Where a dependency needs an interface, write a `Protocol`, not an abstract
    base class. *Composition and dependency injection* decides whether it needs
    one.
- `Sequence` / `Mapping` / `Iterable` in parameter positions, and concrete types
    in return positions.

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
- A leading underscore marks a private name. Everything else in a module is its
    public surface. Define `__all__` only in a module that re-exports names.
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
    operation. Cross the boundary at one explicit place, such as
    `asyncio.run` or `asyncio.to_thread`.
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
    speculative behavior (see *General → Never*).

### Assumed scale

- Design for the count the domain actually produces, and justify the count before
    designing for it. A function over S3 objects will see thousands, but a
    function over Terraform environments will not.
- Judge scale by the total wait, which is the number of items times the cost of
    each, not by the number of items alone. Independent subprocess or network
    calls across tens of items, where a person waits for the result, may run in
    a small thread pool with a stated bound. Anything those calls share must be
    thread-safe. A thread pool inside sync code does not make the module async.
    Do not add batching, concurrency or pagination for a wait nobody notices.
- Where the plausible count is unclear, ask rather than assuming the large case.

## Composition and dependency injection

- Pass collaborators explicitly where substitution, state or ownership requires
    it. Use constructor parameters for collaborators an object retains.
    `Protocol`s describe meaningful substitution or I/O boundaries. Ordinary
    public function calls need no injected object or protocol. A protocol needs
    a boundary the project contract names, or two production implementations.
    An implementation the owner has committed to counts as one of them. A test
    fake is not an implementation.
- No service locator, no global registry, no import-time singleton, no
    framework-magic injection unless an applicable framework contract specifies it.
- Free functions for stateless operations, including those taking explicit
    collaborators. Classes own state or collaborator lifetimes. Never use them
    as namespaces for functions.
- Inheritance is for a genuine substitutable subtype. Anything else is a
    collaborator to inject. Never inherit to share helper methods, and never
    inherit from a concrete class you also instantiate.

## Data and settings modeling

- A model represents a domain fact or a payload that crosses a boundary. Do not
    add a request, plan or result model for each layer a value passes through.
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
- A model that receives secrets sets `hide_input_in_errors=True`. Otherwise a
    `ValidationError` repeats the secret.

## Logging

- Operational logs are JSON. Structured fields go in `extra`, and the message is
    a short, stable event name.

    ```python
    logger.info("frame_dropped", extra={"node": node_id, "seq": seq, "reason": reason})
    ```

- Never an f-string, `%`, or `.format()` in a log call. Enforced by `ruff` (`G`).
- One module-level `logger = logging.getLogger(__name__)`, unless an applicable
    domain contract specifies a different logger. No `print` outside a CLI's
    own output.
- A CLI's messages to its user are output, not logs. They go through the CLI's
    own output code and are not JSON.
- Log at the boundary where the outcome is known. Do not log and re-raise at
    every level.

## Environment and dependencies

### Environment

- Work inside the project virtualenv. **Never install globally.**
- Use the existing project virtualenv through `uv run` or its explicit
    executable. Shell activation is not required. Prefer `uv run --no-sync`
    when verifying an already provisioned environment. Do not create a second
    environment or fall back to global packages. Report an actually missing
    environment/dependency.
- A virtualenv belongs to the machine that created it. Where the working tree
    is shared with another machine, such as a host mounted into a sandbox, do
    not run, sync or install into an environment that machine created. Create
    your own outside the working tree from the project's lockfile, with
    `UV_PROJECT_ENVIRONMENT` pointing at it, and treat it as the project
    virtualenv for the rules here. This is the only reason to create a second
    environment.
- With no virtualenv, use only what the active interpreter already provides.
    Adding a dependency in that state is a blocking assumption.
- `uv` manages the environment and the lockfile: `uv sync` to install, `uv run` to
    execute. `pyproject.toml` is the single source of project and tool
    configuration, with no `setup.py` and no `requirements.txt`.
- Project settings and exact installed versions remain authoritative.

### Adding libraries

Inside the project virtualenv, add a library where it is sound engineering. Do
not hand-roll what a good library does. Add type stubs where the library ships
none and stubs exist.

Preference order, applied as a guideline rather than a checklist:

1. **Modern and narrowly scoped:** debt-free, high-performance, fully typed, a
    clean expressive API, low mental load.
2. **Classic and established:** industry standard, boring engineering, some tech
    debt acceptable.
3. **Little-known but well-engineered:** clean, current, well-maintained.

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

## Project layout

- `src/` layout, one distribution package. Start a component as one module.
    Split it into a package of modules when it has several responsibilities.
    Callers import a name from the module that defines it.
- Do not add a re-exporting `__init__.py`, a private subpackage or a separate
    module of interface types by default. Add one only where it breaks an
    import cycle, keeps an optional heavy dependency out of the import path, or
    the package is published to consumers outside the repository. State the
    reason in the summary.
- Optional, pluggable parts live in separate modules or subpackages and are not
    imported by the component's `__init__.py`.
- A leading underscore marks a module or package as private to its component.
    Never import another component's private module.
- No circular imports. No import-time side effects: importing a module does not
    read configuration, open a connection, or start a thread.

## Docstrings

- Write a docstring where the name and signature leave something out. One line
    is the normal length. A function whose name and types say everything needs
    none.
- Document what the types do not express: units, ranges, side effects, raised
    exceptions, event-loop or thread expectations, and a surprising cost class.
- Do not restate the name or signature, justify the design or tell its history.
- Where a framework turns docstrings or field descriptions into user-facing
    help, those strings are user documentation, written for the user. The
    docstring brevity rules and conformance cleanup do not apply to them, and a
    structural change leaves them unchanged.

## Tooling

- `ruff` for lint and format, with broad rule selection including `S`
    (flake8-bandit), `G` (logging format), `C901`, `ANN`, `RUF`. Fix findings
    rather than narrowing the selection. The selection excludes the rules that
    require a docstring on every module, class or function (`D100` to `D107`).
- `pytest` with `pytest-cov`. Test behavior through the public surface, not
    through private modules.
- `bandit` in CI alongside ruff's `S` rules.
- Add or update tests where existing coverage does not establish the changed
    behavior. A behavior bug fix gets a regression test that fails before the
    fix. Prose-only changes use review and relevant existing tests. Do not write
    tests of agent-rule wording.
