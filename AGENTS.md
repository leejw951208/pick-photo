# Project Harness

## Repository Facts

- Repository root: `pick-photo/`.
- Git repository: current branch `main`; `origin` is `https://github.com/leejw951208/pick-photo.git`.
- Repository state at original harness creation: no repository-local source files, product docs, project metadata, lockfiles, toolchain config, env examples, Docker files, CI workflows, or VCS metadata were present.
- Product reference: `pick-photo/PRD.md` is the Korean product requirements baseline. It describes what the service is, who it serves, product requirements, acceptance criteria, assumptions, and open product questions. Do not add technical implementation details to `pick-photo/PRD.md`.
- Canonical local harness path: `pick-photo/.agents/skills/project-harness/SKILL.md`.
- System design document: `pick-photo/docs/superpowers/specs/2026-04-28-pick-photo-system-design.md`.
- Face selection UX design document: `pick-photo/docs/superpowers/specs/2026-04-29-pick-photo-zoom-direct-face-selection-design.md`. It fixes the face review UX direction as original-photo direct face selection plus zoom/pan-assisted selection mode plus a bottom selection summary; lower face lists are not the primary selection control for this UX.
- Implementation plan documents: `pick-photo/docs/superpowers/plans/2026-04-28-pick-photo-master.md`, `pick-photo/docs/superpowers/plans/2026-04-28-pick-photo-flutter-app.md`, `pick-photo/docs/superpowers/plans/2026-04-28-pick-photo-nestjs-server.md`, `pick-photo/docs/superpowers/plans/2026-04-28-pick-photo-python-ai-server.md`, `pick-photo/docs/superpowers/plans/2026-04-28-pick-photo-database.md`, and `pick-photo/docs/superpowers/plans/2026-04-29-pick-photo-zoom-direct-face-selection.md`.
- Contract documents: `pick-photo/docs/contracts/api.md`, `pick-photo/docs/contracts/ai-service.md`, `pick-photo/docs/contracts/data-model.md`, and `pick-photo/docs/contracts/privacy.md`.
- App shape: independent project folders are `pick-photo/apps/mobile/`, `pick-photo/apps/backend/`, `pick-photo/apps/ai/`, and `pick-photo/database/`; cross-project behavior is coordinated through `pick-photo/docs/contracts/` rather than shared application code.
- Flutter app: `pick-photo/apps/mobile/` is a Flutter app named `pick_photo`; source entrypoint is `pick-photo/apps/mobile/lib/main.dart`; photo-flow feature files live in `pick-photo/apps/mobile/lib/features/photo_flow/`; the app uses a file picker and `NestPhotoFlowApi` to upload selected photos to `http://localhost:3000` by default, configurable with `PICK_PHOTO_API_BASE_URL`.
- Flutter photo-flow face state includes detected face `id`, `faceIndex`, `box`, and `confidence`; `PhotoFlowState` defensively copies source photo preview bytes. `NestPhotoFlowApi` parses backend `box` coordinates and sends `selected_faces` plus sorted `faceIds` when generating for multiple selected faces.
- Flutter face review UX uses `FaceSelectionCanvas` for original-photo direct face selection with zoom controls, visible selected/excluded face labels, stale image decode guards, stable preview bytes during selection rebuilds, and async upload/generation sequence guards in `PhotoFlowScreen`.
- NestJS server: `pick-photo/apps/backend/` is a private npm project using NestJS; source entrypoint is `pick-photo/apps/backend/src/main.ts`; photo API files live in `pick-photo/apps/backend/src/photos/`; AI adapter lives in `pick-photo/apps/backend/src/ai/`; local CORS is enabled; Swagger UI is served at `/docs` and OpenAPI JSON at `/docs-json`.
- Backend generation requests support `single_face`, `selected_faces`, and `all_faces`. `selected_faces` requires a non-empty `faceIds` array, rejects non-array or foreign face IDs with `selection_invalid`, and preserves backward compatibility for `single_face` and `all_faces`.
- Backend storage and adapter behavior: uploaded files are stored through `LocalPhotoStorage`, defaulting to `pick-photo/apps/backend/storage/` when run from `pick-photo/apps/backend`; `PHOTO_STORAGE_DIR` overrides that path; `AI_SERVICE_BASE_URL` enables the Python AI HTTP adapter and absence of that env var falls back to deterministic fake AI; `DATABASE_URL` enables the Prisma 7 PostgreSQL repository using `@prisma/adapter-pg` and absence of that env var falls back to the in-memory repository.
- Backend Prisma configuration: Prisma config lives at `pick-photo/apps/backend/prisma.config.ts`; Prisma schema lives at `pick-photo/apps/backend/prisma/schema.prisma`; `npm run prisma:generate` generates the untracked client into `pick-photo/apps/backend/src/generated/prisma/`; backend test, build, and start scripts run generation through npm pre-scripts.
- Python AI server: `pick-photo/apps/ai/` is a Python package named `pick-photo-ai-server`; FastAPI entrypoint is `pick-photo/apps/ai/app/main.py`; deterministic fake AI behavior lives in `pick-photo/apps/ai/app/fake_ai.py`.
- Database assets: `pick-photo/database/migrations/001_initial_schema.sql` defines the initial PostgreSQL schema; `pick-photo/database/seeds/README.md` reserves the seed workflow. Backend repository code can write workflow metadata to PostgreSQL when `DATABASE_URL` is configured. Docker Compose verifies local PostgreSQL startup with the initial schema, but no repeatable migration runner for non-empty databases is selected yet.
- Docker local runtime: `pick-photo/docker-compose.yml` runs PostgreSQL, the Python AI server, and the NestJS backend together. The Compose stack mounts `pick-photo/database/migrations/001_initial_schema.sql` into PostgreSQL init, shares a named storage volume between backend and AI at `/data/storage`, exposes backend `3000`, AI `8000`, and PostgreSQL `5432`, and leaves Flutter to run locally against `http://localhost:3000`.
- Languages and runtimes:
  - Flutter 3.22.1 stable and Dart 3.4.1 are verified through `mise x flutter@3.22.1-stable -- flutter --version`; `apps/mobile/pubspec.yaml` requires Dart SDK `>=3.4.1 <4.0.0`.
  - Node.js v22.20.0 and npm 10.9.3 are verified locally; `apps/backend/package.json` uses NestJS `^11.0.1`, Prisma `^7.8.0`, Jest, TypeScript, and npm scripts.
  - Python 3.12.12 is verified at `/opt/homebrew/bin/python3.12`; `apps/ai/pyproject.toml` requires Python `>=3.11`.
