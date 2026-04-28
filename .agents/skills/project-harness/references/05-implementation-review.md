# Implementation Review

Review the completed implementation before declaring it ready or tested.

## Review Checklist

- The implementation matches the approved plan and confirmed scope.
- Feature progress tracking is current when applicable, including status, progress, blockers, and feature-requirement-test mapping.
- Any plan divergence was recorded and approved through an updated plan.
- The change is limited to the requested scope.
- The implementation remains aligned with existing `PRD.md` when present.
- Existing language, runtime, module, app-shape, error handling, validation, security, and compatibility patterns are preserved.
- Public APIs, exported interfaces, request/response contracts, schemas, generated/client types, package metadata, docs, and tests are updated together when connected.
- Errors are handled explicitly and are not swallowed.
- Async and concurrency flows propagate failures clearly.
- Resource cleanup is handled for files, processes, network calls, timers, servers, workers, and CLIs.
- No unrelated refactor, dependency, framework, service, data store, or cloud resource was introduced.
- Security-sensitive changes were reviewed with `security.md`.
- Language/runtime-sensitive changes were reviewed with `language-runtime.md`.
- Human-facing review docs outside `.agents/` are in Korean.

## App Shape Checks

Apply only checks that match verified repository evidence:

- HTTP/API server: routing, request validation, response contracts, errors, auth boundary, and middleware/hook/plugin pattern.
- Full-stack or web app: server/client boundary, routing, rendering boundary, API contract, build output, and static assets.
- Client app: API calls, token handling, render state, build config, accessibility, and responsive behavior.
- CLI: argument parsing, stdin/stdout/stderr, exit code, config files, and shell integration.
- Library/package: public API, exports, interface artifacts, package metadata, and backward compatibility.
- Worker/background job: lifecycle, retry, idempotency, concurrency, cancellation, and cleanup.
- Data layer: schema, migrations, rollback, seed/fixture, transactions, and query policy.
- External integration: timeout, retry, rate limit, error mapping, secret handling, and adapter/service boundary.

## Output

Record findings, fixes applied, feature progress updates, and residual risks before testing.
