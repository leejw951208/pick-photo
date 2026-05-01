---
name: project-harness
description: Use this skill for substantial product or engineering work in this repository, including product thinking, PRD alignment when PRD.md exists, architecture decisions, implementation planning, feature progress tracking, plan review, plan-based execution, implementation review, testing, documentation updates, and security-sensitive changes. Use it before changing product behavior, runtime behavior, APIs, exported interfaces, module boundaries, package metadata, configuration, environment variables, filesystem access, command execution, network exposure, authentication, authorization, data storage, or external integrations. Read AGENTS.md when present and PRD.md when it exists. It preserves verified repository facts and keeps language, runtime, framework, build, test, and deployment rules conditional on evidence found inside this repository.
---

# Project Harness

## Required Context

Read `AGENTS.md` first for all work. Read `PRD.md` when it exists. Treat `AGENTS.md` as repository-local operating guidance and a fact snapshot, and treat `PRD.md` as product intent, scope, requirements, acceptance criteria, assumptions, and open product questions.

Stay inside the repository root. Do not read, write, modify, summarize, merge, or clean up files outside this repository.

Write `.agents/**` operational guidance in English. Write human-facing documents outside `.agents/` in Korean, including PRDs, product docs, feature docs, implementation plans, feature progress tracking, review docs, change summaries, and commit messages. Format commit messages as `<commit type>: <Korean message>` on `main` or `dev`; use `[<branch>]<commit type>: <Korean message>` on any other branch.

During future harness generation, do not create, modify, overwrite, rewrite, or delete `AGENTS.md` or `PRD.md`; use them only as read-only context unless the user explicitly asks for a separate non-harness task.

## Repository Facts

- Repository root: `pick-photo/`.
- Git branch recorded during harness generation: `main`; `origin` is `https://github.com/leejw951208/pick-photo.git`.
- Canonical local harness path: `.agents/skills/project-harness/SKILL.md`.
- Product baseline: `PRD.md` defines Pick Photo as a mobile flow for uploading one photo, detecting faces, selecting one or more detected faces, generating ID-photo style results only for selected faces, reviewing results, and retrying from failure states.
- Existing documentation layout uses `docs/contracts/**`, `docs/superpowers/specs/**`, `docs/superpowers/plans/**`, and `docs/superpowers/mockups/**`; preserve that layout before using any fallback feature-doc layout.
- Independent project areas are `apps/mobile/`, `apps/backend/`, `apps/ai/`, and `database/`; coordinate cross-project behavior through `docs/contracts/` rather than shared application code.
- `apps/mobile/` is a Flutter app named `pick_photo`; source entrypoint is `apps/mobile/lib/main.dart`, and photo-flow files live under `apps/mobile/lib/features/photo_flow/`.
- The Flutter app uses `file_picker` and `NestPhotoFlowApi` to upload photos to `http://localhost:3000` by default, configurable with `PICK_PHOTO_API_BASE_URL`.
- The Flutter photo flow parses backend face boxes, keeps stable source preview bytes, supports original-photo direct face selection with zoom/pan assistance, and sends `single_face` or `selected_faces` generation requests based on selected face IDs.
- The selected mobile visual direction is Fresh Clarity: bright blue/mint surfaces, clearer status chips and banners, softer cards, and a redesigned photo-flow shell. This is visual-only and does not change upload, generation, API, AI, database, or retention/deletion behavior.
- `apps/backend/` is a private NestJS npm project; source entrypoint is `apps/backend/src/main.ts`, photo API files live in `apps/backend/src/photos/`, AI adapter code lives in `apps/backend/src/ai/`, local CORS is enabled, Swagger UI is served at `/docs`, and OpenAPI JSON is served at `/docs-json`.
- Backend generation requests support `single_face`, `selected_faces`, and `all_faces`. `selected_faces` requires a non-empty `faceIds` array and rejects invalid or foreign face IDs with `selection_invalid`.
- Backend storage defaults to `apps/backend/storage/` when run from `apps/backend`; `PHOTO_STORAGE_DIR` overrides that path. `AI_SERVICE_BASE_URL` enables the Python AI HTTP adapter; absence of that env var falls back to deterministic fake AI. `DATABASE_URL` enables the Prisma 7 PostgreSQL repository; absence of that env var falls back to the in-memory repository.
- Prisma config lives at `apps/backend/prisma.config.ts`; Prisma schema lives at `apps/backend/prisma/schema.prisma`; `npm run prisma:generate` generates the untracked client into `apps/backend/src/generated/prisma/`.
- `apps/ai/` is a Python package named `pick-photo-ai-server`; FastAPI entrypoint is `apps/ai/app/main.py`; local OpenCV/Pillow behavior is the default; `PICK_PHOTO_AI_MODE=fake` enables deterministic fake AI behavior.
- `database/migrations/001_initial_schema.sql` defines the initial PostgreSQL schema; `database/seeds/README.md` reserves seed guidance and says no seed data is required for the initial workflow.
- `docker-compose.yml` runs PostgreSQL, the Python AI server, and the NestJS backend together, sharing a named storage volume between backend and AI at `/data/storage`; Flutter runs locally against the backend.
- Generated/cache artifacts must remain untracked, including Python virtualenvs, `__pycache__`, pytest cache, Python egg-info, Node `node_modules`, NestJS `dist`, Prisma generated client files under `apps/backend/src/generated/`, Flutter `.dart_tool`, Flutter `build`, and local platform build outputs.

