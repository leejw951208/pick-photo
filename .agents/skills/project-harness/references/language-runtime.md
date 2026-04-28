# Language And Runtime

Use this reference when work touches language, runtime, compiler/interpreter, package metadata, build, module, dependency, public interface, CLI, API, config, or app-shape behavior.

## Detection Rules

- Do not assume a language, runtime, framework, or app shape.
- Identify languages from source files, project metadata, compiler/interpreter config, lockfiles, README, and docs.
- Identify runtime from project metadata, toolchain files, container files, CI, README, and executable entrypoints.
- Identify app shape from source layout, route/controller files, CLI entrypoints, workers, libraries, tests, and docs.
- Identify package or dependency manager from lockfiles and project metadata.
- Record deployment, container, cloud, database, ORM, framework, formatter, linter, and test runner only when repository evidence exists.
- If evidence is missing or conflicting, write `Decision needed` instead of guessing.

## Preservation Rules

- Preserve existing language version, runtime version, module system, compiler/interpreter settings, package metadata, build output, and test setup.
- Do not introduce a new language, runtime, framework, package manager, build tool, test runner, formatter, deployment method, or cloud dependency unless the user explicitly asks.
- Follow existing source layout, naming style, dependency boundaries, error handling style, configuration patterns, and test structure.
- Treat public APIs, exported types/interfaces or equivalent artifacts, CLI behavior, configuration behavior, database schema, request/response contracts, and user-facing behavior as compatibility-sensitive.
- Review runtime, packaging, deployment, and test impact before changing language/runtime/compiler/build settings.
- Do not weaken type safety, validation, error handling, authentication, authorization, security boundaries, or test coverage for convenience.

## Resource Rules

- Handle null, optional, error propagation, async/concurrency behavior, and resource cleanup explicitly.
- For filesystem access, command execution, network requests, timers, long-running processes, servers, workers, and CLIs, include error handling and cleanup.
- Prefer argument-array command execution and review injection risk.
- Do not expose secrets, tokens, credentials, or personal data in logs.
- Explain any dependency addition and check whether existing dependencies can solve the problem first.
