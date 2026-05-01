# Implementation Planning

Create a plan before substantial implementation.

## Plan From Evidence

- Read the files directly involved in the change.
- Read the relevant contracts in `docs/contracts/**` when the change crosses Flutter, backend, AI, database, storage, privacy, or API boundaries.
- Use existing language, runtime, module, source layout, naming, error handling, validation, testing, and documentation patterns.
- Keep language, runtime, framework, app-shape, build, test, deployment, and cloud rules conditional on verified repository evidence.
- Prefer existing dependencies, local helpers, and established app boundaries over new abstractions or packages.
- Follow `01-product-thinking.md` for PRD alignment and product-scope decisions.
- Write implementation plans outside `.agents/` in Korean.
- Preserve the existing documentation layout. Use `07-documentation.md` for document locations and fallback feature-doc rules.

## Repository Planning Anchors

- Keep `apps/mobile/`, `apps/backend/`, `apps/ai/`, and `database/` independent unless an approved plan updates a contract.
- Coordinate cross-project behavior through `docs/contracts/`.
- For Flutter work, inspect `apps/mobile/lib/main.dart`, `apps/mobile/lib/features/photo_flow/**`, and matching tests before editing.
- For backend work, inspect `apps/backend/src/main.ts`, `apps/backend/src/photos/**`, `apps/backend/src/ai/**`, Prisma files, and matching tests before editing.
- For AI work, inspect `apps/ai/app/**`, AI contracts, and `apps/ai/tests/**` before editing.
- For database work, inspect `database/migrations/**`, `database/seeds/**`, Prisma schema, backend repository code, and data-model contracts before editing.
- For documentation work, preserve `docs/superpowers/specs/**`, `docs/superpowers/plans/**`, `docs/superpowers/mockups/**`, and `docs/contracts/**` unless the user asks for a new structure.

## Plan Contents

Include:

- Scope and non-scope
- PRD requirements, acceptance criteria, or open decisions involved
- Existing repository evidence and files read
- Feature document location when persistent human-facing documentation is needed
- Files or modules likely to change
- Product behavior, UI, API, configuration, data, type/interface, package metadata, schema, or contract impacts
- Feature progress tracking when the work has distinct features, requirements, user flows, API/CLI behaviors, or multi-step deliverables
- Security-sensitive impacts and required `security.md` checks
- Language/runtime impacts and required `language-runtime.md` checks
- Verified validation commands from `06-testing.md` or a clear note that no verified command exists
- Documentation impact and whether a Korean product-doc update is needed
- Rollback or containment notes for risky changes

## Output

Write a concise Korean implementation plan outside `.agents/`. When feature progress tracking applies, record where it will live or include a compact summary following `08-feature-progress.md`.