## Product Reference

Use `PRD.md` as the baseline for product intent, users, requirements, scope, acceptance criteria, assumptions, risks, and open product questions.

Keep `PRD.md` product-only. Do not add runtime choices, architecture, API contracts, database schema, package metadata, commands, deployment notes, or other technical implementation details. Do not create or modify `PRD.md` unless the user explicitly asks for a separate PRD task.

Do not treat unresolved PRD questions as verified repository facts.

## Project Decisions To Define

- Decision needed: production authentication, authorization, account model, and access boundaries.
- Decision needed: production storage, retention, deletion, consent, logging redaction, and privacy/compliance policy.
- Decision needed: production job orchestration, retry/cancellation model, and partial-success behavior.
- Decision needed: production AI model stack, model artifact storage, inference hardware, quality thresholds, and official ID-photo standards.
- Decision needed: deployment target, infrastructure layout, secret management, observability, operations commands, CI policy, branch protection, merge policy, and release workflow.
- Decision needed: PostgreSQL migration runner for non-empty databases, transaction policy, seed/fixture workflow, and schema synchronization.
- Decision needed: server-side source preview serving, face crop preview source, result serving/download authorization, and preview/result expiration behavior.
- Decision needed: `selected_faces` is supported by the app API contract and backend code, while `database/migrations/001_initial_schema.sql` still constrains `generation_jobs.selection_mode` to `single_face` and `all_faces`.
- Decision needed: Flutter Android build compatibility remains unverified after the recorded Java 21 / Gradle 7.6.3 warning.

## Workflow

For substantial work, follow this sequence:

1. Read `AGENTS.md`.
2. Read `PRD.md`, if present.
3. Read `references/01-product-thinking.md`.
4. Read `references/02-implementation-planning.md`.
5. Read `references/08-feature-progress.md` when the work has distinct features, requirements, user flows, API/CLI behaviors, or multi-step deliverables.
6. Read `references/03-plan-review.md`.
7. Do not implement unless plan review is `Approved`.
8. Follow the user-confirmation rules in `references/03-plan-review.md` before implementation. If `AGENTS.md` has a stricter confirmation rule, follow `AGENTS.md`.
9. Read `references/04-plan-execution.md` and implement from the approved plan.
10. Read `references/05-implementation-review.md`.
11. Read `references/06-testing.md`.
12. Read `references/07-documentation.md`.
13. Read `references/language-runtime.md` when touching language, runtime, compiler/interpreter, package metadata, build, module, dependency, public interface, CLI, API, config, or app-shape behavior.
14. Read `references/security.md` as soon as work touches authentication, authorization, secrets, env/config, filesystem access, command execution, network exposure, external APIs, payment, personal data, token/session/cookie handling, upload/download, sensitive logging, CORS, server-side execution boundaries, webhooks, or background jobs.

Small work must still read `AGENTS.md` first and `PRD.md` when present, then only the references needed for the change.

## Stop Conditions

- If plan review is `Needs revision`, update the plan before implementation.
- If plan review is `Blocked`, record the blocker and do not implement.
- If the implementation plan conflicts with `PRD.md`, update the plan or record the decision before implementing.
- If implementation must materially diverge from the approved plan, stop and update the plan before continuing.
- If feature progress tracking applies, do not report completion while any in-scope feature is `Blocked` or lacks requirement-to-validation mapping.
- Do not report testing complete before implementation review and verified validation are complete.
- If no verified test command exists, report `No verified test command found` and provide manual validation steps.
