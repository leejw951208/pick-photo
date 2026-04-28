# Plan Execution

Implement only after plan review is `Approved` and the user has confirmed the approved plan for substantial work.

## Execution Rules

- Follow the approved scope.
- Keep changes small and reviewable.
- Preserve existing language, runtime, module, source layout, routing, services, domain logic, validation, errors, logging, tests, and documentation patterns.
- Keep product behavior aligned with `PRD.md`.
- Do not perform unrelated refactors.
- Do not add dependencies unless the approved plan explains why existing code cannot reasonably solve the problem.
- Do not introduce new languages, runtimes, frameworks, package managers, build tools, test runners, clouds, databases, or external services unless the user explicitly requested them and the plan records the impact.
- If implementation must materially diverge from the approved plan, stop and update the plan before continuing.

## Runtime And Resource Rules

- Preserve current language version, runtime version, module system, compiler/interpreter settings, package metadata, build output, and test setup.
- Treat public APIs, exported interfaces, CLI behavior, configuration behavior, database schema, request/response contracts, and user-facing behavior as compatibility-sensitive.
- Handle null, optional, error propagation, async/concurrency behavior, and resource cleanup explicitly.
- For filesystem access, command execution, network requests, timers, long-running processes, servers, workers, and CLIs, include error handling and cleanup.
- Prefer argument-array command execution over shell command string construction.
- Do not log secrets, tokens, credentials, or personal data.
