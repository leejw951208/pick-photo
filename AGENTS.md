# Project Harness

## Repository Facts

- Repository root: `/Users/leejinwoo/mine/pick-photo`.
- Git repository: current branch `main`; `origin` is `https://github.com/leejw951208/pick-photo.git`; latest observed commit is `3139be4 앱: 실제 사진 업로드 연결`.
- Repository state at original harness creation: no repository-local source files, product docs, project metadata, lockfiles, toolchain config, env examples, Docker files, CI workflows, or VCS metadata were present.
- Product reference: `PRD.md` is the Korean product requirements baseline. It describes what the service is, who it serves, product requirements, acceptance criteria, assumptions, and open product questions. Do not add technical implementation details to `PRD.md`.
- Canonical local harness path: `.agents/skills/project-harness/SKILL.md`.
- System design document: `docs/superpowers/specs/2026-04-28-pick-photo-system-design.md`.
- Implementation plan documents: `docs/superpowers/plans/2026-04-28-pick-photo-master.md`, `docs/superpowers/plans/2026-04-28-pick-photo-flutter-app.md`, `docs/superpowers/plans/2026-04-28-pick-photo-nestjs-server.md`, `docs/superpowers/plans/2026-04-28-pick-photo-python-ai-server.md`, and `docs/superpowers/plans/2026-04-28-pick-photo-database.md`.
- Contract documents: `docs/contracts/api.md`, `docs/contracts/ai-service.md`, `docs/contracts/data-model.md`, and `docs/contracts/privacy.md`.
- App shape: independent project folders are `flutter_app/`, `nestjs_server/`, `python_ai_server/`, and `database/`; cross-project behavior is coordinated through `docs/contracts/` rather than shared application code.
- Flutter app: `flutter_app/` is a Flutter app named `pick_photo`; source entrypoint is `flutter_app/lib/main.dart`; photo-flow feature files live in `flutter_app/lib/features/photo_flow/`; the app uses a file picker and `NestPhotoFlowApi` to upload selected photos to `http://localhost:3000` by default, configurable with `PICK_PHOTO_API_BASE_URL`.
- NestJS server: `nestjs_server/` is a private npm project using NestJS; source entrypoint is `nestjs_server/src/main.ts`; photo API files live in `nestjs_server/src/photos/`; AI adapter lives in `nestjs_server/src/ai/`; local CORS is enabled; Swagger UI is served at `/docs` and OpenAPI JSON at `/docs-json`.
- Python AI server: `python_ai_server/` is a Python package named `pick-photo-ai-server`; FastAPI entrypoint is `python_ai_server/app/main.py`; deterministic fake AI behavior lives in `python_ai_server/app/fake_ai.py`.
- Database assets: `database/migrations/001_initial_schema.sql` defines the initial PostgreSQL schema; `database/seeds/README.md` reserves the seed workflow. No migration runner or local PostgreSQL server command is verified yet.
- Languages and runtimes:
  - Flutter 3.22.1 stable and Dart 3.4.1 are verified through `mise x flutter@3.22.1-stable -- flutter --version`; `flutter_app/pubspec.yaml` requires Dart SDK `>=3.4.1 <4.0.0`.
  - Node.js v22.20.0 and npm 10.9.3 are verified locally; `nestjs_server/package.json` uses NestJS `^11.0.1`, Jest, TypeScript, and npm scripts.
  - Python 3.12.12 is verified at `/opt/homebrew/bin/python3.12`; `python_ai_server/pyproject.toml` requires Python `>=3.11`.
- Verified validation commands:
  - `cd python_ai_server && .venv/bin/python -m pytest -q`
  - `cd nestjs_server && npm test`
  - `cd nestjs_server && npm run test:e2e`
  - `cd nestjs_server && npm run build`
  - `cd flutter_app && mise x flutter@3.22.1-stable -- flutter test`
  - `cd flutter_app && mise x flutter@3.22.1-stable -- dart format lib test`

## Product Reference

- Read `PRD.md` when it exists before product or engineering work.
- Treat `PRD.md` as the baseline for product intent, users, requirements, scope, and open product decisions.
- Keep `PRD.md` product-only. Do not add runtime choices, architecture, API contracts, database schema, package metadata, commands, deployment notes, or other technical implementation details.
- Do not treat unresolved PRD decisions as verified repository facts.
- Do not create or modify `PRD.md` unless the user explicitly asks for a separate PRD task.
- When implementation creates or changes product behavior, check whether `PRD.md` needs a product-level Korean update. Put technical facts, commands, architecture, API behavior, data models, configuration, and security boundaries in `AGENTS.md`, `docs/contracts/`, or implementation plans instead.

