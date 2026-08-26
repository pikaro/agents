# C++ contract

Extends General. Applies to all C++, on desktop and on device. Embedded is
stricter where it overlaps and wins there.

Each section is the concrete mechanism for a general principle.

______________________________________________________________________

## Language version and style

- The floor is the standard the build configuration enables. Read the active
    `-std=` rather than assuming, and treat it as both floor and target: no code
    targeting an earlier standard, no feature from a later one.
- Use that standard's features: concepts over SFINAE, `std::span` and
    `std::string_view` over pointer-plus-length, `if constexpr` over tag dispatch,
    `std::optional` and `std::variant` over sentinel values and unions,
    algorithms and ranges over hand-written loops, designated initializers.
- Write no fallback for a feature the active standard provides.
- Header-only. Core logic lives in headers under `Component/detail/`.
- Prefer standard library facilities over hand-rolled equivalents, except where
    Embedded forbids the specific facility.
- Rule of zero: a type that owns nothing declares no special member functions.
    Declaring one means declaring or deleting all, with a reason.
- No raw owning pointers and no manual `new`/`delete`. Ownership is a value, a
    smart pointer, or a fixed-capacity container.
- `[[nodiscard]]` on any function where ignoring the result is a bug.
- `explicit` on any single-argument constructor that is not a deliberate
    conversion.
- `constexpr` or `consteval` anything evaluable at compile time.

______________________________________________________________________

## Configuration visibility - `constexpr`, not `#define`

Concrete form of *General → Configuration visibility*.

- Express project-owned configuration as `constexpr` values, or `constexpr`
    members of a config struct. Not as `#define` entries, not as `-D...` flags.
- clangd resolves `constexpr`: hover shows the active value, go-to-definition
    works, and the value is type-checked. A `#define` or `-D` flag is invisible to
    navigation, and code behind an inactive branch is never analyzed.
- Select between project-owned configuration values with `if constexpr`, or with
    a plain `if` on a `constexpr` value, so both branches stay compiled and
    analyzed. Not with `#if` / `#ifdef`.

Preprocessor use outside this restriction:

- Build differentiation that cannot be a `constexpr` value: platform and HAL
    selection, and node identity when the same code is compiled for different
    hardware roles. See *Embedded → Startup and identity*.
- Function-like macros where a macro is the appropriate mechanism.
- Include guards; prefer `#pragma once` where the project already uses it.
- Macros required by an external SDK or library.
- Compile-time gates for diagnostic instrumentation, per *Embedded → Diagnostics
    on device*.

A change that appears to need a new project-owned build flag outside these cases
is a blocking assumption.

______________________________________________________________________

## Templates

**Keep template bodies small.** clangd does not analyze uninstantiated template
bodies, so code inside a template loses diagnostics, completion and reliable
go-to-definition. The cost is per line inside the template, not per template: a
thin API overload, mixin or container pays almost nothing; a large class body
that became a template incidentally is unnavigable and unreviewable.

Do not make a class a template because one of its member functions must accept
several types. Template the function, not the class.

**Shape for accepting several types:** non-template class, short template member
functions. The template function converts its argument to one internal
representation and delegates to a non-template implementation. Target one to
three lines of template body.

```cpp
// Type erasure: the template overload converts any contiguous byte-like range
// to a span and delegates. All logic is in the non-template overload.
class Writer {
public:
    template <ByteRange R>
    bool write(const R& data) { return write(std::as_bytes(std::span{data})); }

    bool write(std::span<const std::byte> data);
};
```

Erase to a concrete internal type: `std::span<const std::byte>`,
`std::span<const T>`, `std::string_view`, a concrete value type, a `std::variant`
over a closed set, or a function-pointer-plus-context pair.

### Whole-type templates

A whole type is a template where the parameter parameterizes storage, layout or
compile-time composition. These are correct and expected:

- **CRTP mixins.** Compose capability onto a type with thin, focused mixins -
    `HasTask`, `HasLock`, `HasDirectory`. **Overrides *General → Coding
    conventions* on composition over inheritance:** for capability composition,
    prefer a CRTP mixin over an inheritance hierarchy or a runtime interface. Each
    mixin does one thing, and the derived class's declaration reads as the list of
    what the type can do.
- **Policy types**, where compile-time substitution is the purpose.
- **Containers and wrappers** whose element type or capacity determines storage:
    `RingBuffer<T, Capacity>`.

Keep each one thin. Where a mixin accumulates logic that does not depend on the
template parameter, move that logic into a non-template base or a free function
the mixin calls.

State the purpose in a one-line comment at the declaration. A whole-type template
outside these categories is a defect.

### Constraining parameters

The constraint rule depends on how the parameter is supplied:

- **Deduced from a caller's argument:** constrain with a concept. An
    unconstrained `template <typename T>` on a deduced API parameter is a defect.
- **Supplied explicitly and complete at instantiation** - policy types, container
    element types: constrain with a concept expressing what the code requires
    (`std::movable`, `std::trivially_copyable`, a project concept).
- **CRTP `Derived`:** an unconstrained `template <typename Derived>` is correct
    here, and required. The derived type is incomplete where the base is
    instantiated, so a concept inspecting its members is ill-formed or silently
    false. Instead: document the required interface in a comment on the mixin, and
    `static_assert` inside a member function body, where `Derived` is complete.

```cpp
// CRTP mixin: adds frame dispatch. Derived must provide `void onFrame(Frame)`.
// Derived is deliberately unconstrained - it is incomplete at this point; the
// requirement is asserted at first use, where it is complete.
template <typename Derived>
class HasFrameSink {
    void dispatch(Frame f) {
        static_assert(requires(Derived& d, Frame fr) { d.onFrame(fr); });
        static_cast<Derived*>(this)->onFrame(f);
    }
};
```

