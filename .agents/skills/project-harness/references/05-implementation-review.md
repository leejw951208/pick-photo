# Implementation Review

Review the completed implementation before declaring it ready or tested.

## Review Checklist

- The implementation matches the approved plan and confirmed scope.
- Feature progress tracking follows `08-feature-progress.md` when applicable.
- Any plan divergence was recorded and approved through an updated plan.
- The change is limited to the requested scope.
- PRD alignment and product-scope decisions follow `01-product-thinking.md`.
- Existing language, runtime, module, app-shape, error handling, validation, security, and compatibility patterns are preserved.
- Public APIs, exported interfaces, request/response contracts, schemas, generated/client types, package metadata, docs, and tests are updated together when connected.
- Independent app areas remain independent unless a contract change intentionally coordinates them.
- Errors are handled explicitly and are not swallowed.
- Async and concurrency flows propagate failures clearly.
- Resource cleanup is handled for files, processes, network calls, timers, servers, workers, HTTP clients, and CLIs.
- No unrelated refactor, dependency, framework, service, data store, or cloud resource was introduced.
- Security-sensitive changes were reviewed with `security.md`.
- Language/runtime-sensitive changes were reviewed with `language-runtime.md`.
- Human-facing review docs outside `.agents/` are in Korean.

## App Shape Checks

Apply only checks that match verified repository evidence:

- Flutter client: API calls, render state, lifecycle-owned resources, accessibility, responsive behavior, direct face selection, and selected-face-only generation.
- NestJS API server: routing, request validation, response contracts, stable errors, CORS boundary, Swagger/OpenAPI, storage adapter, AI adapter, and repository behavior.
- FastAPI AI service: request schema, storage-key validation, local/fake mode selection, generated image output, and HTTP error mapping.
- Data layer: schema, migrations, Prisma schema alignment, seed/fixture guidance, transaction assumptions, and repository fallback behavior.
- Docker local runtime: service dependencies, shared storage volume, ports, env vars, and health checks.
- External or future integration: timeout, retry, rate limit, error mapping, secret handling, and adapter/service boundary.

## Output

Record findings, fixes applied, feature progress updates required by `08-feature-progress.md`, residual risks, and validation readiness before testing.
