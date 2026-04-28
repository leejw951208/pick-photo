# Pick Photo System Design

## Goal

Create the initial system design for Pick Photo, a service that turns uploaded photos into ID-photo style images by detecting faces, letting the user choose one or all faces, and generating outputs for those selections.

## Product Baseline

The product definition lives in `PRD.md`. This design document may discuss implementation structure and technical boundaries, but it must not replace the product definition in `PRD.md`.

## Recommended Repository Shape

Use independent project folders at the repository root:

- `apps/mobile/`: Flutter client application.
- `apps/backend/`: NestJS application server.
- `apps/ai/`: Python AI service.
- `database/`: PostgreSQL schema, migrations, seeds, and local data notes.
- `docs/contracts/`: Cross-project contracts that must remain explicit instead of becoming shared code.

Do not create a shared source package in the first implementation pass. The projects have different runtimes and ownership concerns, so shared behavior should be expressed as versioned documents and generated artifacts only after a real duplication problem appears.

## System Responsibilities

### Flutter App

- Provides the user-facing upload flow.
- Displays upload, face detection, face selection, generation progress, failure, and result states.
- Sends requests only to the NestJS server.
- Does not call the Python AI service directly.
- Does not store sensitive source photos longer than the user flow requires.

### NestJS Server

- Owns the public application API.
- Validates uploads and workflow requests.
- Coordinates persistence, file storage, AI calls, and result retrieval.
- Maps AI service failures into product-level errors the client can display.
- Enforces retention and deletion rules once defined.

### Python AI Server

- Owns face detection and ID-photo generation behavior.
- Exposes a narrow internal service API.
- Accepts only validated inputs from the NestJS server.
- Returns deterministic metadata for detected faces and generated image artifacts.
- Avoids persisting user photos except temporary processing files required for inference.

### PostgreSQL Data Layer

- Stores workflow metadata, not raw image bytes.
- Tracks uploaded photo records, detected faces, user selections, generation jobs, generated outputs, status transitions, and retention state.
- Supports cleanup and deletion workflows.

## Core Data Flow

1. The user uploads a photo in the Flutter app.
2. The Flutter app sends the photo to the NestJS server.
3. The NestJS server validates the request, creates an upload record, stores the source image according to the chosen storage policy, and requests face detection.
4. The Python AI server detects faces and returns face boxes, confidence values, and preview/crop references.
5. The NestJS server stores detected face metadata and returns the face list to the Flutter app.
6. The user selects one face or all faces.
7. The Flutter app sends the selection to the NestJS server.
8. The NestJS server creates generation job records and requests ID-photo generation from the Python AI server.
9. The Python AI server generates output images and returns result references and metadata.
10. The NestJS server stores result metadata and exposes status/result data to the Flutter app.
11. The Flutter app shows the generated results and save/use actions.

## Trust Boundaries

- Uploaded photos are untrusted external input.
- Client requests are untrusted external input.
- The NestJS server is the boundary between public users and internal processing.
- The Python AI server is internal-only and should not be exposed directly to end users.
- Source photos, face crops, generated ID photos, and logs can contain sensitive personal data.

## Error Model

Use product-level error categories consistently across projects:

- `upload_invalid`: the photo is missing, too large, unsupported, or unreadable.
- `face_not_found`: the photo was processed but no face was detected.
- `face_detection_failed`: detection failed for a system reason.
- `selection_invalid`: the requested face selection does not match detected faces.
- `generation_failed`: ID-photo generation failed for a selected face.
- `result_unavailable`: a result is not ready, expired, deleted, or inaccessible.

Each project can represent these errors in its own native types, but cross-project contracts should preserve these stable category names.

## Contract Documents

Create contract docs before implementation connects services:

- `docs/contracts/api.md`: Flutter-to-NestJS request and response contracts.
- `docs/contracts/ai-service.md`: NestJS-to-Python AI service contracts.
- `docs/contracts/data-model.md`: persistent entities and status transitions.
- `docs/contracts/privacy.md`: photo handling, retention, deletion, and logging rules.

## Testing Strategy

Testing should grow from the contract boundaries:

- Flutter app: widget tests for upload, detected-face selection, progress, empty, failure, and result states.
- NestJS server: unit tests for validation and workflow services; API tests for upload, detection status, selection, generation, and results.
- Python AI server: service tests for request validation, safe storage key resolution, no-face response, fake-mode compatibility, local detection mapping, generation result metadata, unreadable image errors, and JPEG output.
- Database: migration checks and data integrity tests around workflow records and status transitions.
- Integration: a minimal end-to-end happy path with fake AI responses, then a local-storage-aligned path using the Python AI service.

Verified validation commands are now recorded in `AGENTS.md` for the Python AI server, NestJS backend, Flutter app, and Docker Compose local runtime. Docker Compose validates first-time PostgreSQL schema initialization, while a repeatable migration runner for non-empty databases remains undecided.

## Implementation Order

1. Completed: create contract docs and the root folder structure.
2. Completed: create the database schema plan and migration files.
3. Completed: scaffold the Python AI server with fake deterministic detection/generation responses.
4. Completed: scaffold the NestJS server and connect it to the fake AI service contract.
5. Completed: scaffold the Flutter app and build the user flow against the NestJS API contract.
6. Completed: replace the Python AI server default with local OpenCV/Pillow image processing behind the same service contract while keeping explicit fake mode.
7. Completed: add a Docker Compose local runtime for PostgreSQL, Python AI, and NestJS with shared storage.
8. Next: provide result image serving/download behavior.
9. Next: add mobile result preview/save UX.
10. Next: add privacy, retention, cleanup, and operational documentation.

## Resolved Decisions

- Runtime and package manager baseline: Flutter 3.22.1 / Dart 3.4.1 for `apps/mobile`, Node.js 22 / npm for `apps/backend`, Python 3.12 / FastAPI for `apps/ai`, and plain PostgreSQL SQL migrations in `database`.
- The first vertical slice used deterministic fake AI behavior so the Flutter app, NestJS backend, and Python AI service could integrate before model selection was final.
- The NestJS backend stores uploaded files through local storage by default, uses PostgreSQL when `DATABASE_URL` is set, and falls back to in-memory workflow storage when `DATABASE_URL` is absent.
- The Python AI server now uses local OpenCV/Pillow processing by default and preserves deterministic fake behavior with `PICK_PHOTO_AI_MODE=fake`.
- Local Docker Compose runs PostgreSQL, Python AI, and NestJS backend together. Flutter remains a local client pointed at `http://localhost:3000`.

## Open Decisions

- Whether users can use the service anonymously.
- Production storage location for source photos, face crops, and generated outputs.
- Retention and deletion periods.
- Whether job execution is synchronous, queued, or worker-backed.
- Exact ID-photo output standards.
- Whether outputs must satisfy country-specific ID-photo rules.
- Production AI model stack, model artifacts, and inference hardware expectations.
- Production deployment and operations model.

## Spec Self-Review

- Placeholder scan: no unfinished placeholder markers are present.
- Scope check: the system is split into independent project plans because the implementation spans multiple runtimes.
- PRD alignment: the design preserves the PRD's face detection, face selection, all-faces generation, result review, failure state, and privacy expectations.
- Security check: uploaded photos, generated images, and logs are treated as sensitive personal data.