- Verified validation commands:
  - `cd apps/ai && .venv/bin/python -m pytest -q`
  - `cd apps/backend && npm run prisma:generate`
  - `cd apps/backend && npm test`
  - `cd apps/backend && npm run test:e2e`
  - `cd apps/backend && npm run build`
  - `cd apps/mobile && mise x flutter@3.22.1-stable -- flutter test`
  - `cd apps/mobile && mise x flutter@3.22.1-stable -- dart format lib test`
  - `docker compose config`
  - `docker compose build`
  - `docker compose up -d`
  - `docker compose ps`
  - `docker compose exec -T postgres psql -U pick_photo -d pick_photo -c "select count(*) as tables from information_schema.tables where table_schema = 'public';"`

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
- Decision needed: PostgreSQL migration runner for non-empty databases, production transaction policy, and seed/fixture workflow.
- Decision needed: local development commands beyond the verified validation commands, lint coverage policy, deployment, observability, and operations commands.
- Decision needed: privacy, consent, personal data handling, image retention, deletion, logging redaction, and compliance requirements for uploaded photos and generated ID photos.
- Decision needed: server-side source photo preview serving for non-local preview clients, face crop thumbnail source, confidence threshold for `확인 필요`, and retention or expiration behavior for source previews and face previews.

## Always-On Rules

- Stay inside the repository root. Do not read, write, modify, summarize, merge, or clean up files outside this repository.
- Read `AGENTS.md` before all work. Read `PRD.md` when it exists.
- Write `AGENTS.md`, `.agents/skills/project-harness/SKILL.md`, and `.agents/skills/project-harness/references/*.md` in English.
- Write human-facing documents outside `.agents/` in Korean, including PRDs, product docs, feature docs, implementation plans, feature progress tracking, review docs, change summaries, and commit messages.
- Format commit messages as `<commit type>: <Korean message>` on `main` or `dev`; use `[<branch>]<commit type>: <Korean message>` on any other branch.
- Follow verified repository-local language, runtime, package manager, module, source layout, app-shape, error handling, configuration, and test patterns once they exist.
- Do not assume a framework, ORM, test runner, build tool, formatter, deployment target, cloud, database, external service, or command unless verified inside the repository or explicitly requested for a new implementation plan.
- Keep the independent project areas independent unless a future approved plan defines a shared contract: Flutter client, NestJS application server, Python AI service, and database assets.
- Keep changes small and reviewable. Do not perform unrelated refactors.
- For substantial work, use `.agents/skills/project-harness/SKILL.md` before implementation.
- Do not implement substantial changes before product thinking, implementation planning, and plan review are complete.
- For substantial feature work, use `.agents/skills/project-harness/references/08-feature-progress.md` to keep feature status, progress percentage, blockers, and feature-requirement-test mapping current.
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
- When changing the face review UX, align with `docs/superpowers/specs/2026-04-29-pick-photo-zoom-direct-face-selection-design.md`: use original-photo direct selection as the primary interaction, support zoom/pan-assisted selection for dense or small faces, preserve clear selected/excluded/needs-review states, and keep the bottom area as a selection summary rather than the primary face list.
- Generated/cache artifacts such as Python virtualenvs, `__pycache__`, Node `node_modules`, NestJS `dist`, Prisma generated client files under `pick-photo/apps/backend/src/generated/`, Flutter `.dart_tool`, Flutter `build`, and local platform files under `pick-photo/` must remain untracked.
- Flutter Android build is not yet verified. Flutter scaffold generation emitted a Java 21 / Gradle 7.6.3 compatibility warning; treat Android build compatibility as a later task.

## Skill Entrypoint

Use `pick-photo/.agents/skills/project-harness/SKILL.md` for substantial product or engineering work. Use `pick-photo/PRD.md` as product context when it exists.