- Never SFINAE where a concept works.
- Do not template on a value that is ordinary configuration. Template on a value
    only where it must affect layout, capacity or unrolling.
- Do not add a template parameter for future flexibility; see *General → Never*.
- Do not add a template parameter to a mixin that does not need one. A mixin
    takes `Derived` and nothing else unless a second parameter earns its place.

______________________________________________________________________

## Types and interfaces

Concrete form of *General → Type discipline*.

- Encode invariants in types: a value with a unit gets a strong type, not a bare
    `float`; a closed set of states gets an `enum class`, not an `int`; a value
    that cannot be null is a reference or a value, not a pointer.
- Do not weaken a signature to make a call site compile: no `void*`, no
    `reinterpret_cast` between project types, no dropping `const`, no non-`const`
    reference parameter used only to avoid a copy.
- Four or more parameters means a missing type. Group them into a struct -
    typically `Component/Interfaces/Config.hpp` - and pass by `const&`.
- Two adjacent parameters of the same type are a call-site hazard. Use distinct
    strong types.

______________________________________________________________________

## Allocation and hot paths

Concrete form of *General → Performance*.

In hot or latency-sensitive paths, prefer:

- stack allocation over heap allocation
- value semantics; minimize copies of non-trivial types, and move instead
- `std::span` and `std::string_view` over owned containers where the callee does
    not store the argument
- reserving container capacity once, outside the loop
- concrete types over polymorphic ones where the set of types is closed
- avoiding virtual dispatch, `std::function`, `std::shared_ptr`, and
    pointer-chasing layouts

Do not apply these in non-critical paths at the cost of clarity.

______________________________________________________________________

## Includes - IWYU

Concrete form of *General → Dependency and surface hygiene*.

- Include everything you use; include nothing you do not use.
- Never rely on a transitive include. Using a symbol means including its header,
    or forward-declaring it.
- Forward-declare instead of including where only a declaration is needed and the
    header is expensive.
- Use IWYU pragmas to make correct usage easy for the caller: mark `detail/`
    headers private with the facade as their public alternative, annotate the
    facade as the component's preferred include, and use `keep` and `export` to
    manage transitive includes deliberately.

______________________________________________________________________

## Toolchain conformance - clangd

Concrete form of *General → Toolchain conformance*.

- Where the repository contains a `.clangd` file, follow its configuration and
    leave clangd reporting no warnings or errors on the code you write.
- Suppression syntax is `// NOLINT(specific-check)` or `// NOLINTNEXTLINE(...)`,
    naming the check, with a comment stating why. Limits are in *General →
    Toolchain conformance*.
- Keep `compile_commands.json` current for the environment being worked on.

### Analyzability

Treat clangd's ability to analyze the code as a significant design factor,
weighted alongside correctness and clarity - not as a veto.

- Where two designs are otherwise comparable, choose the one clangd can analyze.
    This is the reason for `constexpr` over `#define`, `if constexpr` over `#if`,
    and small template bodies.
- Where analyzability conflicts with a clean, well-engineered solution, the clean
    solution wins. A CRTP mixin, a policy type, or a necessary container template
    is correct even though its body is unanalyzable until instantiated.
- Reduce the unanalyzable surface rather than avoiding the construct: keep the
    template body short, move parameter-independent logic out of it, and
    `static_assert` the requirements the concepts cannot express.
- Do not sacrifice a correct design to satisfy the tooling. Do not leave a large
    body unanalyzable when a small one would do.

______________________________________________________________________

## Code structure

Concrete form of *General → Component structure*.

- Title-case directory names are public code; lower-case directories are private.
- Private means not included directly by a consumer. A consumer includes
    `Component/Facade.hpp`; nothing outside the component includes a `detail/`
    header.
- Core logic lives in `Component/detail/` headers. One of them declares the
    component's primary public type, e.g. `Logging/detail/Logger.hpp` - public in
    the sense that the facade re-exports it, private in the sense that it is
    reached through the facade. Additional `detail/` headers hold supporting code
    that type depends on directly.
- Modular components live in separate trees: a `ConsoleOutput` that plugs into
    the `Logger` is `Logging/Outputs/ConsoleOutput.hpp`.
- Interfaces and interface types such as configuration structs live in
    `Interfaces/`, e.g. `Logging/Interfaces/Config.hpp`. `Interfaces/` may hold
    items usable without the core: a wire-transmissible log message belongs in
    `Logging/Interfaces/Message.hpp` and must be usable without including
    `Logger`.
- Namespaces follow the layout: `Logging` is the public namespace,
    `Logging::Outputs` for output implementations, public interfaces such as
    `Config` in `Logging`, and the `Logger` class in `Logging::detail`.
- `Component/Facade.hpp`, e.g. `Logging/Facade.hpp`, includes the public
    interface and re-exports it in the `Logging` namespace. The facade draws in
    the entire public core API and nothing optional.

______________________________________________________________________

## Logging

Concrete form of *General → Logging and metrics*.

- Log a stable event name plus fields through the project's logging component.
    Do not concatenate or format values into the message text.
- Pass values as fields so the sink decides representation. A log call does not
    allocate or format in the caller.

______________________________________________________________________

## Comments and API documentation

- Doc comment on the declaration in the public header, in the project's existing
    Doxygen style.
- Document what the types do not express: preconditions, units, lifetime and
    ownership of reference parameters, thread context, blocking behavior. ISR
    context has its own requirement in *Embedded → Interrupt context*.
- Document the invariant a class maintains, at the class declaration.
- C++ patterns to name per *General → Name the patterns*, in addition to the
    general list: type erasure, CRTP, policy injection, scope guard / RAII
    wrapper, tag dispatch, pimpl.
