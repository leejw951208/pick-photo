# Plan Execution

Implement only after plan review is `Approved` and any required user confirmation is complete.

## Execution Rules

- Follow the approved scope.
- When feature progress tracking applies, follow the update points in `08-feature-progress.md`.
- Keep changes small and reviewable.
- Preserve existing language, runtime, module, source layout, routing, services, domain logic, validation, errors, logging, tests, and documentation patterns.
- Preserve the boundaries between `apps/mobile/`, `apps/backend/`, `apps/ai/`, and `database/` unless the approved plan updates a contract.
- Follow `01-product-thinking.md` for PRD alignment and product-scope decisions.
- Do not perform unrelated refactors.
- Do not add dependencies unless the approved plan explains why existing code cannot reasonably solve the problem.
- Do not introduce new languages, runtimes, frameworks, package managers, build tools, test runners, clouds, databases, or external services unless the user explicitly requested them and the plan records the impact.
- If implementation must materially diverge from the approved plan, stop and update the plan before continuing.
- Write human-facing change summaries and commit messages in Korean.
- Format commit messages as `<commit type>: <Korean message>` on `main` or `dev`; use `[<branch>]<commit type>: <Korean message>` on any other branch.

## Repository Execution Notes

- Use `docs/contracts/**` as the coordination point for cross-project API, AI service, data-model, and privacy behavior.
- Keep generated/cache artifacts untracked.
- For Flutter photo-flow work, preserve direct face selection, zoom/pan assistance, selection summary behavior, stale async guards, and selected-face-only generation.
- For backend work, preserve stable error categories, workflow status values, validation, Swagger/OpenAPI behavior, and fake-AI fallback when env vars are absent.
- For AI work, preserve storage-key boundaries and explicit HTTP errors for storage and validation failures.
- For database work, do not claim a repeatable non-empty migration workflow until one is selected.

## Runtime, Resource, And Security Rules

- Follow `language-runtime.md` for language, runtime, package, module, dependency, public interface, API, CLI, config, and app-shape impacts.
- Follow `security.md` for filesystem, command execution, network exposure, secrets, auth, tokens, sessions, cookies, personal data, uploads/downloads, webhooks, background jobs, and other security-sensitive behavior.
- Preserve existing validation, error propagation, async/concurrency behavior, logging, and resource cleanup unless the approved plan explicitly changes them.