## Project Decisions To Define

- Decision needed: CI policy, code ownership boundaries, branch protection, merge policy, and release workflow.
- Decision needed: infrastructure folder shape, deployment target, environment variable policy, secrets management, observability, and operations commands.
- Decision needed: authentication policy, real upload storage, real job orchestration, production data retention policy, and production error model.
- Decision needed: Python AI model stack, production face detection/selection pipeline, production ID-photo generation pipeline, model artifact storage, and inference hardware expectations.
- Decision needed: PostgreSQL migration runner, ORM or query layer, transaction policy, seed/fixture workflow, and local PostgreSQL validation command.
- Decision needed: local development commands beyond the verified validation commands, lint coverage policy, Docker, deployment, observability, and operations commands.
- Decision needed: privacy, consent, personal data handling, image retention, deletion, logging redaction, and compliance requirements for uploaded photos and generated ID photos.

## Always-On Rules

- Stay inside the repository root. Do not read, write, modify, summarize, merge, or clean up files outside this repository.
- Read `AGENTS.md` before all work. Read `PRD.md` when it exists.
- Write `AGENTS.md`, `.agents/skills/project-harness/SKILL.md`, and `.agents/skills/project-harness/references/*.md` in English.
- Write human-facing documents outside `.agents/` in Korean, including PRDs, product docs, feature docs, implementation plans, review docs, change summaries, and commit messages.
- Format commit messages as `<commit type>: <Korean message>` on `main` or `dev`; use `[<branch>]<commit type>: <Korean message>` on any other branch.
- Follow verified repository-local language, runtime, package manager, module, source layout, app-shape, error handling, configuration, and test patterns once they exist.
- Do not assume a framework, ORM, test runner, build tool, formatter, deployment target, cloud, database, external service, or command unless verified inside the repository or explicitly requested for a new implementation plan.
- Keep the independent project areas independent unless a future approved plan defines a shared contract: Flutter client, NestJS application server, Python AI service, and database assets.
- Keep changes small and reviewable. Do not perform unrelated refactors.
- For substantial work, use `.agents/skills/project-harness/SKILL.md` before implementation.
- Do not implement substantial changes before product thinking, implementation planning, and plan review are complete.
- Treat plan review as Codex internal self-review unless the user explicitly requires human approval.
- After an internal `Approved` plan review for substantial work, ask the user to confirm before implementation.
- Do not proceed from plan review to implementation unless the plan review result is `Approved`.
- If implementation must materially diverge from the approved plan, stop and get user confirmation before continuing.
- Keep implementation plans aligned with existing `PRD.md`; if the plan conflicts with `PRD.md`, update the plan or record the decision before implementing.
- Do not invent product requirements that are absent from `PRD.md`, repository evidence, or explicit user direction.
- Preserve authentication, authorization, validation, security boundaries, type safety, runtime safety, error handling, and tests.
- Treat uploaded photos, detected faces, generated ID photos, embeddings, metadata, logs, and model outputs as personal or sensitive data unless a future policy states otherwise.
- Use only verified repository commands for testing or validation. If a relevant project lacks a verified command, report that gap explicitly.
- Do not treat commands listed in `Project decisions to define` as verified while they are unresolved, stale, conflicting, missing, `Decision needed`, or `To be defined`.
- When changing product behavior, user-facing behavior, requirements, or scope, check whether `PRD.md` needs a product-only update. Keep technical updates out of `PRD.md`.
- Generated/cache artifacts such as Python virtualenvs, `__pycache__`, Node `node_modules`, NestJS `dist`, Flutter `.dart_tool`, Flutter `build`, and local platform files must remain untracked.
- Flutter Android build is not yet verified. Flutter scaffold generation emitted a Java 21 / Gradle 7.6.3 compatibility warning; treat Android build compatibility as a later task.

## Skill Entrypoint

Use `.agents/skills/project-harness/SKILL.md` for substantial product or engineering work. Use root `PRD.md` as product context when it exists.
