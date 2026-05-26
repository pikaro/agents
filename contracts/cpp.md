# C++ Contract

## Build Configuration

- Do not add `#define` entries or `-D...` compiler flags to express ordinary
    project-owned build configuration. Prefer `constexpr` values so IDEs and
    code navigation see the active configuration.
- Keep preprocessor and build-flag selectors narrow. They are acceptable for
    true build differentiation that cannot reasonably be represented as
    `constexpr`, such as selecting platform/HAL code or node identity when the
    same code is compiled for different hardware roles.
- Real macro use is outside this restriction. Function-like macros, include
    guards, and required external SDK/library macros may still use the
    preprocessor when that is the appropriate mechanism.
- If a change appears to need a new project-owned build flag outside these
    cases, treat it as a blocking assumption and ask first.

## Code Style

- Use header-only, modern C++ - use the latest C++ standard supported by the
    project and make use of its features.
- Use IWYU principles to their full extent. This means including everything you
    use, and not including anything you don't use. Use IWYU pragmas to make
    usage easier for the user - such as declaring detail headers private and
    annotating facades as the preferred include, or using `keep` and `export` to
    manage transitive includes.
- If the repository contains a `.clangd` file, follow its configuration and
    ensure that clangd does not report any warnings or errors. Usually, this
    will mean producing clean code; however, in select cases, setting `NOLINT`
    may be appropriate.

## Code structure

- The project should be organized into logical components with clear interfaces.
- Title-case directory names indicate public code parts, and lowe-case
    directories indicate private code parts.
- The core logic lives in `Component/detail/` headers. One header should be the
    public interface, e.g. `Logging/detail/Logger.hpp`. Additional `detail/`
    headers provide supporting code that the `Logger` depends on directly.
- Modular components should live in separate directory trees. For example,
    `Logging/` may have a `ConsoleOutput` that can be plugged into the `Logger`.
    `Logging/Outputs/ConsoleOutput.hpp` should contain the ConsoleOutput
    implementation.
- Interfaces and interface types such as configuration structs should be located
    in `Interfaces/` directories. For example, `Logging/Interfaces/Config.hpp`
    may contain a `Config` struct that defines the configuration for the
    `Logger`.
- Namespaces should follow this convention. `Logging` is the main public
    namespace for the logging component. `Logging::Outputs` is the namespace for
    output implementations. Public interfaces such as `Config` should be in
    `Logging`. The `Logger` class should be in `Logging::detail`.
- A `Facade.hpp` header such as `Logging/Facade.hpp` should be provided that
    includes the public interface and re-exports it in the `Logging` namespace.
    The Facade header draws in the entire public core API, but not optional
    components such as `ConsoleOutput`. Similarly, `Interfaces` may contain
    items which are usable independently of the core API - for example, if a log
    message is transmissible over the wire, the message struct may be in
    `Logging/Interfaces/Message.hpp` and usable without including the `Logger`
    itself.
