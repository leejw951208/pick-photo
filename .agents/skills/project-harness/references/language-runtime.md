# Language And Runtime

Use this reference when work touches language, runtime, compiler/interpreter, package metadata, build, module, dependency, public interface, CLI, API, config, or app-shape behavior.

## Verified Repository Evidence

- `apps/mobile/pubspec.yaml` defines Flutter app `pick_photo`, `publish_to: none`, Dart SDK `>=3.4.1 <4.0.0`, and dependencies including `file_picker`, `http`, and `http_parser`.
- `AGENTS.md` records Flutter 3.22.1 stable and Dart 3.4.1 as locally verified through `mise x flutter@3.22.1-stable -- flutter --version`.
- `apps/backend/package.json` defines a private npm project using NestJS `^11.0.1`, Prisma `^7.8.0`, Jest, TypeScript, ESLint, Prettier, and npm scripts.
- `AGENTS.md` records Node.js v22.20.0 and npm 10.9.3 as locally verified.
- `apps/ai/pyproject.toml` defines Python package `pick-photo-ai-server`, requires Python `>=3.11`, and uses FastAPI, OpenCV headless, Pillow, Pydantic, Uvicorn, pytest, and httpx.
- `AGENTS.md` records Python 3.12.12 at `/opt/homebrew/bin/python3.12` as locally verified.
- `docker-compose.yml` verifies local container wiring for PostgreSQL 16, the Python AI server, and the NestJS backend.

## Detection Rules

- Do not assume a language, runtime, framework, or app shape.
- Identify languages from source files, project metadata, compiler/interpreter config, lockfiles, README, and docs.
- Identify runtime from project metadata, toolchain files, container files, CI, README, and executable entrypoints.
- Identify app shape from source layout, route/controller files, CLI entrypoints, workers, libraries, tests, and docs.
- Identify package or dependency manager from lockfiles and project metadata.
- Record deployment, container, cloud, database, ORM, framework, formatter, linter, and test runner only when repository evidence exists.
- If a language, framework, or tool is verified but local code style, naming style, formatter, or linter evidence is missing, consult official documentation only as fallback style guidance and label it as fallback guidance, not repository fact.
- If evidence is missing or conflicting, write `Decision needed` instead of guessing.

## Preservation Rules

- Preserve existing language version, runtime version, module system, compiler/interpreter settings, package metadata, build output, and test setup.
- Do not introduce a new language, runtime, framework, package manager, build tool, test runner, formatter, deployment method, or cloud dependency unless the user explicitly asks and the approved plan records the impact.
- Follow existing source layout, naming style, dependency boundaries, error handling style, configuration patterns, and test structure.
- Treat public APIs, exported types/interfaces or equivalent artifacts, CLI behavior, configuration behavior, database schema, request/response contracts, and user-facing behavior as compatibility-sensitive.
- Review runtime, packaging, deployment, and test impact before changing language/runtime/compiler/build settings.
- Do not weaken type safety, validation, error handling, authentication, authorization, security boundaries, or test coverage for convenience.

## Resource Rules

- Handle null, optional, error propagation, async/concurrency behavior, and resource cleanup explicitly.
- Close lifecycle-owned HTTP clients and server/process resources.
- Preserve local storage boundaries for uploads and generated images.
- For security-sensitive resources, follow `security.md`.
- Explain any dependency addition and check whether existing dependencies can solve the problem first.
