# Embedded contract

Extends General and C++. Applies to code that runs on device. Wins over C++
where it is stricter. Host-side tooling in the same repository is not bound by
it.

Assumed target: single-binary multi-role firmware, microcontroller with an RTOS,
a continuous real-time output loop, no memory protection between components.
Report a mismatch rather than working around it.

______________________________________________________________________

## Default criticality

- On device, code is latency-sensitive by default. The real-time output loop, the
    network path, and everything they call are hot paths.
- Non-critical on device means startup, configuration, one-shot command handling,
    and diagnostics. Everything else is hot until shown otherwise.
- This inverts *App → Performance*: here, added overhead needs justification,
    not optimization.

______________________________________________________________________

## Memory

- No dynamic allocation after initialization. Allocate during startup;
    steady-state code allocates nothing.
- No allocation in the output loop, in a callback, or in an interrupt handler.
    This includes the implicit kind: growing a container, constructing a
    `std::string`, formatting into an owning string, capturing a lambda into a
    `std::function`.
- Containers have fixed capacity, declared at compile time. `static_assert` the
    bound where it is statically known; handle the full case explicitly where it
    is not.
- Every buffer is bounded, with a documented limit and a deliberate behavior on
    overflow - drop, overwrite, or reject - named in a comment.
- Report RAM and flash impact when a change adds a non-trivial static
    allocation, a new buffer, or a heavyweight dependency.
- Avoid facilities that pull in large runtime machinery: iostreams,
    `std::regex`, exception-based standard library paths, locale support.

______________________________________________________________________

## Data path

- Do not introduce additional queues, buffering, or data transformations unless
    required.
- Data crosses as few representations as possible between source and output. A
    transformation that exists to tidy an intermediate layer is a defect.
- Do not add indirection between the producer and the consumer of real-time
    data. A new abstraction there is a blocking assumption.

______________________________________________________________________

## Error handling

- No exceptions and no RTTI. Report unrecoverable conditions through the
    project's error path; recoverable ones through a return value.
- Prefer an explicit result type over an out-parameter plus boolean.
- A failure in the output loop degrades gracefully. It does not stall the loop
    and does not reset the device unless project policy says it should.

______________________________________________________________________

## Interrupt context

- An interrupt handler reads or writes hardware, sets a flag or posts to a
    preallocated slot, and returns. Interpretation happens outside.
- Never in an ISR: allocation, logging, blocking, locking a mutex, floating
    point where the platform disallows it, or any call whose implementation you
    have not read.
- Mark ISR-callable functions with the platform's required attribute and state it
    in the doc comment. Every caller inherits these restrictions.

______________________________________________________________________

## Concurrency and ownership

- Every piece of shared mutable state has one documented owner: which task or
    core may write it, and which may read it. State it at the declaration.
- State shared between an ISR and a task, or across cores, is accessed through an
    atomic or a platform primitive. `volatile` is not synchronization.
- Never hold a lock across a blocking call, an I/O operation, or an unbounded
    loop.
- Core pinning and task priority carry a reason in a comment. Changing an
    existing pinning or priority is a shared-code change: ask first.

______________________________________________________________________

## Timing

- Do not block or busy-wait in a task that holds a shared resource or feeds the
    output loop. Yield.
- Every loop on device has a bound derivable from the code.
- Respect the watchdog. Report any change that lengthens a critical section or
    adds work to a loop.
- Prefer integer and fixed-point arithmetic. Use single-precision `float` where
    floating point is needed; avoid `double`, which is emulated or markedly
    slower.

______________________________________________________________________

## Startup and identity

- Avoid non-trivial static initialization. A static object whose constructor
    touches hardware, allocates, or depends on another translation unit creates an
    initialization-order dependency. Initialize explicitly from the entry point.
- Node identity and platform/HAL selection are the exception to
    *C++ → Configuration visibility*: where the same code is compiled for
    different hardware roles, the role is selected by a build-level flag.
- Keep that selector narrow. Use the flag once, to pick a `constexpr`
    configuration object or a HAL type; all downstream code reads the `constexpr`
    value rather than testing the flag again.
- Adding a role-level build flag, or changing how a role is selected, is a
    blocking assumption. The project contract lists the roles that exist.

______________________________________________________________________

## Rebuilding

- Rebuild only the environments a change directly affects. An environment is
    affected when it actually compiles the changed file.
- A changed header affects only the environments that include it, directly or
    transitively. Determine that set with the tools; do not infer it from the file
    being shared code.
- Keeping shared code compatible across environments is a correctness
    requirement, not a build instruction. It does not mean rebuilding every
    environment on every change.
- Rebuild the full set only where the change touches something every environment
    compiles, or when asked.
- State which environments were rebuilt, and why that set.

______________________________________________________________________

## Persistent storage

- Flash and NVS have limited write endurance. Never write persistent storage from
    a loop, a per-frame path, or a per-message path.
- Persist on an explicit event - configuration change, shutdown, operator command
    - and coalesce repeated changes.
- A write interruptible by a reset must leave the stored state readable. State in
    a comment how that is guaranteed.

______________________________________________________________________

## Diagnostics on device

- Logging costs cycles, buffer space and bandwidth. Log events, not progress.
- Temporarily raise logging and metrics levels as needed, and add trace-level
    instrumentation where it helps debugging or optimization.
- Gate every statement added for debugging or optimization behind its respective
    compile-time constant, such that the default configuration compiles it out
    entirely. Many project macros already do this; custom statements need their own
    gate.
- Instrumentation that survives the session is documented and gated.
    Instrumentation that does not is removed before finishing, not left disabled.
- Never log inside an ISR. Never format a log message in the output loop.

______________________________________________________________________

## Verification

**Overrides *General → Workflow* step 5:** reasoning alone does not satisfy
verification on device.

- State what was verified on hardware and what was only reasoned about.
- Extend host-side tests for logic that does not touch hardware rather than
    testing only on device.
- Support timing and memory claims with a measurement, or label them estimates.
